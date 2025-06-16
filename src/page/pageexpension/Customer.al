pageextension 95103 CustomerExt extends "Customer Card"
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
        if Cliente = Rec."No." then
            exit;
        Cliente := Rec."No.";
        GoogleDriveManager.GetFolderMapping(Database::Customer, Id);
        SubFolder := FolderMapping.CreateSubfolderPath(Database::Customer, Rec."No.", 0D);
        IF SubFolder <> '' then
            Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1);
    end;

    trigger OnOpenPage()
    begin
        Cliente := '';
    end;

    var
        Cliente: Text;
}