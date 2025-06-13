pageextension 50100 "Doc. Attachment Factbox Ext" extends "Doc. Attachment List Factbox"
{
    layout
    {
        addlast(Content)
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
            //Cargar archivo a Google Drive
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