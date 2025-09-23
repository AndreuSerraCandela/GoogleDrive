pageextension 95100 "Doc. Attachment Factbox Ext" extends "Doc. Attachment List Factbox"
{
    layout
    {
        addbefore("File Extension")
        {
            field("Store in Google Drive"; Rec."Store in Google Drive")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the attachment should be stored in Google Drive instead of in the database.';
                Caption = 'Store in Google Drive';
                Editable = false;
                Visible = IsGoogle;
            }
            field("Store in OneDrive"; Rec."Store in OneDrive")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the attachment should be stored in OneDrive instead of in the database.';
                Caption = 'Store in OneDrive';
                Editable = false;
                Visible = IsOndrive;
            }
            field("Store in DropBox"; Rec."Store in DropBox")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the attachment should be stored in DropBox instead of in the database.';
                Caption = 'Store in DropBox';
                Editable = false;
                Visible = IsDropBox;
            }
            field("Store in Strapi"; Rec."Store in Strapi")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the attachment should be stored in Strapi instead of in the database.';
                Caption = 'Store in Strapi';
                Editable = false;
                Visible = IsStrapi;
            }
            field("Store in SharePoint"; Rec."Store in SharePoint")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the attachment should be stored in SharePoint instead of in the database.';
                Caption = 'Store in SharePoint';
                Editable = false;
                Visible = IsSharePoint;
            }
            field("Google Drive ID"; Rec."Google Drive ID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the ID of the file in Google Drive.';
                Caption = 'Google Drive ID';
                Editable = false;
                Visible = false;// IsGoogle;

                trigger OnDrillDown()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                begin
                    GoogleDriveManager.OpenFileInBrowser(Rec."Google Drive ID");
                end;
            }
            field("OneDrive ID"; Rec."OneDrive ID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the ID of the file in OneDrive.';
                Caption = 'OneDrive ID';
                Editable = false;
                Visible = false;// IsOndrive;
                trigger OnDrillDown()
                var
                    OneDriveManager: Codeunit "OneDrive Manager";
                begin
                    OneDriveManager.OpenFileInBrowser(Rec."OneDrive ID", false);
                end;
            }
            field("DropBox ID"; Rec."DropBox ID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the ID of the file in DropBox.';
                Caption = 'DropBox ID';
                Editable = false;
                Visible = false;// IsDropBox;
                trigger OnDrillDown()
                var
                    DropBoxManager: Codeunit "DropBox Manager";
                begin
                    DropBoxManager.OpenFileInBrowser(Rec."DropBox ID");
                end;
            }
            field("Strapi ID"; Rec."Strapi ID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the ID of the file in Strapi.';
                Caption = 'Strapi ID';
                Editable = false;
                Visible = false;// IsStrapi;
                trigger OnDrillDown()
                var
                    StrapiManager: Codeunit "Strapi Manager";
                begin
                    StrapiManager.OpenFileInBrowser(Rec."Strapi ID");
                end;
            }
            field("SharePoint ID"; Rec."SharePoint ID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the ID of the file in SharePoint.';
                Caption = 'SharePoint ID';
                Editable = false;
                Visible = false;// IsSharePoint;
            }
        }
        addlast(content)
        {
            group(Group1)
            {
                ShowCaption = false;
                Visible = true;//VisibleControl1;
                usercontrol(PDFViewer1; "PDFV PDF Viewer")
                {
                    ApplicationArea = All;
                    Visible = IsDrive;
                    trigger ControlAddinReady()
                    var
                        URL: Text;
                        UrlProvider: Text;
                        StorageProvider: Enum "Data Storage Provider";
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                        OneDriveManager: Codeunit "OneDrive Manager";
                        DropBoxManager: Codeunit "DropBox Manager";
                        StrapiManager: Codeunit "Strapi Manager";
                        Id: Integer;
                        DriveType: Text;
                        Language: Text;
                        WindowsLanguage: Record "Windows Language";
                        IdLanguage: Integer;
                    begin
                        IdLanguage := GlobalLanguage;
                        If WindowsLanguage.Get(IdLanguage) then begin
                            IdLanguage := WindowsLanguage."Primary Language ID";
                        end;
                        Case IdLanguage of
                            1034:
                                Language := 'es-ES';
                            else
                                Language := 'en-US';

                        end;
                        CurrPage.PDFViewer1.InitializeControl('controlAddIn', Language);
                        IsControlAddInReady := true;
                        If Rec."Store in Google Drive" then begin
                            URL := Rec."Google Drive ID";
                            UrlProvider := Url;//GoogleDriveManager.GetUrl(URL);
                            StorageProvider := StorageProvider::"Google Drive";
                            DriveType := 'google';
                        end;
                        if Rec."Store in OneDrive" then begin
                            URL := Rec."OneDrive ID";
                            UrlProvider := OneDriveManager.GetPdfBase64(URL);
                            URL := UrlProvider;
                            DriveType := 'onedrive';
                        end;
                        if Rec."Store in DropBox" then begin
                            URL := Rec."DropBox ID";
                            UrlProvider := Url;//DropBoxManager.GetUrl(URL);
                            StorageProvider := StorageProvider::DropBox;
                            DriveType := 'dropbox';
                        end;
                        if Rec."Store in Strapi" then begin
                            URL := Rec."Strapi ID";
                            UrlProvider := url;//StrapiManager.GetUrl(URL);
                            StorageProvider := StorageProvider::Strapi;
                            DriveType := 'strapi';
                        end;
                        if Rec."Store in SharePoint" then begin
                            URL := Rec."SharePoint ID";
                            UrlProvider := Url;//SharePointManager.GetUrl(URL);
                            StorageProvider := StorageProvider::SharePoint;
                            DriveType := 'sharepoint';
                        end;

                        if URL <> '' then
                            SetPDFDocumentUrl(URL, 1, (Rec."File Type" = Rec."File Type"::PDF), Rec."File Name", StorageProvider, UrlProvider, DriveType)
                        else
                            SetPDFDocument(GetPDFAsTxt(Rec), 1, (Rec."File Type" = Rec."File Type"::PDF), UrlProvider, DriveType);
                    end;

                    trigger onView()
                    begin
                        RunFullView(Rec);
                    end;

                    trigger OnSiguiente()
                    var
                        StorageProvider: Enum "Data Storage Provider";
                        URL: Text;
                        UrlProvider: Text;
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                        OneDriveManager: Codeunit "OneDrive Manager";
                        DropBoxManager: Codeunit "DropBox Manager";
                        StrapiManager: Codeunit "Strapi Manager";
                        SharePointManager: Codeunit "SharePoint Manager";
                        DriveType: Text;
                    begin
                        a += 1;
                        if Rec.next() = 0 then begin
                            If Not Rec.findlast() then exit;
                            a := Rec.Count;
                        end;

                        if Rec."Store in Google Drive" then begin
                            URL := Rec."Google Drive ID";
                            UrlProvider := GoogleDriveManager.GetUrl(URL);
                            StorageProvider := StorageProvider::"Google Drive";
                            DriveType := 'google';
                        end;
                        if Rec."Store in OneDrive" then begin
                            URL := Rec."OneDrive ID";
                            UrlProvider := OneDriveManager.GetUrl(URL);
                            StorageProvider := StorageProvider::OneDrive;
                            DriveType := 'onedrive';
                        end;
                        if Rec."Store in DropBox" then begin
                            URL := Rec."DropBox ID";
                            UrlProvider := DropBoxManager.GetUrl(URL);
                            StorageProvider := StorageProvider::DropBox;
                            DriveType := 'dropbox';
                        end;
                        if Rec."Store in Strapi" then begin
                            URL := Rec."Strapi ID";
                            UrlProvider := StrapiManager.GetUrl(URL);
                            StorageProvider := StorageProvider::Strapi;
                            DriveType := 'strapi';
                        end;
                        if Rec."Store in SharePoint" then begin
                            URL := Rec."SharePoint ID";
                            UrlProvider := Url;//SharePointManager.GetUrl(URL);
                            StorageProvider := StorageProvider::SharePoint;
                            DriveType := 'sharepoint';
                        end;
                        UrlProvider := Url;
                        if URL <> '' then
                            SetPDFDocumentUrl(URL, 1, (Rec."File Type" = Rec."File Type"::PDF), Rec."File Name", StorageProvider, UrlProvider, DriveType)
                        else
                            SetPDFDocument(GetPDFAsTxt(Rec), 1, (Rec."File Type" = Rec."File Type"::PDF), UrlProvider, DriveType);

                    end;

                    trigger OnAnterior()
                    var
                        StorageProvider: Enum "Data Storage Provider";
                        URL: Text;
                        UrlProvider: Text;
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                        OneDriveManager: Codeunit "OneDrive Manager";
                        DropBoxManager: Codeunit "DropBox Manager";
                        StrapiManager: Codeunit "Strapi Manager";
                        DriveType: Text;
                    begin
                        a -= 1;
                        if Rec.Next(-1) = 0 then begin
                            Rec.findfirst();
                            a := 1;
                        end;
                        if Rec."Store in Google Drive" then begin
                            URL := Rec."Google Drive ID";
                            UrlProvider := GoogleDriveManager.GetUrl(URL);
                            StorageProvider := StorageProvider::"Google Drive";
                            DriveType := 'google';
                        end;
                        if Rec."Store in OneDrive" then begin
                            URL := Rec."OneDrive ID";
                            UrlProvider := OneDriveManager.GetUrl(URL);
                            StorageProvider := StorageProvider::OneDrive;
                            DriveType := 'onedrive';
                        end;
                        if Rec."Store in DropBox" then begin
                            URL := Rec."DropBox ID";
                            UrlProvider := DropBoxManager.GetUrl(URL);
                            StorageProvider := StorageProvider::DropBox;
                            DriveType := 'dropbox';
                        end;
                        if Rec."Store in Strapi" then begin
                            URL := Rec."Strapi ID";
                            UrlProvider := StrapiManager.GetUrl(URL);
                            StorageProvider := StorageProvider::Strapi;
                            DriveType := 'strapi';
                        end;
                        if Rec."Store in SharePoint" then begin
                            URL := Rec."SharePoint ID";
                            UrlProvider := Url;//SharePointManager.GetUrl(URL);
                            StorageProvider := StorageProvider::SharePoint;
                            DriveType := 'sharepoint';
                        end;
                        UrlProvider := Url;
                        if URL <> '' then
                            SetPDFDocumentUrl(URL, 1, (Rec."File Type" = Rec."File Type"::PDF), Rec."File Name", StorageProvider, UrlProvider, DriveType)
                        else
                            SetPDFDocument(GetPDFAsTxt(Rec), 1, (Rec."File Type" = Rec."File Type"::PDF), UrlProvider, DriveType);

                    end;

                    trigger OnDownload()
                    var
                        PDFViewerCard: Page "PDF Viewer";
                        tempblob: Codeunit "Temp Blob";
                        DocumentStream: OutStream;
                        Base64Convert: Codeunit "Base64 Convert";
                        Int: InStream;
                        DocumentInStream: Instream;
                        FileName: Text;
                        Base64: Text;
                        FileManagement: Codeunit "File Management";
                        StorageProvider: Enum "Data Storage Provider";
                        URL: Text;
                    begin
                        if Rec."Store in Google Drive" then begin
                            URL := Rec."Google Drive ID";
                            StorageProvider := StorageProvider::"Google Drive";
                        end;
                        if Rec."Store in OneDrive" then begin
                            URL := Rec."OneDrive ID";
                            StorageProvider := StorageProvider::OneDrive;
                        end;
                        if Rec."Store in DropBox" then begin
                            URL := Rec."DropBox ID";
                            StorageProvider := StorageProvider::DropBox;
                        end;
                        if Rec."Store in Strapi" then begin
                            URL := Rec."Strapi ID";
                            StorageProvider := StorageProvider::Strapi;
                        end;
                        if Rec."Store in SharePoint" then begin
                            URL := Rec."SharePoint ID";
                            StorageProvider := StorageProvider::SharePoint;
                        end;
                        if URL <> '' then begin
                            TempBlob.CreateOutStream(DocumentStream);
                            If Not Rec.ToBase64StringOcr(URL, Base64, Rec."File Name", StorageProvider) then
                                exit;
                            Base64Convert.FromBase64(Base64, DocumentStream);
                            FileManagement.BLOBExport(TempBlob, Rec."File Name" + '.' + Rec."File Extension", true);
                        end;
                        if Rec.IsEmpty() then
                            exit;
                        TempBlob.CreateOutStream(DocumentStream);
                        Rec.Export(true);


                    end;

                    trigger FileUploaded(filesJson: Text)
                    var
                        Files: JsonArray;
                        JsonToken: JsonToken;
                        FileObject: JsonObject;
                        FileName: Text;
                        FileContent: Text;
                        TempBlob: Codeunit "Temp Blob";
                        OutStream: OutStream;
                        i: Integer;
                        DocumentAttachment: Record "Document Attachment";
                        Base64Convert: Codeunit "Base64 Convert";
                        RecRef: RecordRef;
                        Customer: Record Customer;
                        Vendor: Record Vendor;
                        Item: Record Item;
                        Employee: Record Employee;
                        FixedAsset: Record "Fixed Asset";
                        Resource: Record Resource;
                        Job: Record Job;
                        SalesHeader: Record "Sales Header";
                        SalesInvoiceHeader: Record "Sales Invoice Header";
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                        PurchaseHeader: Record "Purchase Header";
                        PurchInvHeader: Record "Purch. Inv. Header";
                        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                        VATReportHeader: Record "VAT Report Header";
                        ServiceItem: Record "Service Item";
                        ServiceHeader: Record "Service Header";
                        ServiceLine: Record "Service Line";
                        ServiceInvoiceHeader: Record "Service Invoice Header";
                        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
                        ServiceContractHeader: Record "Service Contract Header";
                        BankAccount: Record "Bank Account";
                        PurchRcptHeader: Record "Purch. Rcpt. Header";
                        SalesShipmentHeader: Record "Sales Shipment Header";
                        Ventana: Dialog;
                    begin
                        case Rec."Table ID" of
                            0:
                                exit;
                            Database::Customer:
                                begin
                                    RecRef.Open(Database::Customer);
                                    if Customer.Get(Rec."No.") then
                                        RecRef.GetTable(Customer);
                                end;
                            Database::Vendor:
                                begin
                                    RecRef.Open(Database::Vendor);
                                    if Vendor.Get(Rec."No.") then
                                        RecRef.GetTable(Vendor);
                                end;
                            Database::Item:
                                begin
                                    RecRef.Open(Database::Item);
                                    if Item.Get(Rec."No.") then
                                        RecRef.GetTable(Item);
                                end;
                            Database::"Bank Account":
                                begin
                                    RecRef.Open(Database::"Bank Account");
                                    if BankAccount.Get(Rec."No.") then
                                        RecRef.GetTable(BankAccount);
                                end;
                            Database::Employee:
                                begin
                                    RecRef.Open(Database::Employee);
                                    if Employee.Get(Rec."No.") then
                                        RecRef.GetTable(Employee);
                                end;
                            Database::"Fixed Asset":
                                begin
                                    RecRef.Open(Database::"Fixed Asset");
                                    if FixedAsset.Get(Rec."No.") then
                                        RecRef.GetTable(FixedAsset);
                                end;
                            Database::Resource:
                                begin
                                    RecRef.Open(Database::Resource);
                                    if Resource.Get(Rec."No.") then
                                        RecRef.GetTable(Resource);
                                end;
                            Database::Job:
                                begin
                                    RecRef.Open(Database::Job);
                                    if Job.Get(Rec."No.") then
                                        RecRef.GetTable(Job);
                                end;
                            Database::"Sales Header":
                                begin
                                    RecRef.Open(Database::"Sales Header");
                                    if SalesHeader.Get(Rec."Document Type", Rec."No.") then
                                        RecRef.GetTable(SalesHeader);
                                end;
                            Database::"Sales Invoice Header":
                                begin
                                    RecRef.Open(Database::"Sales Invoice Header");
                                    if SalesInvoiceHeader.Get(Rec."No.") then
                                        RecRef.GetTable(SalesInvoiceHeader);
                                end;
                            Database::"Sales Shipment Header":
                                begin
                                    RecRef.Open(Database::"Sales Shipment Header");
                                    if SalesShipmentHeader.Get(Rec."No.") then
                                        RecRef.GetTable(SalesShipmentHeader);
                                end;
                            Database::"Sales Cr.Memo Header":
                                begin
                                    RecRef.Open(Database::"Sales Cr.Memo Header");
                                    if SalesCrMemoHeader.Get(Rec."No.") then
                                        RecRef.GetTable(SalesCrMemoHeader);
                                end;
                            Database::"Purchase Header":
                                begin
                                    RecRef.Open(Database::"Purchase Header");
                                    if PurchaseHeader.Get(Rec."Document Type", Rec."No.") then
                                        RecRef.GetTable(PurchaseHeader);
                                end;
                            Database::"Purch. Inv. Header":
                                begin
                                    RecRef.Open(Database::"Purch. Inv. Header");
                                    if PurchInvHeader.Get(Rec."No.") then
                                        RecRef.GetTable(PurchInvHeader);
                                end;
                            Database::"Purch. Cr. Memo Hdr.":
                                begin
                                    RecRef.Open(Database::"Purch. Cr. Memo Hdr.");
                                    if PurchCrMemoHdr.Get(Rec."No.") then
                                        RecRef.GetTable(PurchCrMemoHdr);
                                end;
                            Database::"Purch. Rcpt. Header":
                                begin
                                    RecRef.Open(Database::"Purch. Rcpt. Header");
                                    if PurchRcptHeader.Get(Rec."No.") then
                                        RecRef.GetTable(PurchRcptHeader);
                                end;
                            Database::"VAT Report Header":
                                begin
                                    RecRef.Open(Database::"VAT Report Header");
                                    if VATReportHeader.Get(Rec."VAT Report Config. Code", Rec."No.") then
                                        RecRef.GetTable(VATReportHeader);
                                end;
                            Database::"Service Item":
                                begin
                                    RecRef.Open(Database::"Service Item");
                                    if ServiceItem.Get(Rec."No.") then
                                        RecRef.GetTable(ServiceItem);
                                end;
                            Database::"Service Header":
                                begin
                                    RecRef.Open(Database::"Service Header");
                                    if ServiceHeader.Get(Rec."Document Type", Rec."No.") then
                                        RecRef.GetTable(ServiceHeader);
                                end;
                            Database::"Service Line":
                                begin
                                    RecRef.Open(Database::"Service Line");
                                    if ServiceLine.Get(Rec."Document Type", Rec."No.", Rec."Line No.") then
                                        RecRef.GetTable(ServiceLine);
                                end;
                            Database::"Service Invoice Header":
                                begin
                                    RecRef.Open(Database::"Service Invoice Header");
                                    if ServiceInvoiceHeader.Get(Rec."No.") then
                                        RecRef.GetTable(ServiceInvoiceHeader);
                                end;
                            Database::"Service Cr.Memo Header":
                                begin
                                    RecRef.Open(Database::"Service Cr.Memo Header");
                                    if ServiceCrMemoHeader.Get(Rec."No.") then
                                        RecRef.GetTable(ServiceCrMemoHeader);
                                end;
                            Database::"Service Contract Header":
                                begin
                                    RecRef.Open(Database::"Service Contract Header");
                                    case Rec."Document Type" of
                                        Rec."Document Type"::"Service Contract":
                                            ServiceContractHeader."Contract Type" := ServiceContractHeader."Contract Type"::Contract;
                                        Rec."Document Type"::"Service Contract Quote":
                                            ServiceContractHeader."Contract Type" := ServiceContractHeader."Contract Type"::Quote;
                                    end;
                                    if ServiceContractHeader.Get(ServiceContractHeader."Contract Type", Rec."No.") then
                                        RecRef.GetTable(ServiceContractHeader);
                                end;

                        end;
                        CurrPage.PDFViewer1.ClearFiles();
                        Ventana.Open('Cargando archivos...###1# de ###2#\####################################3#');
                        if Files.ReadFrom(filesJson) then begin
                            Ventana.Update(2, Files.Count);
                            for i := 0 to Files.Count - 1 do begin
                                Ventana.Update(1, i + 1);

                                Files.Get(i, JsonToken);
                                FileObject := JsonToken.AsObject();

                                FileObject.Get('name', JsonToken);
                                FileName := JsonToken.AsValue().AsText();
                                Ventana.Update(3, FileName);
                                FileObject.Get('content', JsonToken);
                                FileContent := JsonToken.AsValue().AsText();
                                TempBlob.CreateOutStream(OutStream);
                                Base64Convert.FromBase64(FileContent, OutStream);
                                Clear(DocumentAttachment);
                                DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
                                Clear(TempBlob);
                                Clear(OutStream);
                            end;
                            VisibleControl1 := true;
                        end;
                        FileName := '';
                        Ventana.Close();
                        ActualizarRec();
                        CurrPage.Update(false);

                    end;
                }
            }
        }
    }

    actions
    {
        modify(OpenInOneDrive)
        {
            Visible = not IsDrive;
        }
        modify(ShareWithOneDrive)
        {
            Visible = not IsDrive;
        }
        modify(EditInOneDrive)
        {
            Visible = not IsDrive;
        }
        modify(DownloadInRepeater)
        {
            Visible = not IsDrive;
        }


        addafter(AttachmentsUpload)
        {
            action(UploadToGoogleDrive)
            {
                ApplicationArea = All;
                Caption = 'Load file from drive';
                Image = FileContract;
                Visible = IsDriveExt;
                trigger OnAction()
                var
                    DocumentAttachment: Record "Document Attachment";
                    DocAttachmentGrDriveMgmt: Codeunit "Doc. Attachment Mgmt. GDrive";
                    DocumentMgmt: Codeunit "Document Attachment Mgmt";
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    SharePointManager: Codeunit "SharePoint Manager";
                    RecRef: RecordRef;
                    IdTable: Integer;
                    IdTableFilter: Text;
                    No: Text;
                    Files: Record "Name/Value Buffer" temporary;
                    TargetFolderId: Text;
                    FilesSelected: Page "Google Drive List";
                    Id: Integer;
                    DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                    DataStorageProvider: Enum "Data Storage Provider";
                    FileMgt: Codeunit "File Management";
                    Date: Date;
                begin
                    DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();

                    IdTable := Rec."Table ID";
                    Date := ObtenerDate(Rec);
                    if IdTable = 0 then
                        IdTableFilter := Rec.GetFilter("Table ID");
                    if IdTable = 0 then
                        Evaluate(IdTable, IdTableFilter);
                    No := Rec."No.";

                    // Obtener la carpeta objetivo según el proveedor configurado
                    case DataStorageProvider of
                        DataStorageProvider::"Google Drive":
                            begin
                                TargetFolderId := GoogleDriveManager.GetTargetFolderForDocument(IdTable, No, Date, DataStorageProvider);
                                GoogleDriveManager.Carpetas(TargetFolderId, Files);
                            end;
                        DataStorageProvider::OneDrive:
                            begin
                                // Para OneDrive, usar la carpeta raíz por defecto
                                OneDriveManager.ListFolder('', Files, false);
                            end;
                        DataStorageProvider::DropBox:
                            begin
                                // Para DropBox, usar la carpeta raíz por defecto
                                DropBoxManager.ListFolder('', Files, false);
                            end;
                        DataStorageProvider::Strapi:
                            begin
                                // Para Strapi, listar todos los archivos
                                StrapiManager.ListFolder('', Files, false);
                            end;
                        DataStorageProvider::SharePoint:
                            begin
                                // Para SharePoint, listar todos los archivos
                                SharePointManager.ListFolder('', Files, false);
                            end;
                    end;

                    CurrPage.Update();
                    FilesSelected.SetRecords(TargetFolderId, Files, true);
                    If FilesSelected.RunModal() = Action::OK then begin
                        FilesSelected.SetSelectionFilter(Files);
                        GetRefTable(RecRef, Rec);
                        if Files.FindSet() then
                            repeat
                                Rec.Init();
                                Rec.ID := 0;
                                Rec.InitFieldsFromRecRef(RecRef);
                                Rec."Storage Provider" := DataStorageProvider;

                                // Asignar el ID según el proveedor
                                case DataStorageProvider of
                                    DataStorageProvider::"Google Drive":
                                        begin
                                            Rec."Store in Google Drive" := true;
                                            Rec."Google Drive ID" := Files."Google Drive ID";
                                        end;
                                    DataStorageProvider::OneDrive:
                                        begin
                                            Rec."Store in OneDrive" := true;
                                            Rec."OneDrive ID" := Files."Google Drive ID"; // Reutilizamos el campo
                                        end;
                                    DataStorageProvider::DropBox:
                                        begin
                                            Rec."Store in DropBox" := true;
                                            Rec."DropBox ID" := Files."Google Drive ID"; // Reutilizamos el campo
                                        end;
                                    DataStorageProvider::Strapi:
                                        begin
                                            Rec."Store in Strapi" := true;
                                            Rec."Strapi ID" := Files."Google Drive ID"; // Reutilizamos el campo
                                        end;
                                    DataStorageProvider::SharePoint:
                                        begin
                                            Rec."Store in SharePoint" := true;
                                            Rec."SharePoint ID" := Files."Google Drive ID"; // Reutilizamos el campo
                                        end;
                                end;

                                Rec."File Name" := Files.Name;
                                Rec.Validate("File Extension", FileMgt.GetExtension(Files.Name));
                                DocAttachmentGrDriveMgmt.SetDocumentAttachmentFileType(Rec, '');
                                if not Rec.WritePermission() then Error(MisisinDocActchPermision);
                                Rec.Insert(true);
                            until Files.Next() = 0;
                    end;
                end;
            }
            action(MoveToGoogleDrive)
            {
                ApplicationArea = All;
                Caption = 'Move to Drive';
                Image = SendTo;
                ToolTip = 'Moves selected documents to Drive and removes them from local storage.';
                Visible = IsDrive;
                trigger OnAction()
                var
                    DocumentAttachment: Record "Document Attachment";
                    TempBlob: Codeunit "Temp Blob";
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    FileId: Text;
                    ConfirmMsg: Label 'Are you sure you want to move the selected documents to Drive? The documents will be removed from local storage.';
                    SuccessMsg: Label 'Documents moved successfully to Drive.';
                    ErrorMsg: Label 'Error moving documents: %1';
                    FullFileName: Text;
                    DocumentStream: OutStream;
                    GoogleDriveFolderMapping: Record "Google Drive Folder Mapping";
                    GoogleDrive: Codeunit "Google Drive Manager";
                    Id: Text;
                    SubFolder: Text;
                    InStream: InStream;
                    TenantMedia: Record "Tenant Media";
                    DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                    DataStorageProvider: Enum "Data Storage Provider";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    SharePointManager: Codeunit "SharePoint Manager";
                    Path: Text;
                    FolderMapping: Record "Google Drive Folder Mapping";
                    Folder: Text;
                    AccessToken: Text;
                    Fecha: Date;
                begin
                    if not Confirm(ConfirmMsg) then
                        exit;
                    DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();


                    CurrPage.SetSelectionFilter(DocumentAttachment);
                    if DocumentAttachment.FindSet() then
                        repeat

                            If DocumentAttachment."Document Reference ID".HasValue() then begin
                                Fecha := ObtenerDate(DocumentAttachment);
                                // Recupear Registro de Documento

                                //
                                case DataStorageProvider of
                                    DataStorageProvider::"Google Drive":
                                        begin

                                            if not DocumentAttachment."Store in Google Drive" then begin
                                                FullFileName := DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension";
                                                Clear(DocumentStream);
                                                TempBlob.CreateOutStream(DocumentStream);
                                                FolderMapping.SetRange("Table ID", DocumentAttachment."Table ID");
                                                if FolderMapping.FindFirst() Then Folder := FolderMapping."Default Folder ID";
                                                SubFolder := FolderMapping.CreateSubfolderPath(DocumentAttachment."Table ID", DocumentAttachment."No.", Fecha, DataStorageProvider);
                                                IF SubFolder <> '' then
                                                    Folder := GoogleDriveManager.CreateFolderStructure(Folder, SubFolder);
                                                DocumentAttachment."Document Reference ID".ExportStream(DocumentStream);
                                                TempBlob.CreateInStream(InStream);
                                                FileId := GoogleDriveManager.UploadFileB64(Folder, InStream, DocumentAttachment."File Name", DocumentAttachment."File Extension");
                                                if FileId = '' then
                                                    Message(ErrorMsg, DocumentAttachment."File Name")
                                                else begin
                                                    DocumentAttachment."Store in Google Drive" := true;
                                                    Clear(DocumentAttachment."Document Reference ID");
                                                    DocumentAttachment."Google Drive ID" := FileId;
                                                    if not DocumentAttachment.WritePermission() then Error(MisisinDocActchPermision);
                                                    DocumentAttachment.Modify();

                                                end;
                                            end;
                                        end;
                                    DataStorageProvider::OneDrive:
                                        begin
                                            if not DocumentAttachment."Store in OneDrive" then begin
                                                Path := DocAttachmentMgmtGDrive.GetRootFolder() + '/';
                                                DocumentAttachment."Store in OneDrive" := true;
                                                FolderMapping.SetRange("Table ID", DocumentAttachment."Table ID");
                                                if FolderMapping.FindFirst() Then begin
                                                    Folder := FolderMapping."Default Folder Id";
                                                    Path += FolderMapping."Default Folder Name" + '/';
                                                end;
                                                SubFolder := FolderMapping.CreateSubfolderPath(DocumentAttachment."Table ID", DocumentAttachment."No.", Fecha, DataStorageProvider);
                                                IF SubFolder <> '' then begin
                                                    Folder := OneDriveManager.CreateFolderStructure(Folder, SubFolder);
                                                    Path += SubFolder + '/'
                                                end;
                                                Clear(DocumentStream);
                                                TempBlob.CreateOutStream(DocumentStream);
                                                DocumentAttachment."Document Reference ID".ExportStream(DocumentStream);
                                                TempBlob.CreateInStream(InStream);
                                                FileId := OneDriveManager.UploadFileB64(Path, InStream, DocumentAttachment."File Name", DocumentAttachment."File Extension");
                                                if FileId = '' then
                                                    Message(ErrorMsg, DocumentAttachment."File Name")
                                                else begin
                                                    DocumentAttachment."Store in OneDrive" := true;
                                                    Clear(DocumentAttachment."Document Reference ID");
                                                    DocumentAttachment."OneDrive ID" := FileId;
                                                    if not DocumentAttachment.WritePermission() then Error(MisisinDocActchPermision);
                                                    DocumentAttachment.Modify();
                                                end;
                                            end;
                                        end;
                                    DataStorageProvider::DropBox:
                                        begin
                                            if not DocumentAttachment."Store in DropBox" then begin
                                                FolderMapping.SetRange("Table ID", DocumentAttachment."Table ID");
                                                if FolderMapping.FindFirst() Then Folder := FolderMapping."Default Folder ID";
                                                SubFolder := FolderMapping.CreateSubfolderPath(DocumentAttachment."Table ID", DocumentAttachment."No.", Fecha, DataStorageProvider);
                                                IF SubFolder <> '' then
                                                    Folder := DropBoxManager.CreateFolderStructure(Folder, SubFolder);
                                                Clear(DocumentStream);
                                                TempBlob.CreateOutStream(DocumentStream);
                                                DocumentAttachment."Document Reference ID".ExportStream(DocumentStream);
                                                TempBlob.CreateInStream(InStream);
                                                FileId := DropBoxManager.UploadFileB64(Path, InStream, DocumentAttachment."File Name" + DocumentAttachment."File Extension");
                                                if FileId = '' then
                                                    Message(ErrorMsg, DocumentAttachment."File Name")
                                                else begin
                                                    DocumentAttachment."Store in DropBox" := true;
                                                    Clear(DocumentAttachment."Document Reference ID");
                                                    DocumentAttachment."DropBox ID" := FileId;
                                                    if not DocumentAttachment.WritePermission() then Error(MisisinDocActchPermision);
                                                    DocumentAttachment.Modify();
                                                end;

                                            end;
                                        end;
                                    DataStorageProvider::Strapi:
                                        begin
                                            if not DocumentAttachment."Store in Strapi" then begin
                                                Path := DocAttachmentMgmtGDrive.GetRootFolder() + '/';
                                                DocumentAttachment."Store in OneDrive" := true;
                                                FolderMapping.SetRange("Table ID", DocumentAttachment."Table ID");
                                                if FolderMapping.FindFirst() Then begin
                                                    Folder := FolderMapping."Default Folder Id";
                                                    Path += FolderMapping."Default Folder Name" + '/';
                                                end;
                                                ;
                                                SubFolder := FolderMapping.CreateSubfolderPath(DocumentAttachment."Table ID", DocumentAttachment."No.", Fecha, DataStorageProvider);
                                                IF SubFolder <> '' then begin
                                                    Folder := StrapiManager.CreateFolderStructure(Folder, SubFolder);
                                                    Path += SubFolder + '/'
                                                end;
                                                Clear(DocumentStream);
                                                TempBlob.CreateOutStream(DocumentStream);
                                                DocumentAttachment."Document Reference ID".ExportStream(DocumentStream);
                                                TempBlob.CreateInStream(InStream);
                                                FileId := StrapiManager.UploadFileB64(Path, InStream, DocumentAttachment."File Name" + DocumentAttachment."File Extension");
                                                if FileId = '' then
                                                    Message(ErrorMsg, DocumentAttachment."File Name")
                                            end;
                                        end;
                                    DataStorageProvider::SharePoint:
                                        begin
                                            if not DocumentAttachment."Store in SharePoint" then begin
                                                Path := DocAttachmentMgmtGDrive.GetRootFolder() + '/';
                                                DocumentAttachment."Store in OneDrive" := true;
                                                FolderMapping.SetRange("Table ID", DocumentAttachment."Table ID");
                                                if FolderMapping.FindFirst() Then begin
                                                    Folder := FolderMapping."Default Folder Id";
                                                    Path += FolderMapping."Default Folder Name" + '/';
                                                end;
                                                SubFolder := FolderMapping.CreateSubfolderPath(DocumentAttachment."Table ID", DocumentAttachment."No.", Fecha, DataStorageProvider);
                                                IF SubFolder <> '' then begin
                                                    Folder := SharePointManager.CreateFolderStructure(Folder, SubFolder);
                                                    Path += SubFolder + '/'
                                                end;
                                                Clear(DocumentStream);
                                                TempBlob.CreateOutStream(DocumentStream);
                                                DocumentAttachment."Document Reference ID".ExportStream(DocumentStream);
                                                TempBlob.CreateInStream(InStream);
                                                FileId := SharePointManager.UploadFileB64(Path, InStream, DocumentAttachment."File Name", DocumentAttachment."File Extension");
                                                if FileId = '' then
                                                    Message(ErrorMsg, DocumentAttachment."File Name")
                                            end;
                                        end;
                                end;
                            end;
                        until DocumentAttachment.Next() = 0;

                    Message(SuccessMsg);
                    CurrPage.Update();
                end;
            }
        }

        addafter(MoveToGoogleDrive)
        {
            action("Editar en Drive")
            {
                ApplicationArea = All;
                Caption = 'Edit in Drive';
                Image = Edit;
                ToolTip = 'Edits the file in Drive.';
                Scope = Repeater;
                Visible = IsDrive;
                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    SharePointManager: Codeunit "SharePoint Manager";
                    GoogleDrive: Codeunit "Google Drive Manager";
                    OneDrive: Codeunit "OneDrive Manager";
                    DropBox: Codeunit "DropBox Manager";
                    Strapi: Codeunit "Strapi Manager";
                    DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                    DataStorageProvider: Enum "Data Storage Provider";
                begin
                    DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
                    case DataStorageProvider of
                        DataStorageProvider::"Google Drive":
                            GoogleDrive.EditFile(Rec."Google Drive ID");
                        DataStorageProvider::OneDrive:
                            OneDrive.EditFile(Rec."OneDrive ID");
                        DataStorageProvider::DropBox:
                            DropBox.EditFile(Rec."DropBox ID");
                        DataStorageProvider::Strapi:
                            Strapi.EditFile(Rec."Strapi ID");
                        DataStorageProvider::SharePoint:
                            SharePointManager.EditFile(Rec."SharePoint ID");
                    end;
                end;
            }
            action(DownloadFile)
            {
                Visible = IsDriveExt;
                ApplicationArea = All;
                Caption = 'Download File';
                Image = Download;
                ToolTip = 'Downloads the file from cloud storage.';
                Scope = Repeater;
                trigger OnAction()
                var
                    Base64Txt: Text;
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    SharePointManager: Codeunit "SharePoint Manager";
                begin
                    case Rec."Storage Provider" of
                        Rec."Storage Provider"::"Google Drive":
                            If Not GoogleDriveManager.DownloadFileB64(Rec.GetDocumentID(), Rec."File Name", true, Base64Txt) then
                                exit;
                        Rec."Storage Provider"::OneDrive:
                            If Not OneDriveManager.DownloadFileB64(Base64Txt, Rec."File Name", true, Base64Txt) then
                                exit;
                        Rec."Storage Provider"::DropBox:
                            If Not DropBoxManager.DownloadFileB64('', Rec."File Name", true, Base64Txt) then
                                exit;
                        Rec."Storage Provider"::Strapi:
                            Base64Txt := StrapiManager.DownloadFileB64('', Base64Txt, Rec."File Name", true);
                        Rec."Storage Provider"::SharePoint:
                            SharePointManager.DownloadFileB64(Rec."SharePoint ID", Rec."File Name", true, Base64Txt);
                    end;
                end;
            }

            action(MoveFile)
            {
                Visible = IsDriveExt;
                ApplicationArea = All;
                Caption = 'Move';
                Image = Change;
                ToolTip = 'Moves the file to another folder.';
                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    SharePointManager: Codeunit "SharePoint Manager";
                    GoogleDriveList: Page "Google Drive List";

                    destino: Text;
                    TempFiles: Record "Name/Value Buffer" temporary;
                    GoogleDrive: Codeunit "Google Drive Manager";
                    root: Boolean;
                    CarpetaAnterior: List of [Text];
                    DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                    DataStorageProvider: Enum "Data Storage Provider";
                    NewId: Text;
                    NombreCarpetaDestino: Text;
                    DocRef: RecordRef;
                    FieldRef: FieldRef;
                begin
                    DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
                    case DataStorageProvider of
                        DataStorageProvider::"Google Drive":
                            begin
                                GoogleDrive.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, false);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);

                                // Here we would need to implement a folder selection dialog using TempFiles
                                // For now, we'll use a placeholder solution

                                if destino = '' then
                                    Message(NoDestinationSelectedLbl)
                                else
                                    GoogleDrive.Movefile(Rec."Google Drive ID", Destino, '');


                            end;
                        DataStorageProvider::OneDrive:
                            begin
                                OneDriveManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                Commit;
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                if destino = '' then
                                    Message(NoDestinationSelectedLbl)
                                else
                                    NewId := OneDriveManager.Movefile(Rec."OneDrive ID", Destino, '', true, Rec."File Name" + '.' + Rec."File Extension");
                                if NewId <> '' then begin
                                    Rec."OneDrive ID" := NewId;
                                    if not Rec.WritePermission() then Error(MisisinDocActchPermision);
                                    Rec.Modify();
                                end;
                            end;
                        DataStorageProvider::DropBox:
                            // DropBoxManager.MoveFile(Rec.GetDocumentID(), destino, Rec."File Name");
                            begin
                                DropBoxManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                Commit;
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                if destino = '' then
                                    Message(NoDestinationSelectedLbl)
                                else
                                    NewId := DropBoxManager.MoveFile(Rec."DropBox ID", Destino, Rec."File Name" + '.' + Rec."File Extension", true);
                                if NewId <> '' then begin
                                    Rec."DropBox ID" := NewId;
                                    if not Rec.WritePermission() then Error(MisisinDocActchPermision);
                                    Rec.Modify();
                                end;
                            end;
                        DataStorageProvider::Strapi:
                            begin
                                StrapiManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                Commit;
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                if destino = '' then
                                    Message(NoDestinationSelectedLbl)
                                else
                                    NewId := StrapiManager.MoveFile(Rec."Strapi ID", Destino, Rec."File Name" + '.' + Rec."File Extension");
                                if NewId <> '' then begin
                                    Rec."Strapi ID" := NewId;
                                    if not Rec.WritePermission() then Error(MisisinDocActchPermision);
                                    Rec.Modify();
                                end;
                            end;
                        DataStorageProvider::SharePoint:
                            begin
                                SharePointManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                Commit;
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                if destino = '' then
                                    Message(NoDestinationSelectedLbl)
                                else
                                    NewId := SharePointManager.MoveFile(Rec."SharePoint ID", Destino, true, Rec."File Name" + '.' + Rec."File Extension");
                                if NewId <> '' then begin
                                    Rec."SharePoint ID" := NewId;
                                    if not Rec.WritePermission() then Error(MisisinDocActchPermision);
                                    Rec.Modify();
                                end;
                            end;
                    end;
                    if NombreCarpetaDestino <> '' then begin
                        Case Rec."Table ID" of
                            Database::Customer, Database::Vendor, Database::Item, Database::"Bank Account", Database::"G/L Account", Database::"Fixed Asset", Database::Employee, Database::Job, Database::Resource:
                                begin
                                    DocRef.Open(Rec."Table ID");
                                    FieldRef.SetRange(DocRef.Field(1), NombreCarpetaDestino);
                                    If DocRef.FindFirst() then begin
                                        Rec."No." := NombreCarpetaDestino;
                                        if not Rec.WritePermission() then Error(MisisinDocActchPermision);
                                        Rec.Modify();
                                    End;
                                end;
                        end;
                    end;
                end;
            }

            action(CopyFile)
            {
                Visible = IsDriveExt;
                ApplicationArea = All;
                Caption = 'Copy File';
                Image = Copy;
                ToolTip = 'Copies the file to another folder.';
                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    SharePointManager: Codeunit "SharePoint Manager";
                    GoogleDriveList: Page "Google Drive List";
                    destino: Text;
                    TempFiles: Record "Name/Value Buffer" temporary;
                    GoogleDrive: Codeunit "Google Drive Manager";
                    root: Boolean;
                    CarpetaAnterior: List of [Text];
                    DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                    DataStorageProvider: Enum "Data Storage Provider";
                    NewId: Text;
                    NombreCarpetaDestino: Text;
                    // TODO: Implementar diálogo de selección de carpeta destino
                    DocRef: RecordRef;
                    FieldRef: FieldRef;
                    Id: Integer;
                    DocumentAttachment: Record "Document Attachment";
                begin
                    case Rec."Storage Provider" of
                        Rec."Storage Provider"::"Google Drive":
                            begin
                                GoogleDrive.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, false);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                if destino = '' then
                                    Message(NoDestinationSelectedLbl)
                                else
                                    GoogleDrive.Copyfile(Rec."Google Drive ID", Destino);
                            end;
                        Rec."Storage Provider"::OneDrive:
                            begin
                                OneDriveManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                Commit;
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                if destino = '' then
                                    Message(NoDestinationSelectedLbl)
                                else
                                    NewId := OneDriveManager.Movefile(Rec."OneDrive ID", Destino, '', false, Rec."File Name" + '.' + Rec."File Extension");

                            end;
                        Rec."Storage Provider"::DropBox:
                            begin
                                DropBoxManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                Commit;
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                if destino = '' then
                                    Message(NoDestinationSelectedLbl)
                                else
                                    NewId := DropBoxManager.MoveFile(Rec."DropBox ID", Destino, Rec."File Name" + '.' + Rec."File Extension", false);
                                if NewId <> '' then begin
                                    Rec."DropBox ID" := NewId;
                                    if not Rec.WritePermission() then Error(MisisinDocActchPermision);
                                    Rec.Modify();
                                end;
                            end;
                        Rec."Storage Provider"::Strapi:
                            begin
                                StrapiManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                Commit;
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                if destino = '' then
                                    Message(NoDestinationSelectedLbl)
                                else
                                    NewId := StrapiManager.MoveFile(Rec."Strapi ID", Destino, Rec."File Name" + '.' + Rec."File Extension");
                                if NewId <> '' then begin
                                    Rec."Strapi ID" := NewId;
                                    if not Rec.WritePermission() then Error(MisisinDocActchPermision);
                                    Rec.Modify();
                                end;
                            end;
                        Rec."Storage Provider"::SharePoint:
                            begin
                                SharePointManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                Commit;
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                if destino = '' then
                                    Message(NoDestinationSelectedLbl)
                                else
                                    NewId := SharePointManager.MoveFile(Rec."SharePoint ID", Destino, true, Rec."File Name" + '.' + Rec."File Extension");
                                if NewId <> '' then begin
                                    Rec."SharePoint ID" := NewId;
                                    if not Rec.WritePermission() then Error(MisisinDocActchPermision);
                                    Rec.Modify();
                                end;
                            end;
                    end;
                    if NombreCarpetaDestino <> '' then begin
                        Case Rec."Table ID" of
                            Database::Customer, Database::Vendor, Database::Item, Database::"Bank Account", Database::"G/L Account", Database::"Fixed Asset", Database::Employee, Database::Job, Database::Resource:
                                begin
                                    DocRef.Open(Rec."Table ID");
                                    FieldRef.SetRange(DocRef.Field(1), NombreCarpetaDestino);
                                    If DocRef.FindFirst() then begin
                                        DocumentAttachment.SetRange("Table ID", Rec."Table ID");
                                        DocumentAttachment.SetRange("No.", NombreCarpetaDestino);
                                        if DocumentAttachment.FindLast() then Id := DocumentAttachment.ID;
                                        DocumentAttachment := Rec;
                                        DocumentAttachment."No." := NombreCarpetaDestino;
                                        DocumentAttachment.ID := Id + 1;
                                        if not DocumentAttachment.WritePermission() then Error(MisisinDocActchPermision);
                                        DocumentAttachment.Insert();
                                    End;
                                end;
                        end;
                    end;
                end;
            }

            action(CreateFolder)
            {
                Visible = IsDriveExt;
                ApplicationArea = All;
                Caption = 'Create Folder';
                Image = ToggleBreakpoint;
                ToolTip = 'Creates a folder in cloud storage.';
                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    SharePointManager: Codeunit "SharePoint Manager";
                    DialogPage: Page "Dialogo Google Drive";
                    FolderName: Text;
                    Id: Text;
                    SubFolder: Text;
                    path: Text;
                    DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                    DataStorageProvider: Enum "Data Storage Provider";
                    FolderMapping: Record "Google Drive Folder Mapping";
                    Date: Date;
                begin
                    DialogPage.SetTexto('Nombre Carpeta');
                    DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
                    if DialogPage.RunModal() = Action::OK then begin
                        DialogPage.GetTexto(FolderName);
                        Date := ObtenerDate(Rec);
                        if FolderName <> '' then begin
                            case DataStorageProvider of
                                DataStorageProvider::"Google Drive":
                                    begin
                                        GoogleDriveManager.GetFolderMapping(Rec."Table ID", Id);
                                        SubFolder := GoogleDriveManager.CreateFolderStructure(Id, Rec."No.");
                                        if SubFolder <> '' then
                                            Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
                                        GoogleDriveManager.CreateFolder(FolderName, Id, false);

                                    end;
                                DataStorageProvider::OneDrive:
                                    begin
                                        OneDriveManager.GetFolderMapping(Rec."Table ID", Id);
                                        SubFolder := FolderMapping.CreateSubfolderPath(Rec."Table ID", Rec."No.", Date, DataStorageProvider);
                                        SubFolder := OneDriveManager.FindOrCreateSubfolder(Id, SubFolder, true);
                                        OneDriveManager.CreateFolderStructure(SubFolder, FolderName);
                                    end;
                                DataStorageProvider::DropBox:
                                    begin
                                        DropBoxManager.GetFolderMapping(Rec."Table ID", Id);
                                        SubFolder := DropBoxManager.CreateFolderStructure(Id, Rec."No.");
                                        if SubFolder <> '' then
                                            Id := DropBoxManager.CreateFolderStructure(Id, SubFolder);
                                        DropBoxManager.CreateFolder(FolderName, Id, false);
                                    end;
                                DataStorageProvider::Strapi:
                                    begin
                                        StrapiManager.GetFolderMapping(Rec."Table ID", Id);
                                        SubFolder := StrapiManager.CreateFolderStructure(Id, Rec."No.");
                                        if SubFolder <> '' then
                                            Id := StrapiManager.CreateFolderStructure(Id, SubFolder);
                                        StrapiManager.CreateFolder(FolderName, Id, false);
                                    end;
                                DataStorageProvider::SharePoint:
                                    begin
                                        SharePointManager.GetFolderMapping(Rec."Table ID", Id);
                                        SubFolder := SharePointManager.CreateFolderStructure(Id, Rec."No.");
                                        if SubFolder <> '' then
                                            Id := SharePointManager.CreateFolderStructure(Id, SubFolder);
                                        SharePointManager.CreateSharePointFolder(FolderName, Id, false);
                                    end;
                            end;
                            Message(FolderCreatedSuccessfullyLbl, FolderName);
                        end;
                    end;
                end;
            }

            action(DeleteFile)
            {
                Visible = IsDrive;
                ApplicationArea = All;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Deletes the file from cloud storage.';
                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    SharePointManager: Codeunit "SharePoint Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    ConfirmMsg: Label 'Are you sure you want to delete the file "%1"?';
                begin
                    if not Confirm(ConfirmMsg, false, Rec."File Name") then
                        exit;

                    case Rec."Storage Provider" of
                        Rec."Storage Provider"::"Google Drive":
                            If not GoogleDriveManager.DeleteFile(Rec.GetDocumentID()) then
                                Message(ErrorDeletingFileLbl);
                        Rec."Storage Provider"::OneDrive:
                            If not OneDriveManager.DeleteFile(Rec.GetDocumentID()) then
                                Message(ErrorDeletingFileLbl);
                        Rec."Storage Provider"::DropBox:
                            DropBoxManager.DeleteFile(Rec.GetDocumentID());
                        Rec."Storage Provider"::Strapi:
                            StrapiManager.DeleteFile(Rec.GetDocumentID());
                        Rec."Storage Provider"::SharePoint:
                            SharePointManager.DeleteFile(Rec.GetDocumentID());
                    end;

                    // Eliminar el registro local
                    Rec.Delete();
                    Message(FileDeletedSuccessfullyLbl);
                end;
            }

            // action(UploadFile)
            // {
            //     ApplicationArea = All;
            //     Caption = 'Subir Archivo';
            //     Image = Import;
            //     ToolTip = 'Sube un archivo al almacenamiento en la nube.';
            //     trigger OnAction()
            //     var
            //         GoogleDriveManager: Codeunit "Google Drive Manager";
            //         OneDriveManager: Codeunit "OneDrive Manager";
            //         DropBoxManager: Codeunit "DropBox Manager";
            //         StrapiManager: Codeunit "Strapi Manager";
            //         FileInStream: InStream;
            //         FileName: Text;
            //         FileId: Text;
            //         TempBlob: Codeunit "Temp Blob";
            //         DocumentStream: OutStream;
            //         InStream: InStream;
            //         FileMgt: Codeunit "File Management";
            //         FileExtension: Text;
            //         FolderMapping: Record "Google Drive Folder Mapping";
            //         Folder: Text;
            //         SubFolder: Text;
            //     begin
            //         if UploadIntoStream('Seleccionar archivo', '', 'Todos los archivos (*.*)|*.*', FileName, FileInStream) then begin
            //             // Crear un nuevo registro de Document Attachment
            //             Rec.Init();
            //             Rec.InitFieldsFromRecRef(RecRef);
            //             Rec.ID := 0;
            //             Rec."File Name" := FileName;
            //             FileExtension := FileMgt.GetExtension(FileName);
            //             Rec."File Extension" := FileExtension;
            //             Rec."Store in Google Drive" := true;

            //             // Subir archivo según el proveedor configurado
            //             case Rec."Storage Provider" of
            //                 Rec."Storage Provider"::"Google Drive":
            //                     begin

            //                     FolderMapping.SetRange("Table ID", Rec."Table ID");
            //                     if FolderMapping.FindFirst() Then Folder := FolderMapping."Default Folder ID";
            //                     SubFolder := FolderMapping.CreateSubfolderPath(Rec."Table ID",Rec."No.", Date);
            //                     IF SubFolder <> '' then
            //                         Folder := GoogleDriveManager.CreateFolderStructure(Folder, SubFolder);
            //                         TempBlob.CreateOutStream(DocumentStream);
            //                         FileInStream.ReadText(FileName);
            //                         TempBlob.CreateInStream(InStream);
            //                         FileId := GoogleDriveManager.UploadFileB64('', InStream, FileName, FileExtension);
            //                         Rec."Google Drive ID" := FileId;
            //                     end;
            //                 Rec."Storage Provider"::OneDrive:
            //                     begin
            //                         TempBlob.CreateOutStream(DocumentStream);
            //                         FileInStream.ReadText(FileName);
            //                         TempBlob.CreateInStream(InStream);
            //                         FileId := OneDriveManager.UploadFileB64('', InStream, FileName);
            //                         Rec."OneDrive ID" := FileId;
            //                     end;
            //                 Rec."Storage Provider"::DropBox:
            //                     begin
            //                         TempBlob.CreateOutStream(DocumentStream);
            //                         FileInStream.ReadText(FileName);
            //                         TempBlob.CreateInStream(InStream);
            //                         FileId := DropBoxManager.UploadFileB64('', InStream, FileName);
            //                         Rec."DropBox ID" := FileId;
            //                     end;
            //                 Rec."Storage Provider"::Strapi:
            //                     begin
            //                         TempBlob.CreateOutStream(DocumentStream);
            //                         FileInStream.ReadText(FileName);
            //                         TempBlob.CreateInStream(InStream);
            //                         FileId := StrapiManager.UploadFileB64('', InStream, FileName);
            //                         Rec."Strapi ID" := FileId;
            //                     end;
            //             end;

            //             Rec.Insert();
            //             Message('Archivo "%1" subido correctamente.', FileName);
            //         end;
            //     end;
            // }
        }
    }
    var
        IsGoogle: Boolean;
        IsOndrive: Boolean;
        IsDropBox: Boolean;
        IsStrapi: Boolean;
        IsSharePoint: Boolean;
        IsDrive: Boolean;
        IsDriveExt: Boolean;

        // Labels for messages
        MoveToDriveConfirmMsg: Label 'Are you sure you want to move the selected documents to Drive? The documents will be removed from local storage.';
        DocumentsMovedSuccessMsg: Label 'Documents moved successfully to Drive.';
        ErrorMovingDocumentsMsg: Label 'Error moving documents: %1';
        DeleteFileConfirmMsg: Label 'Are you sure you want to delete the file "%1"?';
        MisisinDocActchPermision: Label 'Error: Permission to modify the Document Attachment record is missing';
    // Add triggers
    trigger OnOpenPage()
    var
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        SharePointManager: Codeunit "SharePoint Manager";
        DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
    begin
        IsGoogle := DocAttachmentMgmtGDrive.IsGoogleDrive();
        IsOndrive := DocAttachmentMgmtGDrive.IsOneDrive();
        IsDropBox := DocAttachmentMgmtGDrive.IsDropBox();
        IsStrapi := DocAttachmentMgmtGDrive.IsStrapi();
        IsSharePoint := DocAttachmentMgmtGDrive.IsSharePoint();
        IsDrive := IsGoogle or IsOndrive or IsDropBox or IsStrapi or IsSharePoint;
        IsDriveExt := DocAttachmentMgmtGDrive.FuncionalidadExtendida();
        // Initialize Google Drive Manager when the page opens
        If IsGoogle Then
            GoogleDriveManager.Initialize();
        if IsOndrive Then
            OneDriveManager.Initialize();
        if IsDropBox Then
            DropBoxManager.Initialize();
        if IsStrapi Then
            StrapiManager.Initialize();
        if IsSharePoint Then
            SharePointManager.Initialize();

        a := 1;
        if IsDrive then
            SetRecord();
    end;

    internal procedure GetRefTable(var RecRef: RecordRef; DocumentAttachment: Record "Document Attachment"): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        Employee: Record Employee;
        FixedAsset: Record "Fixed Asset";
        Resource: Record Resource;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        Job: Record Job;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VATReportHeader: Record "VAT Report Header";
        Opportunity: Record Opportunity;
        BankAccount: Record "Bank Account";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        GLAccount: Record "G/L Account";
    begin
        case DocumentAttachment."Table ID" of
            0:
                exit(false);
            Database::Customer:
                begin
                    RecRef.Open(Database::Customer);
                    if Customer.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(Customer);
                end;
            Database::Vendor:
                begin
                    RecRef.Open(Database::Vendor);
                    if Vendor.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(Vendor);
                end;
            Database::Item:
                begin
                    RecRef.Open(Database::Item);
                    if Item.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(Item);
                end;
            Database::"G/L Account":
                begin
                    RecRef.Open(Database::"G/L Account");
                    if GLAccount.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(GLAccount);
                end;
            Database::Employee:
                begin
                    RecRef.Open(Database::Employee);
                    if Employee.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(Employee);
                end;
            Database::"Fixed Asset":
                begin
                    RecRef.Open(Database::"Fixed Asset");
                    if FixedAsset.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(FixedAsset);
                end;
            Database::Resource:
                begin
                    RecRef.Open(Database::Resource);
                    if Resource.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(Resource);
                end;
            Database::"Bank Account":
                begin
                    RecRef.Open(Database::"Bank Account");
                    if BankAccount.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(BankAccount);
                end;
            Database::Job:
                begin
                    RecRef.Open(Database::Job);
                    if Job.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(Job);
                end;
            Database::"Sales Header":
                begin
                    RecRef.Open(Database::"Sales Header");
                    if SalesHeader.Get(DocumentAttachment."Document Type", DocumentAttachment."No.") then
                        RecRef.GetTable(SalesHeader);
                end;
            Database::"Sales Invoice Header":
                begin
                    RecRef.Open(Database::"Sales Invoice Header");
                    if SalesInvoiceHeader.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(SalesInvoiceHeader);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    RecRef.Open(Database::"Sales Cr.Memo Header");
                    if SalesCrMemoHeader.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(SalesCrMemoHeader);
                end;
            Database::"Sales Shipment Header":
                begin
                    RecRef.Open(Database::"Sales Shipment Header");
                    if SalesShipmentHeader.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(SalesShipmentHeader);
                end;
            Database::"Purchase Header":
                begin
                    RecRef.Open(Database::"Purchase Header");
                    if PurchaseHeader.Get(DocumentAttachment."Document Type", DocumentAttachment."No.") then
                        RecRef.GetTable(PurchaseHeader);
                end;
            Database::"Purch. Inv. Header":
                begin
                    RecRef.Open(Database::"Purch. Inv. Header");
                    if PurchInvHeader.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(PurchInvHeader);
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    RecRef.Open(Database::"Purch. Cr. Memo Hdr.");
                    if PurchCrMemoHdr.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(PurchCrMemoHdr);
                end;
            Database::"Purch. Rcpt. Header":
                begin
                    RecRef.Open(Database::"Purch. Rcpt. Header");
                    if PurchRcptHeader.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(PurchRcptHeader);
                end;
            Database::"VAT Report Header":
                begin
                    RecRef.Open(Database::"VAT Report Header");
                    if VATReportHeader.Get(DocumentAttachment."VAT Report Config. Code", DocumentAttachment."No.") then
                        RecRef.GetTable(VATReportHeader);
                end;
            Database::Opportunity:
                begin
                    RecRef.Open(Database::Opportunity);
                    if Opportunity.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(Opportunity);
                end;
        end;

        exit(RecRef.Number > 0);
    end;


    trigger OnAfterGetCurrRecord()
    var
    begin
        ActualizarRec();
    end;

    local procedure ActualizarRec()
    var
        StorageProvider: Enum "Data Storage Provider";
        URL: Text;
        UrlProvider: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        SharePointManager: Codeunit "SharePoint Manager";
        DriveType: Text;
    begin
        if not IsDrive then exit;
        if Rec."Store in Google Drive" then begin
            URL := Rec."Google Drive ID";
            UrlProvider := Url;//GoogleDriveManager.GetUrl(URL);
            StorageProvider := StorageProvider::"Google Drive";
            DriveType := 'google';
        end;
        if Rec."Store in OneDrive" then begin
            URL := Rec."OneDrive ID";
            UrlProvider := OneDriveManager.GetPdfBase64(URL);
            URL := UrlProvider;
            StorageProvider := StorageProvider::OneDrive;
            DriveType := 'onedrive';
        end;
        if Rec."Store in DropBox" then begin
            URL := Rec."DropBox ID";
            UrlProvider := Url;//DropBoxManager.GetUrl(URL);
            StorageProvider := StorageProvider::DropBox;
            DriveType := 'dropbox';
        end;
        if Rec."Store in Strapi" then begin
            URL := Rec."Strapi ID";
            UrlProvider := url;//StrapiManager.GetUrl(URL);
            StorageProvider := StorageProvider::Strapi;
            DriveType := 'strapi';
        end;
        if Rec."Store in SharePoint" then begin
            URL := Rec."SharePoint ID";
            StorageProvider := StorageProvider::SharePoint;
            DriveType := 'sharepoint';
        end;
        if URL <> '' then
            SetPDFDocumentUrl(URL, 1, (Rec."File Type" = Rec."File Type"::PDF), Rec."File Name", StorageProvider, UrlProvider, DriveType)
        else
            SetPDFDocument(GetPDFAsTxt(Rec), 1, (Rec."File Type" = Rec."File Type"::PDF), UrlProvider, DriveType);
    end;

    local procedure GetPDFAsTxt(PDFStorage: Record "Document Attachment"): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        Int: InStream;
        DocumentStream: OutStream;
    begin
        TempBlob.CreateOutStream(DocumentStream);
        PDFStorage."Document Reference ID".ExportStream(DocumentStream);
        TempBlob.CreateInStream(Int);


        exit(Base64Convert.ToBase64(Int));
    end;

    local procedure SetPDFDocument(PDFAsTxt: Text; i: Integer; Pdf: Boolean; Url: Text; driveType: Text);
    var
        IsVisible: Boolean;
    begin
        IsVisible := PDFAsTxt <> '';
        case i of
            1:
                begin
                    VisibleControl1 := IsVisible;
                    if not IsVisible or not IsControlAddInReady then
                        exit;
                    CurrPage.PDFViewer1.SetVisible(IsVisible);
                    If Pdf then
                        CurrPage.PDFViewer1.LoadPDF(PDFAsTxt, true)
                    else begin
                        case Rec."File Type" of
                            Rec."File Type"::PDF:
                                CurrPage.PDFViewer1.LoadOtros(PDFAsTxt, true, 'pdf', driveType, Url);
                            Rec."File Type"::Image:
                                CurrPage.PDFViewer1.LoadOtros(PDFAsTxt, true, 'image', '', '');
                            Rec."File Type"::Word:
                                CurrPage.PDFViewer1.LoadOtros(PDFAsTxt, true, 'word', driveType, Url);
                            Rec."File Type"::Excel:
                                CurrPage.PDFViewer1.LoadOtros(PDFAsTxt, true, 'excel', driveType, Url);
                            Rec."File Type"::PowerPoint:
                                CurrPage.PDFViewer1.LoadOtros(PDFAsTxt, true, 'powerpoint', driveType, Url);
                            Rec."File Type"::XML:
                                CurrPage.PDFViewer1.LoadOtros(PDFAsTxt, true, 'xml', driveType, Url);


                        end;
                    end;
                    CurrPage.PDFViewer1.Fichero(a);
                    CurrPage.PDFViewer1.Ficheros(Rec.Count);
                end;

        end;

    end;

    local procedure SetPDFDocumentUrl(PDFAsTxt: Text; i: Integer; Pdf: Boolean; Filename: Text; Origen: Enum "Data Storage Provider"; UrlProvider: Text; DriveType: Text);
    var
        IsVisible: Boolean;
        Base64: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        SharePointManager: Codeunit "SharePoint Manager";
    begin
        if DriveType = 'onedrive' then begin
            Base64 := PDFAsTxt;
            Pdf := true;
        end
        else
            If not Rec.ToBase64StringOcr(PDFAsTxt, Base64, Filename, Origen) then
                exit;

        IsVisible := Base64 <> '';
        case i of
            1:
                begin
                    VisibleControl1 := IsVisible;
                    if not IsVisible or not IsControlAddInReady then
                        exit;
                    CurrPage.PDFViewer1.SetVisible(IsVisible);
                    If Pdf then
                        CurrPage.PDFViewer1.LoadPDF(Base64, true)
                    else begin
                        case Rec."File Type" of
                            Rec."File Type"::PDF:
                                CurrPage.PDFViewer1.LoadOtros(Base64, true, 'pdf', DriveType, UrlProvider);
                            Rec."File Type"::Image:
                                CurrPage.PDFViewer1.LoadOtros(Base64, true, 'image', DriveType, UrlProvider);
                            Rec."File Type"::Word:
                                CurrPage.PDFViewer1.LoadOtros(Base64, true, 'word', DriveType, UrlProvider);
                            Rec."File Type"::Excel:
                                CurrPage.PDFViewer1.LoadOtros(Base64, true, 'excel', DriveType, UrlProvider);
                            Rec."File Type"::PowerPoint:
                                CurrPage.PDFViewer1.LoadOtros(Base64, true, 'powerpoint', DriveType, UrlProvider);
                            Rec."File Type"::XML:
                                CurrPage.PDFViewer1.LoadOtros(Base64, true, 'xml', DriveType, UrlProvider);

                        end;
                    end;
                    CurrPage.PDFViewer1.Fichero(a);
                    CurrPage.PDFViewer1.Ficheros(Rec.Count);


                end;
        end;
    end;

    local procedure SetRecord()
    var

        HandleErr: Boolean;
        i: Integer;
        RecRef: RecordRef;
        DocTypeS: Enum "Sales Document Type";
        FolderMapping: Record "Google Drive Folder Mapping";
        GoogleDriveManager: Codeunit "Google Drive Manager";
        Id: Text;
        SubFolder: Text;
        Path: Text;
        DocTypeD: Enum "Purchase Document Type";
        FileList: Record "Name/Value Buffer" temporary;
        Instream: InStream;
        DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
        DataStorageProvider: Enum "Data Storage Provider";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        SharePointManager: Codeunit "SharePoint Manager";
        DocumentAttachment: Record "Document Attachment";
        StorageProvider: Enum "Data Storage Provider";
        URL: Text;
        UrlProvider: Text;
        DriveType: Text;
        Date: Date;
    begin
        DocumentAttachment.CopyFilters(Rec);
        DocumentAttachment.SetRange("File Type", DocumentAttachment."File Type"::PDF);
        DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
        //Clear(PDFStorageArray);
        Clear(VisibleControl1);
        Clear(VisibleControl2);
        Clear(VisibleControl3);
        Clear(VisibleControl4);
        Clear(VisibleControl5);
        //PDFStorage.SetRange("Source Record ID", gSourceRecordId);
        //

        if not DocumentAttachment.FindFirst() then begin
            VisibleControl1 := false;
            exit;
        end;
        case DataStorageProvider of
            DataStorageProvider::"Google Drive":
                GoogleDriveManager.GetFolderMapping(DocumentAttachment."Table ID", Id);
            DataStorageProvider::OneDrive:
                OneDriveManager.GetFolderMapping(DocumentAttachment."Table ID", Id);
            DataStorageProvider::DropBox:
                DropBoxManager.GetFolderMapping(DocumentAttachment."Table ID", Id);
            DataStorageProvider::Strapi:
                StrapiManager.GetFolderMapping(DocumentAttachment."Table ID", Id);
            DataStorageProvider::SharePoint:
                SharePointManager.GetFolderMapping(DocumentAttachment."Table ID", Id);
        end;
        Date := ObtenerDate(DocumentAttachment);

        SubFolder := ObtenerSubfolder(DocumentAttachment."Table ID", DocumentAttachment."No.", Date, SubFolder, Path);
        IF SubFolder <> '' then begin
            case DataStorageProvider of
                DataStorageProvider::"Google Drive":
                    begin
                        Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
                        GoogleDriveManager.ListFolder(Id, FileList, true);
                        DriveType := 'google';
                    end;
                DataStorageProvider::OneDrive:
                    begin
                        IF SubFolder <> '' then begin
                            Id := OneDriveManager.CreateFolderStructure(Id, SubFolder);
                            Path += SubFolder + '/'
                        end;
                        OneDriveManager.ListFolder(Id, FileList, true);
                        DriveType := 'onedrive';
                    end;
                DataStorageProvider::DropBox:
                    begin
                        Id := DropBoxManager.CreateSubfolderStructure(Id, SubFolder);
                        DropBoxManager.ListFolder(Id, FileList, true);
                        DriveType := 'dropbox';
                    end;
                DataStorageProvider::Strapi:
                    begin
                        Id := StrapiManager.CreateSubfolderStructure(Id, SubFolder);
                        StrapiManager.ListFolder(Id, FileList, true);
                        DriveType := 'strapi';
                    end;
                DataStorageProvider::SharePoint:
                    begin
                        Id := SharePointManager.CreateFolderStructure(Id, SubFolder);
                        SharePointManager.ListFolder(Id, FileList, true);
                        DriveType := 'sharepoint';
                    end;
            end;
        end;


        FileList.SetFilter("Name", '*.pdf');
        VisibleControl1 := false;
        if Rec.FindSet() then VisibleControl1 := true;
        // a := 0;
        // If PDFStorageT.FindLast() then a := PDFStorageT.id;
        // Case gSourceRecordId.TableNo of
        //     36, 38:
        //         Begin
        //             if FileList.FindFirst() then
        //                 repeat
        //                     PDFStorageT.init;
        //                     a += 1;
        //                     PDFStorageT.id := a;
        //                     PDFStorageT."Table ID" := gSourceRecordId.TableNo;
        //                     PDFStorageT."No." := RecRef.Field(3).Value;
        //                     PDFStorageT."Document Type" := RecRef.Field(1).Value;
        //                     PDFStorageT."Google Drive ID" := FileList."Google Drive ID";
        //                     PDFStorageT."File Type" := PDFStorageT."File Type"::PDF;
        //                     PDFStorageT."File Name" := FileList."Name";
        //                     PDFStorageT."Store in Google Drive" := True;
        //                     VisibleControl1 := true;
        //                     If PDFStorageT.Insert() Then;

        //                 until FileList.Next() = 0;
        //         end;
        //     Database::Customer, Database::Vendor, Database::Item, Database::"G/L Account", Database::"Fixed Asset", Database::Employee, Database::Job, Database::Resource:
        //         begin
        //             if FileList.FindFirst() then
        //                 repeat
        //                     PDFStorageT.init;
        //                     a += 1;
        //                     PDFStorageT.id := a;
        //                     PDFStorageT."Table ID" := gSourceRecordId.TableNo;
        //                     PDFStorageT."No." := RecRef.Field(1).Value;
        //                     PDFStorageT."Google Drive ID" := FileList."Google Drive ID";
        //                     PDFStorageT."File Type" := PDFStorageT."File Type"::PDF;
        //                     PDFStorageT."File Name" := FileList."Name";
        //                     PDFStorageT."Store in Google Drive" := True;
        //                     VisibleControl1 := true;
        //                     If PDFStorageT.Insert() Then;
        //                 until FileList.Next() = 0;
        //         end;
        //     112, 114, 122, 144:
        //         begin
        //             if FileList.FindFirst() then
        //                 repeat
        //                     PDFStorageT.init;
        //                     a += 1;
        //                     PDFStorageT.id := a;
        //                     PDFStorageT."Table ID" := gSourceRecordId.TableNo;
        //                     PDFStorageT."No." := RecRef.Field(3).Value;
        //                     PDFStorageT."Google Drive ID" := FileList."Google Drive ID";
        //                     PDFStorageT."File Type" := PDFStorageT."File Type"::PDF;
        //                     PDFStorageT."File Name" := FileList."Name";
        //                     PDFStorageT."Store in Google Drive" := True;
        //                     VisibleControl1 := true;
        //                     If PDFStorageT.Insert() Then;
        //                 until FileList.Next() = 0;
        //         end;
        // end;
        // commit;
        if Rec.FindFirst() then
            if IsControlAddInReady then BEGIN
                if Rec."Store in Google Drive" then begin
                    URL := Rec."Google Drive ID";
                    UrlProvider := GoogleDriveManager.GetUrl(URL);
                    StorageProvider := StorageProvider::"Google Drive";
                end;
                if Rec."Store in OneDrive" then begin
                    URL := Rec."OneDrive ID";
                    UrlProvider := OneDriveManager.GetUrl(URL);
                    StorageProvider := StorageProvider::OneDrive;
                end;
                if Rec."Store in DropBox" then begin
                    URL := Rec."DropBox ID";
                    UrlProvider := DropBoxManager.GetUrl(URL);
                    StorageProvider := StorageProvider::DropBox;
                end;
                if Rec."Store in Strapi" then begin
                    URL := Rec."Strapi ID";
                    UrlProvider := StrapiManager.GetUrl(URL);
                    StorageProvider := StorageProvider::Strapi;
                end;
                if Rec."Store in SharePoint" then begin
                    URL := Rec."SharePoint ID";
                    StorageProvider := StorageProvider::SharePoint;
                    DriveType := 'sharepoint';
                end;

                UrlProvider := Url;

                if Url <> '' then
                    SetPDFDocumentUrl(Url, 1, (Rec."File Type" = Rec."File Type"::PDF), Rec."File Name", StorageProvider, UrlProvider, DriveType)
                else
                    SetPDFDocument(GetPDFAsTxt(Rec), 1, (Rec."File Type" = Rec."File Type"::PDF), UrlProvider, DriveType);
            end;
        // SetPDFDocument(GetPDFAsTxt(PDFStorageArray[1]), 1);
        // SetPDFDocument(GetPDFAsTxt(PDFStorageArray[2]), 2);
        // SetPDFDocument(GetPDFAsTxt(PDFStorageArray[3]), 3);
        // SetPDFDocument(GetPDFAsTxt(PDFStorageArray[4]), 4);
        // SetPDFDocument(GetPDFAsTxt(PDFStorageArray[5]), 5);
    end;




    local procedure RunFullView(PDFStorage: Record "Document Attachment")
    var
        PDFViewerCard: Page "PDF Viewer";
        tempblob: Codeunit "Temp Blob";
        DocumentStream: OutStream;
        Base64: Text;
        Base64Convert: Codeunit "Base64 Convert";
        Int: InStream;
        StorageProvider: Enum "Data Storage Provider";
        URL: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        SharePointManager: Codeunit "SharePoint Manager";
    begin
        if PDFStorage."Store in Google Drive" then begin
            URL := PDFStorage."Google Drive ID";
            StorageProvider := StorageProvider::"Google Drive";
        end;
        if PDFStorage."Store in OneDrive" then begin
            URL := PDFStorage."OneDrive ID";
            StorageProvider := StorageProvider::OneDrive;
        end;
        if PDFStorage."Store in DropBox" then begin
            URL := PDFStorage."DropBox ID";
            StorageProvider := StorageProvider::DropBox;
        end;
        if PDFStorage."Store in Strapi" then begin
            URL := PDFStorage."Strapi ID";
            StorageProvider := StorageProvider::Strapi;
        end;
        if PDFStorage."Store in SharePoint" then begin
            URL := PDFStorage."SharePoint ID";
            StorageProvider := StorageProvider::SharePoint;

        end;
        if PDFStorage."File Extension" <> 'pdf' then begin
            Case StorageProvider of
                StorageProvider::"Google Drive":
                    begin
                        GoogleDriveManager.OpenFileInBrowser(PDFStorage."Google Drive ID");
                    end;
                StorageProvider::OneDrive:
                    begin
                        OneDriveManager.OpenFileInBrowser(PDFStorage."OneDrive ID", false);
                    end;
                StorageProvider::DropBox:
                    begin
                        DropBoxManager.OpenFileInBrowser(PDFStorage."DropBox ID");
                    end;
                StorageProvider::Strapi:
                    begin
                        StrapiManager.OpenFileInBrowser(PDFStorage."Strapi ID");
                    end;
                StorageProvider::SharePoint:
                    begin
                        SharePointManager.OpenFileInBrowser(PDFStorage."SharePoint ID", false);
                    end;
            end;
            exit;
        end;
        if URL <> '' then begin
            If Not PDFStorage.ToBase64StringOcr(URL, Base64, PDFStorage."File Name", StorageProvider) then
                exit;
            PDFViewerCard.LoadPdfFromBlob(Base64);
        end
        else begin
            if PDFStorage.IsEmpty() then
                exit;

            TempBlob.CreateOutStream(DocumentStream);
            PDFStorage."Document Reference ID".ExportStream(DocumentStream);
            TempBlob.CreateInStream(Int);
            PDFViewerCard.LoadPdfFromBlob(Base64Convert.ToBase64(Int));
        end;
        PDFViewerCard.Run();

    end;

    local procedure ObtenerSubfolder(TableNo: Integer; Value: Variant; Date: Date; var SubFolder: Text; var Path: Text): Text
    var
        FolderMapping: Record "Google Drive Folder Mapping";
        DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
        DataStorageProvider: Enum "Data Storage Provider";
        Id: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        SharePointManager: Codeunit "SharePoint Manager";
    begin
        DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
        case DataStorageProvider of
            DataStorageProvider::"Google Drive":
                SubFolder := FolderMapping.CreateSubfolderPath(TableNo, Value, Date, DataStorageProvider);
            DataStorageProvider::OneDrive:
                begin
                    SubFolder := OneDriveManager.CreateFolderStructure(Id, SubFolder);
                    FolderMapping.SetRange("Table ID", TableNo);
                    if FolderMapping.FindFirst() Then Path += FolderMapping."Default Folder Name" + '/';
                    SubFolder := FolderMapping.CreateSubfolderPath(TableNo, Value, Date, DataStorageProvider);
                end;
            DataStorageProvider::DropBox:
                SubFolder := FolderMapping.CreateSubfolderPath(TableNo, Value, Date, DataStorageProvider);
            DataStorageProvider::Strapi:
                SubFolder := FolderMapping.CreateSubfolderPath(TableNo, Value, Date, DataStorageProvider);
            DataStorageProvider::SharePoint:
                SubFolder := FolderMapping.CreateSubfolderPath(TableNo, Value, Date, DataStorageProvider);
        end;
        exit(SubFolder);
    end;

    local procedure ObtenerDate(DocumentAttachment: Record "Document Attachment"): Date
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        case DocumentAttachment."Table ID" of
            Database::"Sales Header":
                begin
                    if SalesHeader.Get(DocumentAttachment."Document Type", DocumentAttachment."No.") then
                        exit(SalesHeader."Document Date");
                end;
            Database::"Sales Invoice Header":
                begin
                    if SalesInvoiceHeader.Get(DocumentAttachment."No.") then
                        exit(SalesInvoiceHeader."Document Date");
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    if SalesCrMemoHeader.Get(DocumentAttachment."No.") then
                        exit(SalesCrMemoHeader."Document Date");
                end;
            Database::"Purchase Header":
                begin
                    if PurchaseHeader.Get(DocumentAttachment."Document Type", DocumentAttachment."No.") then
                        exit(PurchaseHeader."Document Date");
                end;
            Database::"Purch. Inv. Header":
                begin
                    if PurchaseInvoiceHeader.Get(DocumentAttachment."No.") then
                        exit(PurchaseInvoiceHeader."Document Date");
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    if PurchaseCrMemoHeader.Get(DocumentAttachment."No.") then
                        exit(PurchaseCrMemoHeader."Document Date");
                end;
            Database::"Purch. Rcpt. Header":
                begin
                    if PurchRcptHeader.Get(DocumentAttachment."No.") then
                        exit(PurchRcptHeader."Document Date");
                end;
            Database::"Sales Shipment Header":
                begin
                    if SalesShipmentHeader.Get(DocumentAttachment."No.") then
                        exit(SalesShipmentHeader."Document Date");
                end;
        end;
        exit(0D);
    end;

    var
        //PDFStorageArray: array[5] of Record "Document Attachment";

        VisibleControl1: Boolean;

        VisibleControl2: Boolean;

        VisibleControl3: Boolean;

        VisibleControl4: Boolean;

        VisibleControl5: Boolean;
        //PDFStorageT: Record "Document Attachment" temporary;

        IsControlAddInReady: Boolean;
        l: Integer;
        a: Integer;
        // Labels for messages
        NoDestinationSelectedLbl: Label 'No destination selected';
        FolderCreatedSuccessfullyLbl: Label 'Folder "%1" created successfully.';
        ErrorDeletingFileLbl: Label 'Error deleting file.';
        FileDeletedSuccessfullyLbl: Label 'File deleted successfully.';
}