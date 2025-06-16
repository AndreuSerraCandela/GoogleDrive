pageextension 95107 GLAccountExt extends "G/L Account Card"
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
        if CuentaContable = Rec."No." then
            exit;
        CuentaContable := Rec."No.";
        GoogleDriveManager.GetFolderMapping(Database::"G/L Account", Id);
        SubFolder := FolderMapping.CreateSubfolderPath(Database::"G/L Account", Rec."No.", 0D);
        IF SubFolder <> '' then
            Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1);
    end;

    trigger OnOpenPage()
    begin
        CuentaContable := '';
    end;

    var
        CuentaContable: Text;
}