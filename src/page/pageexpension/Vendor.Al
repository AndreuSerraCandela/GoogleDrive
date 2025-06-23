pageextension 95102 VendorExt extends "Vendor Card"
{
    layout
    {
        addafter("Attached Documents List")
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
                Caption = 'Archivos del Drive';
                ApplicationArea = All;
                Visible = IsExtendedFunctionalityEnabled;

                //SubPageLink = "Vendor No." = field("No.");
            }

        }
    }
    trigger OnAfterGetRecord()
    var
        RecRef: RecordRef;
        CompaniInfo: Record "Company Information";
    begin
        if Proveedor = Rec."No." then
            exit;
        Proveedor := Rec."No.";
        CompaniInfo.Get();
        GoogleDriveManager.GetFolderMapping(Database::Vendor, Id);
        SubFolder := FolderMapping.CreateSubfolderPath(Database::Vendor, rEC."No.", 0D, CompaniInfo."Data Storage Provider");
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
        Proveedor := '';
        CheckExtendedFunctionality();
    end;

    var
        Proveedor: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        FolderMapping: Record "Google Drive Folder Mapping";
        Id: Text;
        AutoCreateSubFolder: Boolean;
        SubFolder: Text;
        IsExtendedFunctionalityEnabled: Boolean;

    local procedure CheckExtendedFunctionality()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        // Verificar si se ha seleccionado algún proveedor de almacenamiento
        // Si el campo no está vacío, significa que se ha configurado un proveedor
        IsExtendedFunctionalityEnabled := CompanyInfo."Funcionalidad extendida";
    end;
}

