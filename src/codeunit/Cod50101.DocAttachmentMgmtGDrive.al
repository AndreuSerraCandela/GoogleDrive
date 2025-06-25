codeunit 95101 "Doc. Attachment Mgmt. GDrive"
{
    // This codeunit overrides the standard Document Attachment Management functionality
    // to use Google Drive instead of storing files in the tenant media

    var
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        CompanyInfo: Record "Company Information";

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnInsertAttachmentOnBeforeImportStream, '', false, false)]
    local procedure OnInsertAttachmentOnBeforeImportStream(var DocumentAttachment: Record "Document Attachment"; DocInStream: InStream; FileName: Text; var IsHandled: Boolean)
    var
        FolderMapping: Record "Google Drive Folder Mapping";
        Folder: Text;
        SubFolder: Text;
        Path: Text;
    begin
        CompanyInfo.Get();
        case CompanyInfo."Data Storage Provider" of
            CompanyInfo."Data Storage Provider"::"Google Drive":
                begin
                    DocumentAttachment."Store in Google Drive" := true;
                    FolderMapping.SetRange("Table ID", DocumentAttachment."Table ID");
                    if FolderMapping.FindFirst() Then Folder := FolderMapping."Default Folder ID";
                    SubFolder := FolderMapping.CreateSubfolderPath(DocumentAttachment."Table ID", DocumentAttachment."No.", 0D, CompanyInfo."Data Storage Provider");
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
                    SubFolder := FolderMapping.CreateSubfolderPath(DocumentAttachment."Table ID", DocumentAttachment."No.", 0D, CompanyInfo."Data Storage Provider");
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
                    SubFolder := FolderMapping.CreateSubfolderPath(DocumentAttachment."Table ID", DocumentAttachment."No.", 0D, CompanyInfo."Data Storage Provider");
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

    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteEvent(var Rec: Record "Document Attachment")
    var
        DeDonde: Text;
    begin
        if Rec.IsTemporary then exit;
        CompanyInfo.Get();
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
        If Confirm('¿Desea eliminar el archivo de %1?', false, DeDonde) then
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
    begin
        if DocumentAttachment."Store in Google Drive" then begin
            IsHandled := true;
            GoogleDriveManager.OpenFileInBrowser(DocumentAttachment."Google Drive ID");
        end;
        if DocumentAttachment."Store in OneDrive" then begin
            IsHandled := true;
            OneDriveManager.OpenFileInBrowser(DocumentAttachment."OneDrive ID");
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
            Base64Data := GoogleDriveManager.DownloadFileB64(DocumentAttachment."Google Drive ID", DocumentAttachment."File Name", false);
            TempBlob.CreateOutStream(OutStream);
            Base64.FromBase64(Base64Data, OutStream);
            IsHandled := true;
        end;
        if DocumentAttachment."Store in OneDrive" then begin
            Base64Data := OneDriveManager.DownloadFileB64(DocumentAttachment."OneDrive ID", DocumentAttachment."File Name", false);
            TempBlob.CreateOutStream(OutStream);
            Base64.FromBase64(Base64Data, OutStream);
            IsHandled := true;
        end;
        if DocumentAttachment."Store in DropBox" then begin
            Base64Data := DropBoxManager.DownloadFileB64('', DocumentAttachment."DropBox ID", DocumentAttachment."File Name", false);
            TempBlob.CreateOutStream(OutStream);
            Base64.FromBase64(Base64Data, OutStream);
            IsHandled := true;
        end;
        if DocumentAttachment."Store in Strapi" then begin
            Base64Data := StrapiManager.DownloadFileB64('', DocumentAttachment."Strapi ID", DocumentAttachment."File Name", false);
        end;
    end;

}