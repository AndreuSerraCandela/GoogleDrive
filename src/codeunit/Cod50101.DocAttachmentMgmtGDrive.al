codeunit 50101 "Doc. Attachment Mgmt. GDrive"
{
    // This codeunit overrides the standard Document Attachment Management functionality
    // to use Google Drive instead of storing files in the tenant media

    var
        GoogleDriveManager: Codeunit "Google Drive Manager";

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

    procedure DownloadAttachment(var DocumentAttachment: Record "Document Attachment"; ShowFileDialog: Boolean): Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
    begin
        // Only override if "Store in Google Drive" is true
        if not DocumentAttachment."Store in Google Drive" then
            exit(''); // We can't call the original method directly

        // Download from Google Drive
        if not GoogleDriveManager.DownloadFile(DocumentAttachment, TempBlob) then
            exit('');

        // In a real implementation, we would handle the file download differently for BC Cloud
        // This is a simplified example showing the concept
        FileName := DocumentAttachment."File Name";
        if ShowFileDialog then
            Message('File "%1" would be downloaded from Google Drive', FileName);

        exit(FileName);
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

    local procedure SetDocumentAttachmentFileType(var DocumentAttachment: Record "Document Attachment"; FileExtension: Text)
    var
        FileType: Enum "Document Attachment File Type";
    begin
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
}