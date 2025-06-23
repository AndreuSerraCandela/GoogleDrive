pageextension 95105 ResourceExt extends "Resource Card"
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
        if Recurso = Rec."No." then
            exit;
        CompaniInfo.Get();
        Recurso := Rec."No.";
        GoogleDriveManager.GetFolderMapping(Database::Resource, Id);
        SubFolder := FolderMapping.CreateSubfolderPath(Database::Resource, Rec."No.", 0D, CompaniInfo."Data Storage Provider");
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
        Recurso := '';
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
        Recurso: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        FolderMapping: Record "Google Drive Folder Mapping";
        Id: Text;
        AutoCreateSubFolder: Boolean;
        SubFolder: Text;
        IsExtendedFunctionalityEnabled: Boolean;
}