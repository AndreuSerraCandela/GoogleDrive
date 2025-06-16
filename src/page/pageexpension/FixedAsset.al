pageextension 95106 FixedAssetExt extends "Fixed Asset Card"
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
        if ActivoFijo = Rec."No." then
            exit;
        ActivoFijo := Rec."No.";
        GoogleDriveManager.GetFolderMapping(Database::"Fixed Asset", Id);
        SubFolder := FolderMapping.CreateSubfolderPath(Database::"Fixed Asset", Rec."No.", 0D);
        IF SubFolder <> '' then
            Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1);
    end;

    trigger OnOpenPage()
    begin
        ActivoFijo := '';
    end;

    var
        ActivoFijo: Text;
}