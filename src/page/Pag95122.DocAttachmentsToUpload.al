page 95122 "Doc. Attachments to Upload"
{
    Caption = 'Adjuntos a subir a almacenamiento';
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
                    ToolTip = 'Identificador de la tabla del documento.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número del documento.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tipo de documento cuando aplica.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre del archivo.';
                }
                field("File Extension"; Rec."File Extension")
                {
                    ApplicationArea = All;
                    ToolTip = 'Extensión del archivo.';
                }
                field("Store in Google Drive"; Rec."Store in Google Drive")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si ya está almacenado en Google Drive.';
                }
                field("Store in OneDrive"; Rec."Store in OneDrive")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si ya está almacenado en OneDrive.';
                }
                field(HasContent; HasDocumentContent)
                {
                    Caption = 'Tiene contenido local';
                    ApplicationArea = All;
                    ToolTip = 'El adjunto tiene contenido en Document Reference ID (no ha pasado por la extensión).';
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
                Caption = 'Subir a almacenamiento';
                Image = Export;
                ApplicationArea = All;
                ToolTip = 'Extrae el documento del campo Document Reference ID y lo sube al proveedor configurado (Google Drive, OneDrive, etc.).';

                trigger OnAction()
                begin
                    UploadSelectedToStorage();
                end;
            }
            action(ShowOnlyNotUploaded)
            {
                Caption = 'Solo adjuntos no subidos';
                Image = Filter;
                ApplicationArea = All;
                ToolTip = 'Filtrar solo registros que tienen contenido local y aún no están en el almacenamiento configurado.';

                trigger OnAction()
                begin
                    SetFilterNotUploaded();
                end;
            }
            action(ClearFilter)
            {
                Caption = 'Quitar filtro';
                Image = ClearFilter;
                ApplicationArea = All;
                ToolTip = 'Quitar el filtro y mostrar todos los adjuntos.';

                trigger OnAction()
                begin
                    Rec.Reset();
                    CurrPage.Update(false);
                end;
            }
            action(FromIncomingDocuments)
            {
                Caption = 'Desde documentos entrantes';
                Image = Document;
                ApplicationArea = All;
                ToolTip = 'Abre la lista de documentos entrantes para crear Document Attachments desde sus adjuntos y subirlos al almacenamiento (sin duplicar por nombre).';

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
                Caption = 'Proceso';
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
        SuccessCountMsg: Label '%1 adjunto(s) subido(s) correctamente.';
        ErrorNoContentMsg: Label 'El adjunto "%1" no tiene contenido en Document Reference ID.', Comment = '%1 = File Name';
        ErrorUploadMsg: Label 'Error al subir el adjunto "%1".', Comment = '%1 = File Name';
        ConfirmUploadQst: Label '¿Subir los adjuntos seleccionados al almacenamiento configurado?';

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
                if DocAttachmentMgmtGDrive.UploadExistingAttachmentToCloud(DocumentAttachment, DocInStream) then
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
