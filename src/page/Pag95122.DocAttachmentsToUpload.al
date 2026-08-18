page 95122 "Doc. Attachments to Upload"
{
    Caption = 'Attachments to upload to storage';
    PageType = List;
    SourceTable = "Document Attachment";
    SourceTableView = sorting("Table ID", "No.", "Document Type", "Line No.");
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Identifier of the document table.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Document number.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Document type when applicable.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'File name.';
                }
                field("File Extension"; Rec."File Extension")
                {
                    ApplicationArea = All;
                    ToolTip = 'File extension.';
                }
                field("Store in Google Drive"; Rec."Store in Google Drive")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether it is already stored in Google Drive.';
                }
                field("Store in OneDrive"; Rec."Store in OneDrive")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether it is already stored in OneDrive.';
                }
                field(HasContent; HasDocumentContent)
                {
                    Caption = 'Has local content';
                    ApplicationArea = All;
                    ToolTip = 'The attachment has content in Document Reference ID (it has not gone through the extension).';
                    Editable = false;
                }

            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UploadToStorage)
            {
                Caption = 'Upload to storage';
                Image = Export;
                ApplicationArea = All;
                ToolTip = 'Extracts the document from the Document Reference ID field and uploads it to the configured provider (Google Drive, OneDrive, etc.).';

                trigger OnAction()
                begin
                    UploadSelectedToStorage();
                end;
            }
            action(ShowOnlyNotUploaded)
            {
                Caption = 'Not uploaded attachments only';
                Image = Filter;
                ApplicationArea = All;
                ToolTip = 'Filter only records that have local content and are not yet in the configured storage.';

                trigger OnAction()
                begin
                    SetFilterNotUploaded();
                end;
            }
            action(ClearFilter)
            {
                Caption = 'Clear filter';
                Image = ClearFilter;
                ApplicationArea = All;
                ToolTip = 'Clear the filter and show all attachments.';

                trigger OnAction()
                begin
                    Rec.Reset();
                    CurrPage.Update(false);
                end;
            }
            action(FromIncomingDocuments)
            {
                Caption = 'From incoming documents';
                Image = Document;
                ApplicationArea = All;
                ToolTip = 'Opens the incoming documents list to create Document Attachments from their attachments and upload them to storage (without duplicating by file name).';

                trigger OnAction()
                var
                    IncomingDocsPage: Page "Incoming Docs. to Doc. Attach.";
                begin
                    IncomingDocsPage.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(UploadToStorageRef; UploadToStorage)
                {
                }
                actionref(ShowOnlyNotUploadedRef; ShowOnlyNotUploaded)
                {
                }
                actionref(ClearFilterRef; ClearFilter)
                {
                }
                actionref(FromIncomingDocumentsRef; FromIncomingDocuments)
                {
                }
            }
        }
    }

    var
        DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
        SuccessCountMsg: Label '%1 attachment(s) uploaded successfully.', Comment = '%1 = Number of uploaded attachments';
        ErrorNoContentMsg: Label 'Attachment "%1" has no content in Document Reference ID.', Comment = '%1 = File Name';
        ErrorUploadMsg: Label 'Error uploading attachment "%1".', Comment = '%1 = File Name';
        ConfirmUploadQst: Label 'Upload the selected attachments to the configured storage?';

    local procedure HasDocumentContent(): Boolean
    begin
        exit(Rec."Document Reference ID".HasValue());
    end;

    local procedure UploadSelectedToStorage()
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        DocInStream: InStream;
        DocOutStream: OutStream;
        Count: Integer;
        IdDrive: Text;
    begin
        if not Confirm(ConfirmUploadQst) then
            exit;
        CurrPage.SetSelectionFilter(DocumentAttachment);
        if not DocumentAttachment.FindSet() then
            exit;
        repeat
            if not DocumentAttachment."Document Reference ID".HasValue() then
                Message(ErrorNoContentMsg, DocumentAttachment."File Name")
            else begin
                TempBlob.CreateOutStream(DocOutStream);
                DocumentAttachment."Document Reference ID".ExportStream(DocOutStream);
                TempBlob.CreateInStream(DocInStream);
                if DocAttachmentMgmtGDrive.UploadExistingAttachmentToCloud(DocumentAttachment, DocInStream, IdDrive) then
                    Count += 1
                else
                    Message(ErrorUploadMsg, DocumentAttachment."File Name");
            end;
        until DocumentAttachment.Next() = 0;
        if Count > 0 then
            Message(SuccessCountMsg, Count);
        CurrPage.Update(false);
    end;

    local procedure SetFilterNotUploaded()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        Rec.Reset();
        case CompanyInfo."Data Storage Provider" of
            CompanyInfo."Data Storage Provider"::"Google Drive":
                Rec.SetRange("Store in Google Drive", false);
            CompanyInfo."Data Storage Provider"::OneDrive:
                Rec.SetRange("Store in OneDrive", false);
            CompanyInfo."Data Storage Provider"::DropBox:
                Rec.SetRange("Store in DropBox", false);
            CompanyInfo."Data Storage Provider"::Strapi:
                Rec.SetRange("Store in Strapi", false);
            CompanyInfo."Data Storage Provider"::SharePoint:
                Rec.SetRange("Store in SharePoint", false);
            else
                Rec.SetRange("Store in Google Drive", false); // por defecto
        end;
        CurrPage.Update(false);
    end;
}
