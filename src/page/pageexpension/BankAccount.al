pageextension 95108 BankAccountExt extends "Bank Account Card"
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
        if CuentaBancaria = Rec."No." then
            exit;
        CuentaBancaria := Rec."No.";
        GoogleDriveManager.GetFolderMapping(Database::"Bank Account", Id);
        SubFolder := FolderMapping.CreateSubfolderPath(Database::"Bank Account", Rec."No.", 0D);
        IF SubFolder <> '' then
            Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1);
    end;

    trigger OnOpenPage()
    begin
        CuentaBancaria := '';
    end;

    var
        CuentaBancaria: Text;
}