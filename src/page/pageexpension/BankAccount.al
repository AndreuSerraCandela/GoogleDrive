pageextension 95108 BankAccountExt extends "Bank Account Card"
{
    layout
    {
        addlast(factboxes)
        {
            part(Visor; "PDF Viewer Part Google Drive")
            {
                //SubPageLink = "Entry No." = field("Incoming Document Entry No.");
                Caption = 'PDF Viewer';
                ApplicationArea = All;
                //Visible = Tienedatos;
            }
            part(GoogleDriveFiles; "Google Drive Factbox")
            {
                Caption = 'Archivos del Drive';
                ApplicationArea = All;
                Visible = IsExtendedFunctionalityEnabled;
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        RecRef: RecordRef;
        CompaniInfo: Record "Company Information";
    begin
        CompaniInfo.Get();
        if CuentaBancaria = Rec."No." then
            exit;
        CuentaBancaria := Rec."No.";
        GoogleDriveManager.GetFolderMapping(Database::"Bank Account", Id);
        SubFolder := FolderMapping.CreateSubfolderPath(Database::"Bank Account", Rec."No.", 0D, CompaniInfo."Data Storage Provider");
        IF SubFolder <> '' then
            Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
        RecRef.GetTable(Rec);
        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
        CurrPage.Visor.Page.SetRecord(Rec.RecordId);
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnOpenPage()
    begin
        CuentaBancaria := '';
        CheckExtendedFunctionality();
    end;

    local procedure CheckExtendedFunctionality()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        IsExtendedFunctionalityEnabled := CompanyInfo."Funcionalidad extendida";
    end;

    var
        CuentaBancaria: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        FolderMapping: Record "Google Drive Folder Mapping";
        Id: Text;
        AutoCreateSubFolder: Boolean;
        SubFolder: Text;
        IsExtendedFunctionalityEnabled: Boolean;
}