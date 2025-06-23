pageextension 95103 CustomerExt extends "Customer Card"
{
    layout
    {
        addafter("Attached Documents List")
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
        if Cliente = Rec."No." then
            exit;
        CompaniInfo.Get();
        Cliente := Rec."No.";
        GoogleDriveManager.GetFolderMapping(Database::Customer, Id);
        SubFolder := FolderMapping.CreateSubfolderPath(Database::Customer, Rec."No.", 0D, CompaniInfo."Data Storage Provider");
        IF SubFolder <> '' then
            Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
        RecRef.GetTable(Rec);
        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
        CurrPage.Visor.Page.SetRecord(Rec.RecordId);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnOpenPage()
    begin
        Cliente := '';
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
        Cliente: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        FolderMapping: Record "Google Drive Folder Mapping";
        Id: Text;
        AutoCreateSubFolder: Boolean;
        SubFolder: Text;
        IsExtendedFunctionalityEnabled: Boolean;
}