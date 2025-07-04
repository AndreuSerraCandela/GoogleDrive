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
                Visible = IsExtendedFunctionalityEnabled;
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
        CodeuniDocAtchManager: Codeunit "Doc. Attachment Mgmt. GDrive";
        RecRef: RecordRef;
        Recargar: Boolean;
    begin
        if Maestro = Rec."No." then
            exit;
        RecRef.GetTable(Rec);
        If Not CodeuniDocAtchManager.OnAfterGetRecord(Maestro, Recargar, RecRef, Id, Rec."No.") then
            exit;
        If Recargar Then
            CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
        CurrPage.Visor.Page.SetRecord(Rec.RecordId);


    end;

    trigger OnAfterGetCurrRecord()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if not CompanyInfo."Funcionalidad extendida" then
            exit;
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnOpenPage()
    begin
        Maestro := '';
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
        Maestro: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        FolderMapping: Record "Google Drive Folder Mapping";
        Id: Text;
        AutoCreateSubFolder: Boolean;
        SubFolder: Text;
        IsExtendedFunctionalityEnabled: Boolean;
}