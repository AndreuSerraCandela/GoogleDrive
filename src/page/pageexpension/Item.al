pageextension 95104 ItemExt extends "Item Card"
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
        if Articulo = Rec."No." then
            exit;
        Articulo := Rec."No.";
        GoogleDriveManager.GetFolderMapping(Database::Item, Id);
        SubFolder := FolderMapping.CreateSubfolderPath(Database::Item, Rec."No.", 0D);
        IF SubFolder <> '' then
            Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1);
    end;

    trigger OnOpenPage()
    begin
        Articulo := '';
    end;

    var
        Articulo: Text;
}