page 95124 "Incoming Docs. to Doc. Attach."
{
    Caption = 'Documentos entrantes a Document Attachment';
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
                    ToolTip = 'Número de entrada del documento entrante.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tipo de documento.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número del documento creado.';
                }
                field("Related Record ID"; Rec."Related Record ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Registro del documento relacionado (factura, pedido, etc.).';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Estado.';
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
                Caption = 'Crear Document Attachments y subir';
                Image = Export;
                ApplicationArea = All;
                ToolTip = 'Para cada documento entrante seleccionado, crea registros Document Attachment a partir de sus adjuntos, vinculados al documento relacionado, y los sube al almacenamiento. No crea duplicados por nombre de archivo.';

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
                Caption = 'Quitar filtro';
                Image = ClearFilter;
                ApplicationArea = All;
                ToolTip = 'Quitar el filtro.';

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
                Caption = 'Proceso';
                actionref(CreateDocAttachmentsRef; CreateDocAttachments) { }
                actionref(QuitarFiltroIncRef; QuitarFiltroInc) { }
            }
        }
    }

    var
        ResultMsg: Label 'Creados: %1 adjunto(s). Omitidos (ya existían con el mismo nombre): %2.', Comment = '%1=Created, %2=Skipped';
}
