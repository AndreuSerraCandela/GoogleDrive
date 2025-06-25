pageextension 95106 FixedAssetExt extends "Fixed Asset Card"
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
        if ActivoFijo = Rec."No." then
            exit;
        CompanyInfo.Get();
        case CompanyInfo."Data Storage Provider" of
            CompanyInfo."Data Storage Provider"::"Google Drive":
                begin
                    ActivoFijo := Rec."No.";
                    GoogleDriveManager.GetFolderMapping(Database::"Fixed Asset", Id);
                    SubFolder := FolderMapping.CreateSubfolderPath(Database::"Fixed Asset", Rec."No.", 0D, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then
                        Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
                    RecRef.GetTable(Rec);
                    CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
                    CurrPage.Visor.Page.SetRecord(Rec.RecordId);
                end;
            CompanyInfo."Data Storage Provider"::OneDrive:
                begin
                    ActivoFijo := Rec."No.";
                    Path := CompanyInfo."Root Folder" + '/';
                    FolderMapping.SetRange("Table ID", Database::"Fixed Asset");
                    if FolderMapping.FindFirst() Then begin
                        Id := FolderMapping."Default Folder Id";
                        Path += FolderMapping."Default Folder Name" + '/';
                    end;
                    SubFolder := FolderMapping.CreateSubfolderPath(Database::"Fixed Asset", Rec."No.", 0D, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then
                        Id := OneDriveManager.CreateFolderStructure(Id, SubFolder);
                    RecRef.GetTable(Rec);
                    CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
                    CurrPage.Visor.Page.SetRecord(Rec.RecordId);
                end;
            CompanyInfo."Data Storage Provider"::DropBox:
                begin
                    ActivoFijo := Rec."No.";
                    FolderMapping.SetRange("Table ID", Database::"Fixed Asset");
                    if FolderMapping.FindFirst() Then Id := FolderMapping."Default Folder ID";
                    SubFolder := FolderMapping.CreateSubfolderPath(Database::"Fixed Asset", Rec."No.", 0D, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then
                        Id := DropBoxManager.CreateFolderStructure(Id, SubFolder);
                    RecRef.GetTable(Rec);
                    CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
                    CurrPage.Visor.Page.SetRecord(Rec.RecordId);
                end;
            CompanyInfo."Data Storage Provider"::Strapi:
                begin
                    ActivoFijo := Rec."No.";
                    FolderMapping.SetRange("Table ID", Database::"Fixed Asset");
                    if FolderMapping.FindFirst() Then Id := FolderMapping."Default Folder ID";
                    SubFolder := FolderMapping.CreateSubfolderPath(Database::"Fixed Asset", Rec."No.", 0D, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then
                        Id := StrapiManager.CreateFolderStructure(Id, SubFolder);
                    RecRef.GetTable(Rec);
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
        ActivoFijo := '';
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
        ActivoFijo: Text;
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