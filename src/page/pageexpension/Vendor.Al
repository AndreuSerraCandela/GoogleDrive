pageextension 95102 VendorExt extends "Vendor Card"
{
    layout
    {
        addlast(factboxes)
        {
            part(Visor; "PDF Viewer Part Google Drive")
            {
                UpdatePropagation = Both;
                //SubPageLink = "Entry No." = field("Incoming Document Entry No.");
                Caption = 'PDF Viewer';
                ApplicationArea = All;
                //Visible = Tienedatos;
            }
            part(GoogleDriveFiles; "Google Drive Factbox")
            {
                UpdatePropagation = Both;
                Caption = 'Archivos de Google Drive';
                ApplicationArea = All;

                //SubPageLink = "Vendor No." = field("No.");
            }

        }
    }
    trigger OnAfterGetRecord()
    var


    begin
        if Proveedor = Rec."No." then
            exit;
        Proveedor := Rec."No.";
        GoogleDriveManager.GetFolderMapping(Database::Vendor, Id);
        SubFolder := FolderMapping.CreateSubfolderPath(Database::Vendor, rEC."No.", 0D);
        IF SubFolder <> '' then
            Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1);
        CurrPage.Visor.Page.SetRecord(Rec.RecordId);
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnOpenPage()
    begin
        Proveedor := '';
    end;

    var
        Proveedor: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        FolderMapping: Record "Google Drive Folder Mapping";
        Id: Text;
        AutoCreateSubFolder: Boolean;
        SubFolder: Text;


}

