pageextension 95112 PurchaseOrderExt extends "Purchase Order"
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
                Visible = IsExtendedFunctionalityEnabled;
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
        CodeuniDocAtchManager: Codeunit "Doc. Attachment Mgmt. GDrive";
        RecRef: RecordRef;
        Recargar: Boolean;
    begin
        if Maestro = Rec."No." then
            exit;
        RecRef.GetTable(Rec);
        If Not CodeuniDocAtchManager.OnAfterGetRecord(Maestro, Recargar, RecRef, Id, Rec."No.", Rec."Order Date") then
            exit;
        If Recargar Then
            CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
        CurrPage.Visor.Page.SetRecord(Rec.RecordId);


    end;

    trigger OnAfterGetCurrRecord()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if not CompanyInfo."Funcionalidad extendida" then
            exit;
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnOpenPage()
    begin
        Maestro := '';
        CheckExtendedFunctionality();
    end;

    var
        Maestro: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
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
pageextension 95113 PurchaseInvoiceExt extends "Purchase Invoice"
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
                Visible = IsExtendedFunctionalityEnabled;
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
        CodeuniDocAtchManager: Codeunit "Doc. Attachment Mgmt. GDrive";
        RecRef: RecordRef;
        Recargar: Boolean;
    begin
        if Maestro = Rec."No." then
            exit;
        RecRef.GetTable(Rec);
        If Not CodeuniDocAtchManager.OnAfterGetRecord(Maestro, Recargar, RecRef, Id, Rec."No.", Rec."Document Date") then
            exit;
        If Recargar Then
            CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
        CurrPage.Visor.Page.SetRecord(Rec.RecordId);


    end;

    trigger OnAfterGetCurrRecord()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if not CompanyInfo."Funcionalidad extendida" then
            exit;
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnOpenPage()
    begin
        Maestro := '';
        CheckExtendedFunctionality();
    end;

    var
        Maestro: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
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
pageextension 95114 PurchaseCrMemoExt extends "Purchase Credit Memo"
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
                Visible = IsExtendedFunctionalityEnabled;
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
        CodeuniDocAtchManager: Codeunit "Doc. Attachment Mgmt. GDrive";
        RecRef: RecordRef;
        Recargar: Boolean;
    begin
        if Maestro = Rec."No." then
            exit;
        RecRef.GetTable(Rec);
        If Not CodeuniDocAtchManager.OnAfterGetRecord(Maestro, Recargar, RecRef, Id, Rec."No.", Rec."Document Date") then
            exit;
        If Recargar Then
            CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
        CurrPage.Visor.Page.SetRecord(Rec.RecordId);


    end;

    trigger OnAfterGetCurrRecord()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if not CompanyInfo."Funcionalidad extendida" then
            exit;
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnOpenPage()
    begin
        Maestro := '';
        CheckExtendedFunctionality();
    end;

    var
        Maestro: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
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

pageextension 95115 PurchasePostInvoiceExt extends "Posted Purchase Invoice"
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
                Visible = IsExtendedFunctionalityEnabled;
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
        CodeuniDocAtchManager: Codeunit "Doc. Attachment Mgmt. GDrive";
        RecRef: RecordRef;
        Recargar: Boolean;
    begin
        if Maestro = Rec."No." then
            exit;
        RecRef.GetTable(Rec);
        If Not CodeuniDocAtchManager.OnAfterGetRecord(Maestro, Recargar, RecRef, Id, Rec."No.", Rec."Document Date") then
            exit;
        If Recargar Then
            CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
        CurrPage.Visor.Page.SetRecord(Rec.RecordId);


    end;

    trigger OnAfterGetCurrRecord()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if not CompanyInfo."Funcionalidad extendida" then
            exit;
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnOpenPage()
    begin
        Maestro := '';
        CheckExtendedFunctionality();
    end;

    var
        Maestro: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
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
pageextension 95116 PurchasePostCrMemoExt extends "Posted Purchase Credit Memo"
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
                Visible = IsExtendedFunctionalityEnabled;
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
        CodeuniDocAtchManager: Codeunit "Doc. Attachment Mgmt. GDrive";
        RecRef: RecordRef;
        Recargar: Boolean;
    begin
        if Maestro = Rec."No." then
            exit;
        RecRef.GetTable(Rec);
        If Not CodeuniDocAtchManager.OnAfterGetRecord(Maestro, Recargar, RecRef, Id, Rec."No.", Rec."Document Date") then
            exit;
        If Recargar Then
            CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
        CurrPage.Visor.Page.SetRecord(Rec.RecordId);


    end;

    trigger OnAfterGetCurrRecord()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if not CompanyInfo."Funcionalidad extendida" then
            exit;
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnOpenPage()
    begin
        Maestro := '';
        CheckExtendedFunctionality();
    end;

    var
        Maestro: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
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
pageextension 95117 PurchasePostReceiptExt extends "Posted Purchase Receipt"
{
    layout
    {
        addafter("Control1900383207")
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Purch. Rcpt. Header"),
                              "No." = field("No.");
            }
            part(Visor; "PDF Viewer Part Google Drive")
            {
                UpdatePropagation = Both;
                //SubPageLink = "Entry No." = field("Incoming Document Entry No.");
                Caption = 'PDF Viewer';
                ApplicationArea = All;
                Visible = IsExtendedFunctionalityEnabled;
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
        CodeuniDocAtchManager: Codeunit "Doc. Attachment Mgmt. GDrive";
        RecRef: RecordRef;
        Recargar: Boolean;
    begin
        if Maestro = Rec."No." then
            exit;
        RecRef.GetTable(Rec);
        If Not CodeuniDocAtchManager.OnAfterGetRecord(Maestro, Recargar, RecRef, Id, Rec."No.", Rec."Document Date") then
            exit;
        If Recargar Then
            CurrPage.GoogleDriveFiles.Page.Recargar(Id, '', 1, RecRef);
        CurrPage.Visor.Page.SetRecord(Rec.RecordId);


    end;

    trigger OnAfterGetCurrRecord()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if not CompanyInfo."Funcionalidad extendida" then
            exit;
        CurrPage.Visor.Page.Update(false);
        CurrPage.GoogleDriveFiles.Page.Update(false);
    end;

    trigger OnOpenPage()
    begin
        Maestro := '';
        CheckExtendedFunctionality();
    end;

    var
        Maestro: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
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
