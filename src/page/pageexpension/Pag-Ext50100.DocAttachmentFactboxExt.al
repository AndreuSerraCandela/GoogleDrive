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
                Editable = true;
            }
            field("Google Drive ID"; Rec."Google Drive ID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the ID of the file in Google Drive.';
                Caption = 'Google Drive ID';
                Editable = false;
                Visible = Rec."Store in Google Drive";

                trigger OnDrillDown()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                begin
                    GoogleDriveManager.OpenFileInBrowser(Rec."Google Drive ID");
                end;
            }
        }
    }

    actions
    {
        addafter(AttachmentsUpload)
        {
            action(UploadToGoogleDrive)
            {
                ApplicationArea = All;
                Caption = 'Cargar archivo desde Google Drive';
                Image = FileContract;
                trigger OnAction()
                var
                    DocumentAttachment: Record "Document Attachment";
                    DocAttachmentGrDriveMgmt: Codeunit "Doc. Attachment Mgmt. GDrive";
                    DocumentMgmt: Codeunit "Document Attachment Mgmt";
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    RecRef: RecordRef;
                    IdTable: Integer;
                    IdTableFilter: Text;
                    No: Text;
                    Files: Record "Name/Value Buffer" temporary;
                    TargetFolderId: Text;
                    FilesSelected: Page "Google Drive List";
                    Id: Integer;
                begin
                    IdTable := Rec."Table ID";
                    if IdTable = 0 then
                        IdTableFilter := Rec.GetFilter("Table ID");
                    if IdTable = 0 then
                        Evaluate(IdTable, IdTableFilter);
                    No := Rec."No.";
                    TargetFolderId := GoogleDriveManager.GetTargetFolderForDocument(IdTable, No, 0D);
                    GoogleDriveManager.Carpetas(TargetFolderId, Files);
                    CurrPage.Update();
                    FilesSelected.SetRecords(TargetFolderId, Files);
                    If FilesSelected.RunModal() = Action::OK then begin
                        FilesSelected.SetSelectionFilter(Files);
                        GetRefTable(RecRef, Rec);
                        if Files.FindSet() then
                            repeat
                                Rec.Init();
                                Rec.ID := 0;
                                Rec.InitFieldsFromRecRef(RecRef);
                                Rec."Store in Google Drive" := true;
                                Rec."Google Drive ID" := Files."Google Drive ID";
                                Rec."File Name" := Files.Name;
                                DocAttachmentGrDriveMgmt.SetDocumentAttachmentFileType(Rec, '');
                                Rec.Insert(true);
                            until Files.Next() = 0;
                    end;
                end;
            }
            action(MoveToGoogleDrive)
            {
                ApplicationArea = All;
                Caption = 'Mover a Google Drive';
                Image = SendTo;
                ToolTip = 'Mueve los documentos seleccionados a Google Drive y los elimina del almacenamiento local.';
                trigger OnAction()
                var
                    DocumentAttachment: Record "Document Attachment";
                    DocumentAttachment2: Record "Document Attachment" temporary;
                    TempBlob: Codeunit "Temp Blob";
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    FileId: Text;
                    ConfirmMsg: Label '¿Está seguro de que desea mover los documentos seleccionados a Google Drive? Los documentos se eliminarán del almacenamiento local.';
                    SuccessMsg: Label 'Documentos movidos correctamente a Google Drive.';
                    ErrorMsg: Label 'Error al mover los documentos: %1';
                    FullFileName: Text;
                    DocumentStream: OutStream;
                    GoogleDriveFolderMapping: Record "Google Drive Folder Mapping";
                    GoogleDrive: Codeunit "Google Drive Manager";
                    Id: Text;
                    SubFolder: Text;
                    InStream: InStream;
                    TenantMedia: Record "Tenant Media";
                begin
                    if not Confirm(ConfirmMsg) then
                        exit;

                    DocumentAttachment.CopyFilters(Rec);
                    if DocumentAttachment.FindSet() then
                        repeat
                            if not DocumentAttachment."Store in Google Drive" then begin
                                FullFileName := DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension";
                                Clear(DocumentStream);
                                TempBlob.CreateOutStream(DocumentStream);
                                GoogleDrive.GetFolderMapping(DocumentAttachment."Table ID", Id);
                                SubFolder := GoogleDrive.CreateFolderStructure(Id, DocumentAttachment."No.");
                                if SubFolder <> '' then
                                    Id := GoogleDrive.CreateFolderStructure(Id, SubFolder);
                                DocumentAttachment."Document Reference ID".ExportStream(DocumentStream);
                                TempBlob.CreateInStream(InStream);
                                FileId := GoogleDriveManager.UploadFileB64(Id, InStream, DocumentAttachment."File Name", DocumentAttachment."File Extension");
                                if FileId = '' then
                                    Message(ErrorMsg, DocumentAttachment."File Name")
                                else begin
                                    DocumentAttachment."Store in Google Drive" := true;
                                    DocumentAttachment."Google Drive ID" := FileId;
                                    DocumentAttachment2.ID := DocumentAttachment.ID;
                                    DocumentAttachment2."Table ID" := DocumentAttachment."Table ID";
                                    DocumentAttachment2."No." := DocumentAttachment."No.";
                                    DocumentAttachment2."Attached By" := DocumentAttachment."Attached By";
                                    DocumentAttachment2."File Name" := DocumentAttachment."File Name";
                                    DocumentAttachment2."File Extension" := DocumentAttachment."File Extension";
                                    DocumentAttachment2."Attached Date" := DocumentAttachment."Attached Date";
                                    DocumentAttachment2."File Type" := DocumentAttachment."File Type";
                                    DocumentAttachment2."Document Flow Production" := DocumentAttachment."Document Flow Production";
                                    DocumentAttachment2."Document Flow Purchase" := DocumentAttachment."Document Flow Purchase";
                                    DocumentAttachment2."Document Flow Sales" := DocumentAttachment."Document Flow Sales";
                                    DocumentAttachment2."Document Type" := DocumentAttachment."Document Type";
                                    DocumentAttachment2."Google Drive ID" := FileId;
                                    DocumentAttachment2."Line No." := DocumentAttachment."Line No.";
                                    DocumentAttachment2."Store in Google Drive" := true;
                                    DocumentAttachment2.User := DocumentAttachment.User;
                                    DocumentAttachment.Delete(true);
                                    DocumentAttachment.Insert();
                                end;
                            end;
                        until DocumentAttachment.Next() = 0;

                    Message(SuccessMsg);
                    CurrPage.Update();
                end;
            }
        }
    }

    // Add triggers
    trigger OnOpenPage()
    var
        GoogleDriveManager: Codeunit "Google Drive Manager";
    begin
        // Initialize Google Drive Manager when the page opens
        GoogleDriveManager.Initialize();
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
}