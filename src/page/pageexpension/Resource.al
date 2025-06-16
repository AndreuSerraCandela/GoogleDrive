pageextension 95105 ResourceExt extends "Resource Card"
{
    layout
    {
        addlast(factboxes)
        {
            part(GoogleDriveFiles; "Google Drive Factbox")
            {
                Caption = 'Archivos de Google Drive';
                ApplicationArea = All;
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        GoogleDriveManager: Codeunit "Google Drive Manager";
        FolderMapping: Record "Google Drive Folder Mapping";
        Id: Text;
        AutoCreateSubFolder: Boolean;
        SubFolder: Text;
    begin
        if Recurso = Rec."No." then
            exit;
        Recurso := Rec."No.";
        GoogleDriveManager.GetFolderMapping(Database::Resource, Id);
        SubFolder := FolderMapping.CreateSubfolderPath(Database::Resource, Rec."No.", 0D);
        IF SubFolder <> '' then
            Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1);
    end;

    trigger OnOpenPage()
    begin
        Recurso := '';
    end;

    var
        Recurso: Text;
}