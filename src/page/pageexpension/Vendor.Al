pageextension 50102 VendorExt extends "Vendor Card"
{
    layout
    {
        addlast(factboxes)
        {
            part(GoogleDriveFiles; "Google Drive Factbox")
            {
                Caption = 'Archivos de Google Drive';
                ApplicationArea = All;
                //SubPageLink = "Vendor No." = field("No.");
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        GoogleDriveManager: Codeunit "Google Drive Manager";
        Id: Text;
    begin
        GoogleDriveManager.GetFolderMapping(Database::Vendor, Id);
        CurrPage.GoogleDriveFiles.Page.Recargar(Id);
    end;
}
