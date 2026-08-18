page 95124 "Incoming Docs. to Doc. Attach."
{
    Caption = 'Incoming documents to Document Attachment';
    PageType = List;
    SourceTable = "Incoming Document";
    SourceTableView = sorting("Entry No.");
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Entry number of the incoming document.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Description.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Document type.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of the created document.';
                }
                field("Related Record ID"; Rec."Related Record ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Related document record (invoice, order, etc.).';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Status.';
                }
                field("URL"; Rec.URL)
                {
                    ApplicationArea = All;
                    ToolTip = 'Incoming document URL.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateDocAttachments)
            {
                Caption = 'Create Document Attachments and upload';
                Image = Export;
                ApplicationArea = All;
                ToolTip = 'For each selected incoming document, creates Document Attachment records from its attachments, linked to the related document, and uploads them to storage. Does not create duplicates by file name.';

                trigger OnAction()
                var
                    IncomingDocument: Record "Incoming Document";
                    DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                    CountCreated: Integer;
                    CountSkipped: Integer;
                    TotalCreated: Integer;
                    TotalSkipped: Integer;
                begin
                    CurrPage.SetSelectionFilter(IncomingDocument);
                    if not IncomingDocument.FindSet() then
                        exit;
                    repeat
                        if DocAttachmentMgmtGDrive.CreateDocumentAttachmentsFromIncomingDocument(IncomingDocument, CountCreated, CountSkipped) then begin
                            TotalCreated += CountCreated;
                            TotalSkipped += CountSkipped;
                        end;
                    until IncomingDocument.Next() = 0;
                    Message(ResultMsg, TotalCreated, TotalSkipped);
                    CurrPage.Update(false);
                end;
            }
            action(QuitarFiltroInc)
            {
                Caption = 'Clear filter';
                Image = ClearFilter;
                ApplicationArea = All;
                ToolTip = 'Clear the filter.';

                trigger OnAction()
                begin
                    Rec.Reset();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(CreateDocAttachmentsRef; CreateDocAttachments) { }
                actionref(QuitarFiltroIncRef; QuitarFiltroInc) { }
            }
        }
    }

    var
        ResultMsg: Label 'Created: %1 attachment(s). Skipped (already existed with the same name): %2.', Comment = '%1=Created, %2=Skipped';
}
