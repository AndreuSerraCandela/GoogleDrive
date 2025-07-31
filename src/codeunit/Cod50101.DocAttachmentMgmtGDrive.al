codeunit 95101 "Doc. Attachment Mgmt. GDrive"
{
    // This codeunit overrides the standard Document Attachment Management functionality
    // to use Google Drive instead of storing files in the tenant media
    permissions = tabledata "Company Information" = RIMD,
                  tabledata "Document Attachment" = RIMD,
                  tabledata "Google Drive Folder Mapping" = RIMD;

    var
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        SharePointManager: Codeunit "SharePoint Manager";
        CompanyInfo: Record "Company Information";
        MisisinDocActchPermision: Label 'Error: Permission to modify the Document Attachment record is missing';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", OnAfterTableHasNumberFieldPrimaryKey, '', false, false)]
    local procedure OnAfterTableHasNumberFieldPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    begin
        Case TableNo of
            Database::"Bank Account",
            Database::"G/L Account":
                begin
                    FieldNo := 1;
                    Result := true;
                end;
            Database::"Sales Shipment Header",
            Database::"Purch. Rcpt. Header":
                begin
                    FieldNo := 3;
                    Result := true;
                end;
        end;
    end;



    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnInsertAttachmentOnBeforeImportStream, '', false, false)]
    local procedure OnInsertAttachmentOnBeforeImportStream(var DocumentAttachment: Record "Document Attachment"; DocInStream: InStream; FileName: Text; var IsHandled: Boolean)
    var
        FolderMapping: Record "Google Drive Folder Mapping";
        Folder: Text;
        SubFolder: Text;
        Path: Text;
        Fecha: Date;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PurcchaseRcptHeader: Record "Purch. Rcpt. Header";

    begin
        Fecha := 0D;
        case DocumentAttachment."Table ID" of
            Database::"Sales Header":
                begin
                    If SalesHeader.Get(DocumentAttachment."Document Type", DocumentAttachment."No.") then
                        Fecha := SalesHeader."Document Date";
                end;
            Database::"Sales Invoice Header":
                begin
                    If SalesInvoiceHeader.Get(DocumentAttachment."No.") then
                        Fecha := SalesInvoiceHeader."Document Date";
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    If SalesCrMemoHeader.Get(DocumentAttachment."No.") then
                        Fecha := SalesCrMemoHeader."Document Date";
                end;
            Database::"Purchase Header":
                begin
                    If PurchaseHeader.Get(DocumentAttachment."Document Type", DocumentAttachment."No.") then
                        Fecha := PurchaseHeader."Document Date";
                end;
            Database::"Purch. Inv. Header":
                begin
                    If PurchaseInvoiceHeader.Get(DocumentAttachment."No.") then
                        Fecha := PurchaseInvoiceHeader."Document Date";
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    If PurchaseCrMemoHeader.Get(DocumentAttachment."No.") then
                        Fecha := PurchaseCrMemoHeader."Document Date";
                end;
            Database::"Purch. Rcpt. Header":
                begin
                    If PurcchaseRcptHeader.Get(DocumentAttachment."No.") then
                        Fecha := PurcchaseRcptHeader."Document Date";
                end;
            Database::"Sales Shipment Header":
                begin
                    If SalesShipmentHeader.Get(DocumentAttachment."No.") then
                        Fecha := SalesShipmentHeader."Document Date";
                end;

        end;
        CompanyInfo.Get();
        if CompanyInfo."Data Storage Provider" = CompanyInfo."Data Storage Provider"::Local then exit;
        case CompanyInfo."Data Storage Provider" of
            CompanyInfo."Data Storage Provider"::"Google Drive":
                begin
                    DocumentAttachment."Store in Google Drive" := true;
                    FolderMapping.SetRange("Table ID", DocumentAttachment."Table ID");
                    if FolderMapping.FindFirst() Then Folder := FolderMapping."Default Folder ID";
                    SubFolder := FolderMapping.CreateSubfolderPath(DocumentAttachment."Table ID", DocumentAttachment."No.", Fecha, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then
                        Folder := GoogleDriveManager.CreateFolderStructure(Folder, SubFolder);
                    DocumentAttachment."Google Drive ID" := GoogleDriveManager.UploadFileB64(Folder, DocInStream, DocumentAttachment."File Name", DocumentAttachment."File Extension");
                end;
            CompanyInfo.
            "Data Storage Provider"::OneDrive:
                begin
                    Path := CompanyInfo."Root Folder" + '/';
                    DocumentAttachment."Store in OneDrive" := true;
                    FolderMapping.SetRange("Table ID", DocumentAttachment."Table ID");
                    if FolderMapping.FindFirst() Then begin
                        Folder := FolderMapping."Default Folder Id";
                        Path += FolderMapping."Default Folder Name" + '/';
                    end;
                    ;
                    SubFolder := FolderMapping.CreateSubfolderPath(DocumentAttachment."Table ID", DocumentAttachment."No.", Fecha, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then begin
                        Folder := OneDriveManager.CreateFolderStructure(Folder, SubFolder);
                        Path += SubFolder + '/'
                    end;
                    DocumentAttachment."OneDrive ID" := OneDriveManager.UploadFileB64(Path, DocInStream, DocumentAttachment."File Name", DocumentAttachment."File Extension");
                end;
            CompanyInfo."Data Storage Provider"::DropBox:
                begin
                    DocumentAttachment."Store in DropBox" := true;
                    FolderMapping.SetRange("Table ID", DocumentAttachment."Table ID");
                    if FolderMapping.FindFirst() Then Folder := FolderMapping."Default Folder ID";
                    SubFolder := FolderMapping.CreateSubfolderPath(DocumentAttachment."Table ID", DocumentAttachment."No.", Fecha, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then
                        Folder := DropBoxManager.CreateFolderStructure(Folder, SubFolder);
                    DocumentAttachment."DropBox ID" := DropBoxManager.UploadFileB64(Folder, DocInStream, DocumentAttachment."File Name");
                end;
            CompanyInfo."Data Storage Provider"::Strapi:
                begin
                    DocumentAttachment."Store in Strapi" := true;
                    DocumentAttachment."Strapi ID" := StrapiManager.UploadFileB64(Folder, DocInStream, DocumentAttachment."File Name");
                end;
        end;
        IsHandled := true;

    end;

    [EventSubscriber(ObjectType::Codeunit, 80, OnRunOnBeforeFinalizePosting, '', false, false)]
    local procedure OnRunOnBeforeFinalizePosting(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CommitIsSuppressed: Boolean; GenJnlLineExtDocNo: Code[35]; var EverythingInvoiced: Boolean; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PreviewMode: Boolean)
    var
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachment2: Record "Document Attachment";
        FolderMappingSH: Record "Google Drive Folder Mapping";
        FolderMappingSalesInv: Record "Google Drive Folder Mapping";
        FolderMappingSalesCrMemo: Record "Google Drive Folder Mapping";
        FolderMappingSalesShipment: Record "Google Drive Folder Mapping";
        RecRef: RecordRef;
    begin
        CompanyInfo.Get();
        RecRef.GetTable(SalesHeader);
        If not FolderMappingSH.Get(Database::"Sales Header") then
            FolderMappingSH.init;
        if not FolderMappingSalesInv.Get(Database::"Sales Invoice Header") then
            FolderMappingSalesInv.init;
        if not FolderMappingSalesCrMemo.Get(Database::"Sales Cr.Memo Header") then
            FolderMappingSalesCrMemo.init;
        if not FolderMappingSalesShipment.Get(Database::"Sales Shipment Header") then
            FolderMappingSalesShipment.init;
        If (SalesInvoiceHeader."No." <> '') Or (SalesCrMemoHeader."No." <> '') then begin
            DocumentAttachment.SetRange("Table ID", Database::"Sales Header");
            DocumentAttachment.SetRange("No.", SalesHeader."No.");
            DocumentAttachment.SetRange("Document Type", SalesHeader."Document Type");
            DocumentAttachment.SetRange("Posted Document", false);
            if not DocumentAttachment.WritePermission() then Error(MisisinDocActchPermision);
            DocumentAttachment.ModifyAll("Posted Document", true);
        end;
        if (SalesInvoiceHeader."No." <> '') then begin
            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Sales Invoice Header");
            DocumentAttachment.SetRange("No.", SalesInvoiceHeader."No.");
            if DocumentAttachment.FindFirst() then
                repeat
                    FolderMappingSH.MoveFileH(CompanyInfo."Data Storage Provider", DocumentAttachment, Database::"Sales Header", Database::"Sales Invoice Header", RecRef, SalesHeader."Document Date", SalesInvoiceHeader."Document Date", SalesHeader."No.", SalesInvoiceHeader."No.");
                until DocumentAttachment.Next() = 0;
        end;
        if (SalesCrMemoHeader."No." <> '') then begin
            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Sales Cr.Memo Header");
            DocumentAttachment.SetRange("No.", SalesCrMemoHeader."No.");
            if DocumentAttachment.FindFirst() then
                repeat
                    FolderMappingSH.MoveFileH(CompanyInfo."Data Storage Provider", DocumentAttachment, Database::"Sales Header", Database::"Sales Cr.Memo Header", RecRef, SalesHeader."Document Date", SalesCrMemoHeader."Document Date", SalesHeader."No.", SalesCrMemoHeader."No.");
                until DocumentAttachment.Next() = 0;
        end;
        if (SalesShipmentHeader."No." <> '') then begin
            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Sales Shipment Header");
            DocumentAttachment.SetRange("No.", SalesShipmentHeader."No.");
            if not DocumentAttachment.FindFirst() then begin
                DocumentAttachment.SetRange("Table ID", Database::"Sales Header");
                DocumentAttachment.SetRange("No.", SalesHeader."No.");
                DocumentAttachment.SetRange("Document Type", SalesHeader."Document Type");
                if DocumentAttachment.FindFirst() then
                    repeat
                        DocumentAttachment2 := DocumentAttachment;
                        DocumentAttachment2."Table ID" := Database::"Sales Shipment Header";
                        DocumentAttachment2."No." := SalesShipmentHeader."No.";
                        DocumentAttachment2."Document Type" := 0;
                        if not DocumentAttachment2.WritePermission() then Error(MisisinDocActchPermision);
                        DocumentAttachment2.Insert();

                    until DocumentAttachment.Next() = 0;
            end;
            if DocumentAttachment.FindFirst() then
                repeat
                    FolderMappingSH.MoveFileH(CompanyInfo."Data Storage Provider", DocumentAttachment, Database::"Sales Header", Database::"Sales Shipment Header", RecRef, SalesHeader."Document Date", SalesShipmentHeader."Document Date", SalesHeader."No.", SalesShipmentHeader."No.");
                until DocumentAttachment.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, OnBeforeDeleteAfterPosting, '', false, false)]
    local procedure OnBeforeDeleteAfterPosting(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SkipDelete: Boolean; CommitIsSuppressed: Boolean; EverythingInvoiced: Boolean; var TempSalesLineGlobal: Record "Sales Line" temporary)
    var
        DocumentAttachment: Record "Document Attachment";
        FolderMappingSH: Record "Google Drive Folder Mapping";
        FolderMappingSalesInv: Record "Google Drive Folder Mapping";
        FolderMappingSalesCrMemo: Record "Google Drive Folder Mapping";
        RecRef: RecordRef;
    begin
        CompanyInfo.Get();
        RecRef.GetTable(SalesHeader);
        If not FolderMappingSH.Get(Database::"Sales Header") then
            exit;
        if not FolderMappingSalesInv.Get(Database::"Sales Invoice Header") then
            exit;
        if not FolderMappingSalesCrMemo.Get(Database::"Sales Cr.Memo Header") then
            exit;

        If (SalesInvoiceHeader."No." <> '') Or (SalesCrMemoHeader."No." <> '') then begin
            DocumentAttachment.SetRange("Table ID", Database::"Sales Header");
            DocumentAttachment.SetRange("No.", SalesHeader."No.");
            DocumentAttachment.SetRange("Document Type", SalesHeader."Document Type");
            DocumentAttachment.SetRange("Posted Document", false);
            if not DocumentAttachment.WritePermission() then Error(MisisinDocActchPermision);
            DocumentAttachment.ModifyAll("Posted Document", true);
        end;
        if (SalesInvoiceHeader."No." <> '') then begin
            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Sales Invoice Header");
            DocumentAttachment.SetRange("No.", SalesInvoiceHeader."No.");
            if DocumentAttachment.FindFirst() then
                repeat
                    FolderMappingSH.MoveFileH(CompanyInfo."Data Storage Provider", DocumentAttachment, Database::"Sales Header", Database::"Sales Invoice Header", RecRef, SalesHeader."Document Date", SalesInvoiceHeader."Document Date", SalesHeader."No.", SalesInvoiceHeader."No.");
                until DocumentAttachment.Next() = 0;
        end;
        if (SalesCrMemoHeader."No." <> '') then begin
            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Sales Cr.Memo Header");
            DocumentAttachment.SetRange("No.", SalesCrMemoHeader."No.");
            if DocumentAttachment.FindFirst() then
                repeat
                    FolderMappingSH.MoveFileH(CompanyInfo."Data Storage Provider", DocumentAttachment, Database::"Sales Header", Database::"Sales Cr.Memo Header", RecRef, SalesHeader."Document Date", SalesCrMemoHeader."Document Date", SalesHeader."No.", SalesCrMemoHeader."No.");
                until DocumentAttachment.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 90, OnRunOnBeforeFinalizePosting, '', false, false)]
    local procedure OnRunOnBeforeFinalizePosting2(var PurchaseHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ReturnShipmentHeader: Record "Return Shipment Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CommitIsSuppressed: Boolean)
    var
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachment2: Record "Document Attachment";
        FolderMappingSH: Record "Google Drive Folder Mapping";
        FolderMappingSalesInv: Record "Google Drive Folder Mapping";
        FolderMappingSalesCrMemo: Record "Google Drive Folder Mapping";
        FolderMappingSalesShipment: Record "Google Drive Folder Mapping";
        RecRef: RecordRef;
    begin
        CompanyInfo.Get();
        RecRef.GetTable(PurchaseHeader);
        If not FolderMappingSH.Get(Database::"Purchase Header") then
            FolderMappingSH.init;
        if not FolderMappingSalesInv.Get(Database::"Purch. Inv. Header") then
            FolderMappingSalesInv.init;
        if not FolderMappingSalesCrMemo.Get(Database::"Purch. Cr. Memo Hdr.") then
            FolderMappingSalesCrMemo.init;
        if not FolderMappingSalesShipment.Get(Database::"Purch. Rcpt. Header") then
            FolderMappingSalesShipment.init;
        If (PurchInvHeader."No." <> '') Or (PurchCrMemoHdr."No." <> '') then begin
            DocumentAttachment.SetRange("Table ID", Database::"Purchase Header");
            DocumentAttachment.SetRange("No.", PurchaseHeader."No.");
            DocumentAttachment.SetRange("Document Type", PurchaseHeader."Document Type");
            DocumentAttachment.SetRange("Posted Document", false);
            if not DocumentAttachment.WritePermission() then Error(MisisinDocActchPermision);
            DocumentAttachment.ModifyAll("Posted Document", true);
        end;
        if (PurchInvHeader."No." <> '') then begin
            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Purch. Inv. Header");
            DocumentAttachment.SetRange("No.", PurchInvHeader."No.");
            if DocumentAttachment.FindFirst() then
                repeat
                    FolderMappingSH.MoveFileH(CompanyInfo."Data Storage Provider", DocumentAttachment, Database::"Purchase Header", Database::"Purch. Inv. Header", RecRef, PurchaseHeader."Document Date", PurchInvHeader."Document Date", PurchaseHeader."No.", PurchInvHeader."No.");
                until DocumentAttachment.Next() = 0;
        end;
        if (PurchCrMemoHdr."No." <> '') then begin
            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Purch. Cr. Memo Hdr.");
            DocumentAttachment.SetRange("No.", PurchCrMemoHdr."No.");
            if DocumentAttachment.FindFirst() then
                repeat
                    FolderMappingSH.MoveFileH(CompanyInfo."Data Storage Provider", DocumentAttachment, Database::"Purchase Header", Database::"Purch. Cr. Memo Hdr.", RecRef, PurchaseHeader."Document Date", PurchCrMemoHdr."Document Date", PurchaseHeader."No.", PurchCrMemoHdr."No.");
                until DocumentAttachment.Next() = 0;
        end;
        if (PurchRcptHeader."No." <> '') then begin
            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Purch. Rcpt. Header");
            DocumentAttachment.SetRange("No.", PurchRcptHeader."No.");
            if not DocumentAttachment.FindFirst() then begin
                DocumentAttachment.SetRange("Table ID", Database::"Purchase Header");
                DocumentAttachment.SetRange("No.", PurchaseHeader."No.");
                DocumentAttachment.SetRange("Document Type", PurchaseHeader."Document Type");
                if DocumentAttachment.FindFirst() then
                    repeat
                        DocumentAttachment2 := DocumentAttachment;
                        DocumentAttachment2."Table ID" := Database::"Purch. Rcpt. Header";
                        DocumentAttachment2."No." := PurchRcptHeader."No.";
                        DocumentAttachment2."Document Type" := 0;
                        if not DocumentAttachment2.WritePermission() then Error(MisisinDocActchPermision);
                        DocumentAttachment2.Insert();

                    until DocumentAttachment.Next() = 0;
            end;
            if DocumentAttachment.FindFirst() then
                repeat
                    FolderMappingSH.MoveFileH(CompanyInfo."Data Storage Provider", DocumentAttachment, Database::"Purchase Header", Database::"Purch. Rcpt. Header", RecRef, PurchaseHeader."Document Date", PurchRcptHeader."Document Date", PurchaseHeader."No.", PurchRcptHeader."No.");
                until DocumentAttachment.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 90, OnBeforeDeleteAfterPosting, '', false, false)]
    local procedure OnBeforeDeleteAfterPosting2(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var SkipDelete: Boolean; CommitIsSupressed: Boolean; var TempPurchLine: Record "Purchase Line" temporary; var TempPurchLineGlobal: Record "Purchase Line" temporary; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        DocumentAttachment: Record "Document Attachment";
        FolderMappingSH: Record "Google Drive Folder Mapping";
        FolderMappingSalesInv: Record "Google Drive Folder Mapping";
        FolderMappingSalesCrMemo: Record "Google Drive Folder Mapping";
        RecRef: RecordRef;
    begin
        CompanyInfo.Get();
        RecRef.GetTable(PurchaseHeader);
        If not FolderMappingSH.Get(Database::"Purchase Header") then
            exit;
        if not FolderMappingSalesInv.Get(Database::"Purch. Inv. Header") then
            exit;
        if not FolderMappingSalesCrMemo.Get(Database::"Purch. Cr. Memo Hdr.") then
            exit;

        If (PurchInvHeader."No." <> '') Or (PurchCrMemoHdr."No." <> '') then begin
            DocumentAttachment.SetRange("Table ID", Database::"Purchase Header");
            DocumentAttachment.SetRange("No.", PurchaseHeader."No.");
            DocumentAttachment.SetRange("Document Type", PurchaseHeader."Document Type");
            DocumentAttachment.SetRange("Posted Document", false);
            if not DocumentAttachment.WritePermission() then Error(MisisinDocActchPermision);
            DocumentAttachment.ModifyAll("Posted Document", true);
        end;
        if (PurchInvHeader."No." <> '') then begin
            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Purch. Inv. Header");
            DocumentAttachment.SetRange("No.", PurchInvHeader."No.");
            if DocumentAttachment.FindFirst() then
                repeat
                    FolderMappingSH.MoveFileH(CompanyInfo."Data Storage Provider", DocumentAttachment, Database::"Purchase Header", Database::"Purch. Inv. Header", RecRef, PurchaseHeader."Document Date", PurchInvHeader."Document Date", PurchaseHeader."No.", PurchInvHeader."No.");
                until DocumentAttachment.Next() = 0;
        end;
        if (PurchCrMemoHdr."No." <> '') then begin
            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Purch. Cr. Memo Hdr.");
            DocumentAttachment.SetRange("No.", PurchCrMemoHdr."No.");
            if DocumentAttachment.FindFirst() then
                repeat
                    FolderMappingSH.MoveFileH(CompanyInfo."Data Storage Provider", DocumentAttachment, Database::"Purchase Header", Database::"Purch. Cr. Memo Hdr.", RecRef, PurchaseHeader."Document Date", PurchCrMemoHdr."Document Date", PurchaseHeader."No.", PurchCrMemoHdr."No.");
                until DocumentAttachment.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteEvent(var Rec: Record "Document Attachment")
    var
        DeDonde: Text;
    begin
        if Rec.IsTemporary then exit;
        CompanyInfo.Get();
        if CompanyInfo."Data Storage Provider" = CompanyInfo."Data Storage Provider"::Local then exit;
        Case CompanyInfo."Data Storage Provider" of
            CompanyInfo."Data Storage Provider"::"Google Drive":
                DeDonde := 'Google Drive';
            CompanyInfo."Data Storage Provider"::OneDrive:
                DeDonde := 'OneDrive';
            CompanyInfo."Data Storage Provider"::DropBox:
                DeDonde := 'DropBox';
            CompanyInfo."Data Storage Provider"::Strapi:
                DeDonde := 'Strapi';
        end;
        if Rec."Posted Document" then
            exit;
        //If Confirm('¿Desea eliminar el archivo de %1?', false, DeDonde) then
        case CompanyInfo."Data Storage Provider" of
            CompanyInfo."Data Storage Provider"::"Google Drive":
                GoogleDriveManager.DeleteFile(Rec."Google Drive ID");
            CompanyInfo."Data Storage Provider"::OneDrive:
                OneDriveManager.DeleteFile(Rec."OneDrive ID");
            CompanyInfo."Data Storage Provider"::DropBox:
                DropBoxManager.DeleteFile(Rec."DropBox ID");
            CompanyInfo."Data Storage Provider"::Strapi:
                StrapiManager.DeleteFile(Rec."Strapi ID");
        end;
        //end;
    end;

    procedure UploadAttachment(var DocumentAttachment: Record "Document Attachment"; FileName: Text; FileExtension: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        FileContent: Text;
        InStream: InStream;
        OutStream: OutStream;
        UploadResult: Boolean;
        FileMgt: Codeunit "File Management";
    begin
        // Only override if "Store in Google Drive" is true
        if not DocumentAttachment."Store in Google Drive" then
            exit(false); // We can't call the original method directly so return false to let standard flow continue

        if FileName <> '' then begin
            DocumentAttachment."File Name" := CopyStr(FileName, 1, MaxStrLen(DocumentAttachment."File Name"));
            DocumentAttachment."File Extension" := CopyStr(FileExtension, 1, MaxStrLen(DocumentAttachment."File Extension"));

            // For BC Cloud, we would need to use a different approach to get file content
            // This is a simplified example showing the concept
            TempBlob.CreateOutStream(OutStream);
            FileContent := 'Sample file content for demo purposes';
            OutStream.WriteText(FileContent);

            // Set file type based on extension
            SetDocumentAttachmentFileType(DocumentAttachment, FileExtension);

            // Upload to Google Drive
            exit(GoogleDriveManager.UploadFile(DocumentAttachment, TempBlob));
        end;

        exit(true);
    end;



    procedure DeleteAttachment(var DocumentAttachment: Record "Document Attachment"): Boolean
    begin
        // In a complete implementation, you might want to delete from Google Drive as well
        // But for simplicity, we're just deleting the record

        // Mark record as deleted
        DocumentAttachment.Delete();

        exit(true);
    end;

    procedure ImportAttachmentFromStream(var DocumentAttachment: Record "Document Attachment"; InStream: InStream; FileName: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        FileExtension: Text;
        OutStream: OutStream;
        FileMgt: Codeunit "File Management";
    begin
        // Only override if "Store in Google Drive" is true
        if not DocumentAttachment."Store in Google Drive" then
            exit(false); // We can't call the original method directly

        FileExtension := FileMgt.GetExtension(FileName);

        DocumentAttachment."File Name" := CopyStr(FileName, 1, MaxStrLen(DocumentAttachment."File Name"));
        DocumentAttachment."File Extension" := CopyStr(FileExtension, 1, MaxStrLen(DocumentAttachment."File Extension"));

        // Set file type based on extension
        SetDocumentAttachmentFileType(DocumentAttachment, FileExtension);

        // Copy InStream to TempBlob
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);

        // Upload to Google Drive
        exit(GoogleDriveManager.UploadFile(DocumentAttachment, TempBlob));
    end;

    procedure SetDocumentAttachmentFileType(var DocumentAttachment: Record "Document Attachment"; FileExtension: Text)
    var
        FileType: Enum "Document Attachment File Type";
    begin
        if FileExtension = '' then begin
            if StrPos(DocumentAttachment."File Name", '.') > 0 then
                FileExtension := CopyStr(DocumentAttachment."File Name", StrLen(DocumentAttachment."File Name") - 3, 4);
            if StrPos(FileExtension, '.') > 0 then
                FileExtension := CopyStr(FileExtension, StrPos(FileExtension, '.') + 1, 3);
            FileExtension := '.' + FileExtension;
        end;
        case LowerCase(FileExtension) of
            '.pdf':
                FileType := FileType::PDF;
            '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff':
                FileType := FileType::Image;
            '.doc', '.docx', '.odt':
                FileType := FileType::Word;
            '.xls', '.xlsx', '.ods':
                FileType := FileType::Excel;
            '.xml':
                FileType := FileType::XML;
            else
                FileType := FileType::Other;
        end;
        DocumentAttachment."File Type" := FileType;
    end;

    internal procedure OnAfterGetRecord(var Maestro: Text; var Recargar: Boolean; RecRef: RecordRef; var Id: Text; No: Code[20]; Fecha: Date): Boolean
    var
        FolderMapping: Record "Google Drive Folder Mapping";
        Folder: Text;
        SubFolder: Text;
        Path: Text;

    begin
        CompanyInfo.Get();
        if not CompanyInfo."Funcionalidad extendida" then
            exit;
        case CompanyInfo."Data Storage Provider" of
            CompanyInfo."Data Storage Provider"::"Google Drive":
                begin
                    Maestro := No;
                    GoogleDriveManager.GetFolderMapping(RecRef.Number, Id);
                    SubFolder := FolderMapping.CreateSubfolderPath(RecRef.Number, No, 0D, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then
                        Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
                    if CompanyInfo."Funcionalidad extendida" then
                        Recargar := true;
                end;
            CompanyInfo.
            "Data Storage Provider"::OneDrive:
                begin
                    Maestro := No;
                    Path := CompanyInfo."Root Folder" + '/';
                    FolderMapping.SetRange("Table ID", RecRef.Number);
                    if FolderMapping.FindFirst() Then begin
                        Id := FolderMapping."Default Folder Id";
                        Path += FolderMapping."Default Folder Name" + '/';
                    end;

                    SubFolder := FolderMapping.CreateSubfolderPath(RecRef.Number, No, Fecha, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then begin
                        Id := OneDriveManager.CreateFolderStructure(Id, SubFolder);
                        Path += SubFolder + '/'
                    end;
                    if CompanyInfo."Funcionalidad extendida" then
                        Recargar := true;
                end;
            CompanyInfo."Data Storage Provider"::DropBox:
                begin
                    Maestro := No;
                    FolderMapping.SetRange("Table ID", RecRef.Number);
                    if FolderMapping.FindFirst() Then Id := FolderMapping."Default Folder ID";
                    SubFolder := FolderMapping.CreateSubfolderPath(RecRef.Number, No, Fecha, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then
                        Id := DropBoxManager.CreateFolderStructure(Id, SubFolder);
                    if CompanyInfo."Funcionalidad extendida" then
                        Recargar := true;
                end;
            CompanyInfo."Data Storage Provider"::Strapi:
                begin
                    Maestro := No;
                    FolderMapping.SetRange("Table ID", RecRef.Number);
                    if FolderMapping.FindFirst() Then Id := FolderMapping."Default Folder ID";
                    SubFolder := FolderMapping.CreateSubfolderPath(RecRef.Number, No, Fecha, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then
                        Id := StrapiManager.CreateFolderStructure(Id, SubFolder);
                    if CompanyInfo."Funcionalidad extendida" then
                        Recargar := true;
                end;
            CompanyInfo."Data Storage Provider"::SharePoint:
                begin
                    Maestro := No;
                    FolderMapping.SetRange("Table ID", RecRef.Number);
                    if FolderMapping.FindFirst() Then Id := FolderMapping."Default Folder ID";
                    SubFolder := FolderMapping.CreateSubfolderPath(RecRef.Number, No, Fecha, CompanyInfo."Data Storage Provider");
                    IF SubFolder <> '' then
                        Id := SharePointManager.CreateFolderStructure(Id, SubFolder);
                    if CompanyInfo."Funcionalidad extendida" then
                        Recargar := true;
                end;
        end;
    end;

    internal procedure FuncionalidadExtendida(): Boolean
    begin
        if CompanyInfo.Get() then
            exit(CompanyInfo."Funcionalidad extendida");
        exit(false);
    end;

    internal procedure IsGoogleDrive(): Boolean
    begin
        if CompanyInfo.Get() then
            exit(CompanyInfo."Data Storage Provider" = CompanyInfo."Data Storage Provider"::"Google Drive");
        exit(false);
    end;

    internal procedure IsOneDrive(): Boolean
    begin
        if CompanyInfo.Get() then
            exit(CompanyInfo."Data Storage Provider" = CompanyInfo."Data Storage Provider"::OneDrive);
        exit(false);
    end;

    internal procedure IsDropBox(): Boolean
    begin
        if CompanyInfo.Get() then
            exit(CompanyInfo."Data Storage Provider" = CompanyInfo."Data Storage Provider"::DropBox);
        exit(false);
    end;

    internal procedure IsStrapi(): Boolean
    begin
        if CompanyInfo.Get() then
            exit(CompanyInfo."Data Storage Provider" = CompanyInfo."Data Storage Provider"::Strapi);
        exit(false);
    end;

    internal procedure IsSharePoint(): Boolean
    begin
        if CompanyInfo.Get() then
            exit(CompanyInfo."Data Storage Provider" = CompanyInfo."Data Storage Provider"::SharePoint);
        exit(false);
    end;

    internal procedure GetDataStorageProvider(): Enum "Data Storage Provider"
    begin
        if CompanyInfo.Get() then
            exit(CompanyInfo."Data Storage Provider");
        exit(CompanyInfo."Data Storage Provider"::Local);
    end;

    internal procedure GetRootFolderId(): Text
    begin
        if CompanyInfo.Get() then
            exit(CompanyInfo."Root Folder ID");
        exit('');
    end;

    internal procedure GetRootFolder(): Text
    begin
        if CompanyInfo.Get() then
            exit(CompanyInfo."Root Folder");
        exit('');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnBeforeHasContent', '', true, true)]
    local procedure OnBeforeHasContent(var DocumentAttachment: Record "Document Attachment"; var AttachmentIsAvailable: Boolean; var IsHandled: Boolean)
    begin
        if (DocumentAttachment."Store in Google Drive" or DocumentAttachment."Store in OneDrive" or DocumentAttachment."Store in DropBox" or DocumentAttachment."Store in Strapi") then begin
            AttachmentIsAvailable := true;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnBeforeExport', '', true, true)]
    local procedure OnBeforeExport(var DocumentAttachment: Record "Document Attachment"; var IsHandled: Boolean; ShowFileDialog: Boolean)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if CompanyInfo."Data Storage Provider" = CompanyInfo."Data Storage Provider"::Local then exit;
        if DocumentAttachment."Store in Google Drive" then begin
            IsHandled := true;
            GoogleDriveManager.OpenFileInBrowser(DocumentAttachment."Google Drive ID");
        end;
        if DocumentAttachment."Store in OneDrive" then begin
            IsHandled := true;
            OneDriveManager.OpenFileInBrowser(DocumentAttachment."OneDrive ID", false);
        end;
        if DocumentAttachment."Store in DropBox" then begin
            IsHandled := true;
            DropBoxManager.OpenFileInBrowser(DocumentAttachment."DropBox ID");
        end;
        if DocumentAttachment."Store in Strapi" then begin
            IsHandled := true;
            StrapiManager.OpenFileInBrowser(DocumentAttachment."Strapi ID");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnBeforeGetAsTempBlob', '', true, true)]
    local procedure OnBeforeGetAsTempBlob(var DocumentAttachment: Record "Document Attachment"; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    var
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        Base64Data: Text;
        OutStream: OutStream;
        Base64: Codeunit "Base64 Convert";
    begin
        if DocumentAttachment."Store in Google Drive" then begin
            If Not GoogleDriveManager.DownloadFileB64(DocumentAttachment."Google Drive ID", DocumentAttachment."File Name", false, Base64Data) then
                exit;
            TempBlob.CreateOutStream(OutStream);
            Base64.FromBase64(Base64Data, OutStream);
            IsHandled := true;
        end;
        if DocumentAttachment."Store in OneDrive" then begin
            If Not OneDriveManager.DownloadFileB64(DocumentAttachment."OneDrive ID", DocumentAttachment."File Name", false, Base64Data) then
                exit;
            TempBlob.CreateOutStream(OutStream);
            Base64.FromBase64(Base64Data, OutStream);
            IsHandled := true;
        end;
        if DocumentAttachment."Store in DropBox" then begin
            If Not DropBoxManager.DownloadFileB64('', DocumentAttachment."File Name", false, Base64Data) then
                exit;
            TempBlob.CreateOutStream(OutStream);
            Base64.FromBase64(Base64Data, OutStream);
            IsHandled := true;
        end;
        if DocumentAttachment."Store in Strapi" then begin
            Base64Data := StrapiManager.DownloadFileB64('', DocumentAttachment."Strapi ID", DocumentAttachment."File Name", false);
        end;
    end;

}