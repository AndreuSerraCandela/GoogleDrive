table 95100 "Google Drive Folder Mapping"
{
    Caption = 'Folder Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()
            begin
                CalcFields("Table Name");
            end;
        }

        field(2; "Table Name"; Text[100])
        {
            Caption = 'Table Name';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
            Editable = false;
        }

        field(3; "Default Folder ID"; Text[250])
        {
            Caption = 'Default Folder ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the ID of the Drive folder where files for this table will be stored by default.';
        }

        field(4; "Default Folder Name"; Text[250])
        {
            Caption = 'Default Folder Name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the name of the Drive folder (for reference only).';
            trigger OnValidate()
            begin
                If (xRec."Default Folder Name" <> "Default Folder Name") and
                ("Default Folder ID" <> '') and (xRec."Default Folder Name" <> '') then begin
                    If Confirm('¿Desea renombrar la carpeta?', false) Then
                        RenameFolder("Default Folder ID", "Default Folder Name");
                end;
            end;
        }

        field(5; "Auto Create Subfolders"; Boolean)
        {
            Caption = 'Auto Create Subfolders';
            DataClassification = CustomerContent;
            ToolTip = 'If enabled, it will automatically create subfolders based on the document number.';
            InitValue = false;
        }

        field(6; "Subfolder Pattern"; Text[100])
        {
            Caption = 'Subfolder Pattern';
            DataClassification = CustomerContent;
            ToolTip = 'Pattern for creating subfolders. Use {DOCNO} for document number, {NO} for Code, {YEAR} for year, {MONTH} for month.';
        }

        field(7; "Active"; Boolean)
        {
            Caption = 'Active';
            DataClassification = CustomerContent;
            InitValue = true;
        }

        field(8; "Description"; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Optional description for this configuration.';
        }

        field(9; "Created Date"; DateTime)
        {
            Caption = 'Created Date';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(10; "Modified Date"; DateTime)
        {
            Caption = 'Modified Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Table ID")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        "Created Date" := CurrentDateTime;
        "Modified Date" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Modified Date" := CurrentDateTime;
    end;

    procedure RecuperarIdFolder(Folder: Text; Crear: Boolean; RootFolder: Boolean): Text
    var
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OnDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        SharePointManager: Codeunit "SharePoint Manager";
        Files: Record "Name/Value Buffer" temporary;
        Id: Text;
        CompaiInfo: Record "Company Information";
    begin
        CompaiInfo.Get();
        case CompaiInfo."Data Storage Provider" of
            CompaiInfo."Data Storage Provider"::"Google Drive":
                exit(GoogleDriveManager.RecuperaIdFolder(Id, Folder, Files, Crear, RootFolder));
            CompaiInfo."Data Storage Provider"::OneDrive:
                exit(OnDriveManager.RecuperaIdFolder(Id, Folder, Files, Crear, RootFolder));
            CompaiInfo."Data Storage Provider"::DropBox:
                exit(DropBoxManager.RecuperaIdFolder(Id, Folder, Files, Crear, RootFolder));
            CompaiInfo."Data Storage Provider"::Strapi:
                exit(StrapiManager.RecuperaIdFolder(Id, Folder, Files, Crear, RootFolder));
            CompaiInfo."Data Storage Provider"::SharePoint:
                exit(SharePointManager.RecuperaIdFolder(Id, Folder, Files, Crear, RootFolder));
        end;
    end;

    procedure GetDefaultFolderForTable(TableID: Integer): Text
    var
        FolderMapping: Record "Google Drive Folder Mapping";
    begin
        if FolderMapping.Get(TableID) and FolderMapping.Active then
            exit(FolderMapping."Default Folder ID");

        exit(''); // Return empty if no mapping found
    end;

    procedure CreateSubfolderPath(TableID: Integer; DocumentNo: Text; DocumentDate: Date; Origen: Enum "Data Storage Provider"): Text
    var
        FolderMapping: Record "Google Drive Folder Mapping";
        SubfolderPath: Text;
        Year: Text;
        Month: Text;
    begin
        if not FolderMapping.Get(TableID) then
            exit('');

        if not FolderMapping."Auto Create Subfolders" then
            exit(FolderMapping."Default Folder ID");

        if FolderMapping."Subfolder Pattern" = '' then
            exit(FolderMapping."Default Folder ID");
        SubfolderPath := FolderMapping."Subfolder Pattern";

        // Replace patterns
        if StrPos(SubfolderPath, '{DOCNO}') > 0 then
            SubfolderPath := DocumentNo;
        if StrPos(SubfolderPath, '{NO}') > 0 then
            SubfolderPath := DocumentNo;
        if DocumentDate = 0D then
            exit(SubfolderPath);
        if StrPos(SubfolderPath, '{YEAR}') > 0 then begin
            Year := Format(Date2DMY(DocumentDate, 3));
            SubfolderPath := Year;
        end;

        if StrPos(SubfolderPath, '{MONTH}') > 0 then begin
            Month := Format(DocumentDate, 0, '<Month Text>');
            SubfolderPath := Month;
        end;
        if StrPos(SubfolderPath, '{YEAR}/{MONTH}') > 0 then begin
            Year := Format(Date2DMY(DocumentDate, 3));
            Month := Format(DocumentDate, 0, '<Month Text>');
            SubfolderPath := Year + '-' + Month;
        end;

        exit(SubfolderPath);
    end;

    procedure SetupDefaultMappings()
    var
        FolderMapping: Record "Google Drive Folder Mapping";
    begin
        // Sales Invoice Header
        if not FolderMapping.Get(112) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 112;
            FolderMapping."Default Folder Name" := 'Sales Invoices';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{YEAR}/{MONTH}';
            FolderMapping.Description := 'Sales Invoice Header documents';
            FolderMapping.Insert();
        end;
        //114
        if not FolderMapping.Get(114) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 114;
            FolderMapping."Default Folder Name" := 'Sales Credit Memos';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{YEAR}/{MONTH}';
            FolderMapping.Description := 'Sales Credit Memo Header documents';
            FolderMapping.Insert();
        end;
        //122
        if not FolderMapping.Get(122) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 122;
            FolderMapping."Default Folder Name" := 'Purchase Invoices';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{YEAR}/{MONTH}';
            FolderMapping.Description := 'Purchase Invoice Header documents';
            FolderMapping.Insert();
        end;
        //124
        if not FolderMapping.Get(124) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 124;
            FolderMapping."Default Folder Name" := 'Purchase Credit Memos';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{YEAR}/{MONTH}';
            FolderMapping.Description := 'Purchase Credit Memo Header documents';
            FolderMapping.Insert();
        end;

        // Sales Header
        if not FolderMapping.Get(36) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 36;
            FolderMapping."Default Folder Name" := 'Sales Orders';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{YEAR}';
            FolderMapping.Description := 'Sales Header documents';
            FolderMapping.Insert();
        end;

        // Purchase Header
        if not FolderMapping.Get(38) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 38;
            FolderMapping."Default Folder Name" := 'Purchase Orders';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{YEAR}';
            FolderMapping.Description := 'Purchase Header documents';
            FolderMapping.Insert();
        end;

        // Customer
        if not FolderMapping.Get(18) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 18;
            FolderMapping."Default Folder Name" := 'Customers';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{NO}';
            FolderMapping.Description := 'Customer documents';
            FolderMapping.Insert();
        end;

        // Vendor
        if not FolderMapping.Get(23) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 23;
            FolderMapping."Default Folder Name" := 'Vendors';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{NO}';
            FolderMapping.Description := 'Vendor documents';
            FolderMapping.Insert();
        end;
        //27
        if not FolderMapping.Get(27) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 27;
            FolderMapping."Default Folder Name" := 'Items';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{NO}';
            FolderMapping.Description := 'Item documents';
            FolderMapping.Insert();
        end;
        //167
        if not FolderMapping.Get(Database::Job) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := Database::Job;
            FolderMapping."Default Folder Name" := 'Jobs';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{NO}';
            FolderMapping.Description := 'Job documents';
            FolderMapping.Insert();
        end;
        //15
        if not FolderMapping.Get(15) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 15;
            FolderMapping."Default Folder Name" := 'G/L Accounts';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{NO}';
            FolderMapping.Description := 'G/L Account documents';
            FolderMapping.Insert();
        end;
        //5600
        if not FolderMapping.Get(5600) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 5600;
            FolderMapping."Default Folder Name" := 'Fixed Assets';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{NO}';
            FolderMapping.Description := 'Fixed Asset documents';
            FolderMapping.Insert();
        end;
        //Database::Employee
        if not FolderMapping.Get(Database::Employee) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := Database::Employee;
            FolderMapping."Default Folder Name" := 'Employees';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{NO}';
            FolderMapping.Description := 'Employee documents';
            FolderMapping.Insert();
        end;

        Message('Configuraciones por defecto creadas exitosamente.');
    end;

    internal procedure RenameFolder(RootFolderID: Text[250]; RootFolder: Text[250]): text
    var
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OnDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        SharePointManager: Codeunit "SharePoint Manager";
        Files: Record "Name/Value Buffer" temporary;
        Id: Text;
        CompaiInfo: Record "Company Information";
    begin
        CompaiInfo.Get();
        case CompaiInfo."Data Storage Provider" of
            CompaiInfo."Data Storage Provider"::"Google Drive":
                exit(GoogleDriveManager.RenameFolder(RootFolderID, RootFolder));
            CompaiInfo."Data Storage Provider"::OneDrive:
                exit(OnDriveManager.RenameFolder(RootFolderID, RootFolder));
            CompaiInfo."Data Storage Provider"::DropBox:
                exit(DropBoxManager.RenameFolder(RootFolderID, RootFolder));
            CompaiInfo."Data Storage Provider"::Strapi:
                exit(StrapiManager.RenameFolder(RootFolderID, RootFolder));
            CompaiInfo."Data Storage Provider"::SharePoint:
                exit(SharePointManager.RenameFolder(RootFolderID, RootFolder));
        end;
    end;

    internal procedure MoveFileH(DataStorageProvider: Enum "Data Storage Provider"; var DocumentAttachment: Record "Document Attachment"; Origen: Integer; TableId: Integer; Var RecRef: RecordRef; Fecha: Date)
    var
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OnDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        SharePointManager: Codeunit "SharePoint Manager";
        IdCarpetaOrigen: Text;
        IdCarpetaDestino: Text;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        DocNo: Text;
        DocDate: Date;

    begin
        Case Origen of
            Database::"Purchase Header":
                begin
                    DocNo := RecRef.Field(PurchaseHeader.FieldNo("No.")).Value;
                    DocDate := RecRef.Field(PurchaseHeader.FieldNo("Document Date")).Value;
                end;
            Database::"Sales Header":
                begin
                    DocNo := RecRef.Field(SalesHeader.FieldNo("No.")).Value;
                    DocDate := RecRef.Field(SalesHeader.FieldNo("Document Date")).Value;
                end;
        end;
        case DataStorageProvider of
            DataStorageProvider::"Google Drive":
                begin
                    IdCarpetaOrigen := GoogleDriveManager.GetTargetFolderForDocument(Origen, DocNo, DocDate, DataStorageProvider);
                    IdCarpetaDestino := GoogleDriveManager.GetTargetFolderForDocument(TableId, DocumentAttachment."No.", Fecha, DataStorageProvider);
                    DocumentAttachment."Google Drive ID" := GoogleDriveManager.MoveFile(DocumentAttachment."Google Drive ID", IdCarpetaDestino, IdCarpetaOrigen);
                    DocumentAttachment.Modify();
                end;
            DataStorageProvider::OneDrive:
                begin
                    IdCarpetaOrigen := OnDriveManager.GetTargetFolderForDocument(Origen, DocNo, DocDate, DataStorageProvider);
                    IdCarpetaDestino := OnDriveManager.GetTargetFolderForDocument(TableId, DocumentAttachment."No.", Fecha, DataStorageProvider);
                    DocumentAttachment."OneDrive ID" := OnDriveManager.MoveFile(DocumentAttachment."OneDrive ID", IdCarpetaDestino, IdCarpetaOrigen, true, DocumentAttachment."File Name");
                    DocumentAttachment.Modify();
                end;
            DataStorageProvider::DropBox:
                begin
                    IdCarpetaOrigen := DropBoxManager.GetTargetFolderForDocument(Origen, DocNo, DocDate, DataStorageProvider);
                    IdCarpetaDestino := DropBoxManager.GetTargetFolderForDocument(TableId, DocumentAttachment."No.", Fecha, DataStorageProvider);
                    DocumentAttachment."DropBox ID" := DropBoxManager.MoveFile(DocumentAttachment."DropBox ID", IdCarpetaDestino, DocumentAttachment."File Name", true);
                    DocumentAttachment.Modify();
                end;
            DataStorageProvider::Strapi:
                begin
                    IdCarpetaOrigen := StrapiManager.GetTargetFolderForDocument(Origen, DocNo, DocDate, DataStorageProvider);
                    IdCarpetaDestino := StrapiManager.GetTargetFolderForDocument(TableId, DocumentAttachment."No.", Fecha, DataStorageProvider);
                    DocumentAttachment."Strapi ID" := StrapiManager.MoveFile(DocumentAttachment."Strapi ID", IdCarpetaDestino, IdCarpetaOrigen);
                    DocumentAttachment.Modify();
                end;
            DataStorageProvider::SharePoint:
                begin
                    IdCarpetaOrigen := SharePointManager.GetTargetFolderForDocument(Origen, DocNo, DocDate, DataStorageProvider);
                    IdCarpetaDestino := SharePointManager.GetTargetFolderForDocument(TableId, DocumentAttachment."No.", Fecha, DataStorageProvider);
                    DocumentAttachment."SharePoint ID" := SharePointManager.MoveFile(DocumentAttachment."SharePoint ID", IdCarpetaDestino, true, DocumentAttachment."File Name");
                    DocumentAttachment.Modify();
                end;
        end;
    end;


}