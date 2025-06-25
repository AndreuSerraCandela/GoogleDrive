pageextension 95109 JobExt extends "Job Card"
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
        CompanyInfo: Record "Company Information";
        Path: Text;
    begin
        if Job = Rec."No." then
            exit;
        CompanyInfo.Get();
        case CompanyInfo."Data Storage Provider" of
            CompanyInfo."Data Storage Provider"::"Google Drive":
                begin
                    Job := Rec."No.";
                    GoogleDriveManager.GetFolderMapping(Database::Job, Id);
                    SubFolder := FolderMapping.CreateSubfolderPath(Database::Job, Rec."No.", 0D, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then
                        Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
                    RecRef.GetTable(Rec);
                    if CompanyInfo."Funcionalidad extendida" then
                        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
                    CurrPage.Visor.Page.SetRecord(Rec.RecordId);
                end;
            CompanyInfo.
            "Data Storage Provider"::OneDrive:
                begin
                    Job := Rec."No.";
                    Path := CompanyInfo."Root Folder" + '/';
                    FolderMapping.SetRange("Table ID", Database::Job);
                    if FolderMapping.FindFirst() Then begin
                        Id := FolderMapping."Default Folder Id";
                        Path += FolderMapping."Default Folder Name" + '/';
                    end;

                    SubFolder := FolderMapping.CreateSubfolderPath(Database::Job, Rec."No.", 0D, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then begin
                        Id := OneDriveManager.CreateFolderStructure(Id, SubFolder);
                        Path += SubFolder + '/'
                    end;
                    if CompanyInfo."Funcionalidad extendida" then
                        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
                    CurrPage.Visor.Page.SetRecord(Rec.RecordId);
                end;
            CompanyInfo."Data Storage Provider"::DropBox:
                begin
                    Job := Rec."No.";
                    FolderMapping.SetRange("Table ID", Database::Job);
                    if FolderMapping.FindFirst() Then Id := FolderMapping."Default Folder ID";
                    SubFolder := FolderMapping.CreateSubfolderPath(Database::Job, Rec."No.", 0D, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then
                        Id := DropBoxManager.CreateFolderStructure(Id, SubFolder);
                    if CompanyInfo."Funcionalidad extendida" then
                        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
                    CurrPage.Visor.Page.SetRecord(Rec.RecordId);
                end;
            CompanyInfo."Data Storage Provider"::Strapi:
                begin
                    Job := Rec."No.";
                    FolderMapping.SetRange("Table ID", Database::Job);
                    if FolderMapping.FindFirst() Then Id := FolderMapping."Default Folder ID";
                    SubFolder := FolderMapping.CreateSubfolderPath(Database::Job, Rec."No.", 0D, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then
                        Id := StrapiManager.CreateFolderStructure(Id, SubFolder);
                    if CompanyInfo."Funcionalidad extendida" then
                        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
                    CurrPage.Visor.Page.SetRecord(Rec.RecordId);
                end;
        end;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnOpenPage()
    begin
        Job := '';
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
        Job: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        FolderMapping: Record "Google Drive Folder Mapping";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        Id: Text;
        AutoCreateSubFolder: Boolean;
        SubFolder: Text;
        IsExtendedFunctionalityEnabled: Boolean;
}