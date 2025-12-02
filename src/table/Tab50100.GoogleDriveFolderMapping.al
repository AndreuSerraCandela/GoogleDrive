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
                    If Confirm(RenameFolderMsg, false) Then
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
        DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
        DataStorageProvider: Enum "Data Storage Provider";
    begin
        DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
        case DataStorageProvider of
            DataStorageProvider::"Google Drive":
                exit(GoogleDriveManager.RecuperaIdFolder(Id, Folder, Files, Crear, RootFolder));
            DataStorageProvider::OneDrive:
                exit(OnDriveManager.RecuperaIdFolder(Id, Folder, Files, Crear, RootFolder));
            DataStorageProvider::DropBox:
                exit(DropBoxManager.RecuperaIdFolder(Id, Folder, Files, Crear, RootFolder));
            DataStorageProvider::Strapi:
                exit(StrapiManager.RecuperaIdFolder(Id, Folder, Files, Crear, RootFolder));
            DataStorageProvider::SharePoint:
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
        SubfolderPath2: Text;
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
        if (StrPos(SubfolderPath, '{DOCNO}') > 0) or (StrPos(SubfolderPath, '{NODOC}') > 0) then
            SubfolderPath2 := DocumentNo;
        if (StrPos(SubfolderPath, '{NO}') > 0) or (StrPos(SubfolderPath, '{CODIGO}') > 0) then
            SubfolderPath2 := DocumentNo;
        if DocumentDate = 0D then
            exit(SubfolderPath2);
        if (StrPos(SubfolderPath, '{YEAR}') > 0) or (StrPos(SubfolderPath, '{AÑO}') > 0) then begin
            Year := Format(Date2DMY(DocumentDate, 3));
            SubfolderPath2 := Year;
        end;

        if (StrPos(SubfolderPath, '{MONTH}') > 0) or (StrPos(SubfolderPath, '{MES}') > 0) then begin
            Month := Format(DocumentDate, 0, '<Month Text>');
            SubfolderPath2 := Month;
        end;
        if (StrPos(SubfolderPath, '{YEAR}/{MONTH}') > 0) or (StrPos(SubfolderPath, '{AÑO}/{MES}') > 0) then begin
            Year := Format(Date2DMY(DocumentDate, 3));
            Month := Format(DocumentDate, 0, '<Month Text>');
            SubfolderPath2 := Year + '-' + Month;
        end;
        if (FolderMapping."Subfolder Pattern" = '{YEAR}/{DOCNO}') or (FolderMapping."Subfolder Pattern" = '{AÑO}/{NODOC}') then begin
            Year := Format(Date2DMY(DocumentDate, 3));
            SubfolderPath2 := Year + '/' + DocumentNo;
        end;
        if (FolderMapping."Subfolder Pattern" = '{YEAR}/{MONTH}') or (FolderMapping."Subfolder Pattern" = '{AÑO}/{MES}') then begin
            Year := Format(Date2DMY(DocumentDate, 3));
            Month := Format(DocumentDate, 0, '<Month Text>');
            SubfolderPath2 := Year + '/' + Month;
        end;
        if (FolderMapping."Subfolder Pattern" = '{YEAR}/{MONTH}/{NO}') or (FolderMapping."Subfolder Pattern" = '{AÑO}/{MES}/{CODIGO}') then begin
            Year := Format(Date2DMY(DocumentDate, 3));
            Month := Format(DocumentDate, 0, '<Month Text>');
            SubfolderPath2 := Year + '/' + Month + '/' + DocumentNo;
        end;
        if (FolderMapping."Subfolder Pattern" = '{YEAR}/{MONTH}/{DOCNO}') or (FolderMapping."Subfolder Pattern" = '{AÑO}/{MES}/{NODOC}') then begin
            Year := Format(Date2DMY(DocumentDate, 3));
            Month := Format(DocumentDate, 0, '<Month Text>');
            SubfolderPath2 := Year + '/' + Month + '/' + DocumentNo;
        end;


        exit(SubfolderPath2);



    end;

    procedure SetupDefaultMappings()
    var
        FolderMapping: Record "Google Drive Folder Mapping";
    begin
        // Sales Invoice Header
        if not FolderMapping.Get(112) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 112;
            FolderMapping."Default Folder Name" := SalesInvoicesFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternYearMonthLbl;
            FolderMapping.Description := SalesInvoiceHeaderDocsLbl;
            FolderMapping.Insert();
        end;
        //114
        if not FolderMapping.Get(114) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 114;
            FolderMapping."Default Folder Name" := SalesCreditMemosFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternYearMonthLbl;
            FolderMapping.Description := SalesCreditMemoHeaderDocsLbl;
            FolderMapping.Insert();
        end;
        //122
        if not FolderMapping.Get(122) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 122;
            FolderMapping."Default Folder Name" := PurchaseInvoicesFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternYearMonthLbl;
            FolderMapping.Description := PurchaseInvoiceHeaderDocsLbl;
            FolderMapping.Insert();
        end;
        //124
        if not FolderMapping.Get(124) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 124;
            FolderMapping."Default Folder Name" := PurchaseCreditMemosFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternYearMonthLbl;
            FolderMapping.Description := PurchaseCreditMemoHeaderDocsLbl;
            FolderMapping.Insert();
        end;

        // Sales Header
        if not FolderMapping.Get(36) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 36;
            FolderMapping."Default Folder Name" := SalesOrdersFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternYearLbl;
            FolderMapping.Description := SalesHeaderDocsLbl;
            FolderMapping.Insert();
        end;

        // Purchase Header
        if not FolderMapping.Get(38) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 38;
            FolderMapping."Default Folder Name" := PurchaseOrdersFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternYearLbl;
            FolderMapping.Description := PurchaseHeaderDocsLbl;
            FolderMapping.Insert();
        end;

        // Customer
        if not FolderMapping.Get(18) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 18;
            FolderMapping."Default Folder Name" := CustomersFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternNoLbl;
            FolderMapping.Description := CustomerDocsLbl;
            FolderMapping.Insert();
        end;

        // Vendor
        if not FolderMapping.Get(23) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 23;
            FolderMapping."Default Folder Name" := VendorsFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternNoLbl;
            FolderMapping.Description := VendorDocsLbl;
            FolderMapping.Insert();
        end;

        // Contact
        if not FolderMapping.Get(5050) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 5050;
            FolderMapping."Default Folder Name" := ContactsFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternNoLbl;
            FolderMapping.Description := ContactDocsLbl;
            FolderMapping.Insert();
        end;

        // Opportunity
        if not FolderMapping.Get(5092) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 5092;
            FolderMapping."Default Folder Name" := OpportunitiesFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternYearLbl;
            FolderMapping.Description := OpportunityDocsLbl;
            FolderMapping.Insert();
        end;
        //27
        if not FolderMapping.Get(27) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 27;
            FolderMapping."Default Folder Name" := ItemsFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternNoLbl;
            FolderMapping.Description := ItemDocsLbl;
            FolderMapping.Insert();
        end;
        //167
        if not FolderMapping.Get(Database::Job) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := Database::Job;
            FolderMapping."Default Folder Name" := JobsFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternNoLbl;
            FolderMapping.Description := JobDocsLbl;
            FolderMapping.Insert();
        end;
        //15
        if not FolderMapping.Get(15) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 15;
            FolderMapping."Default Folder Name" := GLAccountsFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternNoLbl;
            FolderMapping.Description := GLAccountDocsLbl;
            FolderMapping.Insert();
        end;
        //5600
        if not FolderMapping.Get(5600) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 5600;
            FolderMapping."Default Folder Name" := FixedAssetsFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternNoLbl;
            FolderMapping.Description := FixedAssetDocsLbl;
            FolderMapping.Insert();
        end;
        //Database::Employee
        if not FolderMapping.Get(Database::Employee) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := Database::Employee;
            FolderMapping."Default Folder Name" := EmployeesFolderLbl;
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := SubfolderPatternNoLbl;
            FolderMapping.Description := EmployeeDocsLbl;
            FolderMapping.Insert();
        end;

        Message(SetupDefaultMappingsMsg);
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
        DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
        DataStorageProvider: Enum "Data Storage Provider";
    begin
        DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
        case DataStorageProvider of
            DataStorageProvider::"Google Drive":
                exit(GoogleDriveManager.RenameFolder(RootFolderID, RootFolder));
            DataStorageProvider::OneDrive:
                exit(OnDriveManager.RenameFolder(RootFolderID, RootFolder));
            DataStorageProvider::DropBox:
                exit(DropBoxManager.RenameFolder(RootFolderID, RootFolder));
            DataStorageProvider::Strapi:
                exit(StrapiManager.RenameFolder(RootFolderID, RootFolder));
            DataStorageProvider::SharePoint:
                exit(SharePointManager.RenameFolder(RootFolderID, RootFolder));
        end;
    end;

    internal procedure MoveFileH(DataStorageProvider: Enum "Data Storage Provider";
    var DocumentAttachment: Record "Document Attachment";
    Origen: Integer; TableId: Integer;
    Var RecRef: RecordRef;
    FechaOrigen: Date; FechaDestino: Date; DocOrigenNo: Text; DocDestino: Text): boolean
    var
        IsDrive: Boolean;

    begin
        IsDrive := (DocumentAttachment."Google Drive ID" <> '') or
        (DocumentAttachment."OneDrive ID" <> '') or
        (DocumentAttachment."DropBox ID" <> '') or
        (DocumentAttachment."Strapi ID" <> '') or
        (DocumentAttachment."SharePoint ID" <> '');
        if IsDrive then
            If Not TryMoveFileH(DataStorageProvider, DocumentAttachment, Origen, TableId, RecRef, FechaOrigen, FechaDestino, DocOrigenNo, DocDestino)
            then
                exit(false);
        exit(true);
    end;

    [TryFunction]
    local procedure TryMoveFileH(DataStorageProvider: Enum "Data Storage Provider";
    var DocumentAttachment: Record "Document Attachment";
    Origen: Integer; TableId: Integer;
    Var RecRef: RecordRef;
    FechaOrigen: Date; FechaDestino: Date; DocOrigenNo: Text; DocDestino: Text)
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

    begin
        // Case Origen of
        //     Database::"Purchase Header":
        //         begin
        //             DocNo := RecRef.Field(PurchaseHeader.FieldNo("No.")).Value;
        //             DocDate := RecRef.Field(PurchaseHeader.FieldNo("Document Date")).Value;
        //         end;
        //     Database::"Sales Header":
        //         begin
        //             DocNo := RecRef.Field(SalesHeader.FieldNo("No.")).Value;
        //             DocDate := RecRef.Field(SalesHeader.FieldNo("Document Date")).Value;
        //         end;
        // end;

        case DataStorageProvider of
            DataStorageProvider::"Google Drive":
                begin
                    IdCarpetaOrigen := GoogleDriveManager.GetTargetFolderForDocument(Origen, DocOrigenNo, FechaOrigen, DataStorageProvider);
                    IdCarpetaDestino := GoogleDriveManager.GetTargetFolderForDocument(TableId, DocDestino, FechaDestino, DataStorageProvider);
                    DocumentAttachment."Google Drive ID" := GoogleDriveManager.CopyFile(DocumentAttachment."Google Drive ID", IdCarpetaDestino);
                    DocumentAttachment.Modify();
                end;
            DataStorageProvider::OneDrive:
                begin
                    IdCarpetaOrigen := OnDriveManager.GetTargetFolderForDocument(Origen, DocOrigenNo, FechaOrigen, DataStorageProvider);
                    IdCarpetaDestino := OnDriveManager.GetTargetFolderForDocument(TableId, DocDestino, FechaDestino, DataStorageProvider);
                    DocumentAttachment."OneDrive ID" := OnDriveManager.MoveFile(DocumentAttachment."OneDrive ID", IdCarpetaDestino, IdCarpetaOrigen, false, DocumentAttachment."File Name");
                    DocumentAttachment.Modify();
                end;
            DataStorageProvider::DropBox:
                begin
                    IdCarpetaOrigen := DropBoxManager.GetTargetFolderForDocument(Origen, DocOrigenNo, FechaOrigen, DataStorageProvider);
                    IdCarpetaDestino := DropBoxManager.GetTargetFolderForDocument(TableId, DocDestino, FechaDestino, DataStorageProvider);
                    DocumentAttachment."DropBox ID" := DropBoxManager.MoveFile(DocumentAttachment."DropBox ID", IdCarpetaDestino, DocumentAttachment."File Name", false);
                    DocumentAttachment.Modify();
                end;
            DataStorageProvider::Strapi:
                begin
                    IdCarpetaOrigen := StrapiManager.GetTargetFolderForDocument(Origen, DocOrigenNo, FechaOrigen, DataStorageProvider);
                    IdCarpetaDestino := StrapiManager.GetTargetFolderForDocument(TableId, DocDestino, FechaDestino, DataStorageProvider);
                    DocumentAttachment."Strapi ID" := StrapiManager.CopyFile(DocumentAttachment."Strapi ID", IdCarpetaDestino, IdCarpetaOrigen);
                    DocumentAttachment.Modify();
                end;
            DataStorageProvider::SharePoint:
                begin
                    IdCarpetaOrigen := SharePointManager.GetTargetFolderForDocument(Origen, DocOrigenNo, FechaOrigen, DataStorageProvider);
                    IdCarpetaDestino := SharePointManager.GetTargetFolderForDocument(TableId, DocDestino, FechaDestino, DataStorageProvider);
                    DocumentAttachment."SharePoint ID" := SharePointManager.MoveFile(DocumentAttachment."SharePoint ID", IdCarpetaDestino, false, DocumentAttachment."File Name");
                    DocumentAttachment.Modify();
                end;
        end;
    end;


    var
        SetupDefaultMappingsMsg: Label 'Default mappings created successfully.';
        RenameFolderMsg: Label 'Are you sure you want to rename folder?';
        SalesInvoicesFolderLbl: Label 'Sales Invoices';
        SalesCreditMemosFolderLbl: Label 'Sales Credit Memos';
        PurchaseInvoicesFolderLbl: Label 'Purchase Invoices';
        PurchaseCreditMemosFolderLbl: Label 'Purchase Credit Memos';
        SalesOrdersFolderLbl: Label 'Sales Orders';
        PurchaseOrdersFolderLbl: Label 'Purchase Orders';
        CustomersFolderLbl: Label 'Customers';
        VendorsFolderLbl: Label 'Vendors';
        ContactsFolderLbl: Label 'Contacts';
        OpportunitiesFolderLbl: Label 'Opportunities';
        ItemsFolderLbl: Label 'Items';
        JobsFolderLbl: Label 'Jobs';
        GLAccountsFolderLbl: Label 'G/L Accounts';
        FixedAssetsFolderLbl: Label 'Fixed Assets';
        EmployeesFolderLbl: Label 'Employees';
        SalesInvoiceHeaderDocsLbl: Label 'Sales Invoice Header documents';
        SalesCreditMemoHeaderDocsLbl: Label 'Sales Credit Memo Header documents';
        PurchaseInvoiceHeaderDocsLbl: Label 'Purchase Invoice Header documents';
        PurchaseCreditMemoHeaderDocsLbl: Label 'Purchase Credit Memo Header documents';
        SalesHeaderDocsLbl: Label 'Sales Header documents';
        PurchaseHeaderDocsLbl: Label 'Purchase Header documents';
        CustomerDocsLbl: Label 'Customer documents';
        VendorDocsLbl: Label 'Vendor documents';
        ContactDocsLbl: Label 'Contact documents';
        OpportunityDocsLbl: Label 'Opportunity documents';
        ItemDocsLbl: Label 'Item documents';
        JobDocsLbl: Label 'Job documents';
        GLAccountDocsLbl: Label 'G/L Account documents';
        FixedAssetDocsLbl: Label 'Fixed Asset documents';
        EmployeeDocsLbl: Label 'Employee documents';
        SubfolderPatternYearMonthLbl: Label '{YEAR}/{MONTH}';
        SubfolderPatternYearLbl: Label '{YEAR}';
        SubfolderPatternNoLbl: Label '{NO}';
}