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
                //Visible = Tienedatos;
            }
            part(GoogleDriveFiles; "Google Drive Factbox")
            {
                Caption = 'Archivos de Google Drive';
                ApplicationArea = All;
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        RecRef: RecordRef;
    begin
        if CuentaBancaria = Rec."No." then
            exit;
        CuentaBancaria := Rec."No.";
        GoogleDriveManager.GetFolderMapping(Database::"Bank Account", Id);
        SubFolder := FolderMapping.CreateSubfolderPath(Database::"Bank Account", Rec."No.", 0D);
        IF SubFolder <> '' then
            Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
        RecRef.GetTable(Rec);
        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
        CurrPage.Visor.Page.SetRecord(Rec.RecordId);
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnOpenPage()
    begin
        CuentaBancaria := '';
    end;

    var
        CuentaBancaria: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        FolderMapping: Record "Google Drive Folder Mapping";
        Id: Text;
        AutoCreateSubFolder: Boolean;
        SubFolder: Text;
}