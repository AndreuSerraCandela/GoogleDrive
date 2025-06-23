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
        modify(OpenInOneDrive)
        {
            Visible = false;
        }
        modify(ShareWithOneDrive)
        {
            Visible = false;
        }
        modify(EditInOneDrive)
        {
            Visible = false;
        }
        modify(DownloadInRepeater)
        {
            Visible = false;
        }


        addafter(AttachmentsUpload)
        {
            action(UploadToGoogleDrive)
            {
                ApplicationArea = All;
                Caption = 'Cargar archivo desde el drive';
                Image = FileContract;
                trigger OnAction()
                var
                    DocumentAttachment: Record "Document Attachment";
                    DocAttachmentGrDriveMgmt: Codeunit "Doc. Attachment Mgmt. GDrive";
                    DocumentMgmt: Codeunit "Document Attachment Mgmt";
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    RecRef: RecordRef;
                    IdTable: Integer;
                    IdTableFilter: Text;
                    No: Text;
                    Files: Record "Name/Value Buffer" temporary;
                    TargetFolderId: Text;
                    FilesSelected: Page "Google Drive List";
                    Id: Integer;
                    CompanyInfo: Record "Company Information";
                begin
                    CompanyInfo.Get();

                    IdTable := Rec."Table ID";
                    if IdTable = 0 then
                        IdTableFilter := Rec.GetFilter("Table ID");
                    if IdTable = 0 then
                        Evaluate(IdTable, IdTableFilter);
                    No := Rec."No.";

                    // Obtener la carpeta objetivo según el proveedor configurado
                    case CompanyInfo."Data Storage Provider" of
                        CompanyInfo."Data Storage Provider"::"Google Drive":
                            begin
                                TargetFolderId := GoogleDriveManager.GetTargetFolderForDocument(IdTable, No, 0D, CompanyInfo."Data Storage Provider");
                                GoogleDriveManager.Carpetas(TargetFolderId, Files);
                            end;
                        CompanyInfo."Data Storage Provider"::OneDrive:
                            begin
                                // Para OneDrive, usar la carpeta raíz por defecto
                                OneDriveManager.ListFolder('', Files, false);
                            end;
                        CompanyInfo."Data Storage Provider"::DropBox:
                            begin
                                // Para DropBox, usar la carpeta raíz por defecto
                                DropBoxManager.ListFolder('', Files, false);
                            end;
                        CompanyInfo."Data Storage Provider"::Strapi:
                            begin
                                // Para Strapi, listar todos los archivos
                                StrapiManager.ListFolder('', Files, false);
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
                                Rec."Storage Provider" := CompanyInfo."Data Storage Provider";

                                // Asignar el ID según el proveedor
                                case CompanyInfo."Data Storage Provider" of
                                    CompanyInfo."Data Storage Provider"::"Google Drive":
                                        begin
                                            Rec."Store in Google Drive" := true;
                                            Rec."Google Drive ID" := Files."Google Drive ID";
                                        end;
                                    CompanyInfo."Data Storage Provider"::OneDrive:
                                        begin
                                            Rec."Store in OneDrive" := true;
                                            Rec."OneDrive ID" := Files."Google Drive ID"; // Reutilizamos el campo
                                        end;
                                    CompanyInfo."Data Storage Provider"::DropBox:
                                        begin
                                            Rec."Store in DropBox" := true;
                                            Rec."DropBox ID" := Files."Google Drive ID"; // Reutilizamos el campo
                                        end;
                                    CompanyInfo."Data Storage Provider"::Strapi:
                                        begin
                                            Rec."Store in Strapi" := true;
                                            Rec."Strapi ID" := Files."Google Drive ID"; // Reutilizamos el campo
                                        end;
                                end;

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

        addafter(MoveToGoogleDrive)
        {
            action(DownloadFile)
            {
                ApplicationArea = All;
                Caption = 'Descargar Archivo';
                Image = Download;
                ToolTip = 'Descarga el archivo desde el almacenamiento en la nube.';
                trigger OnAction()
                var
                    Base64Txt: Text;
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                begin
                    case Rec."Storage Provider" of
                        Rec."Storage Provider"::"Google Drive":
                            Base64Txt := GoogleDriveManager.DownloadFileB64(Rec.GetDocumentID(), Rec."File Name", true);
                        Rec."Storage Provider"::OneDrive:
                            Base64Txt := OneDriveManager.DownloadFileB64('', Base64Txt, Rec."File Name", true);
                        Rec."Storage Provider"::DropBox:
                            Base64Txt := DropBoxManager.DownloadFileB64('', Base64Txt, Rec."File Name", true);
                        Rec."Storage Provider"::Strapi:
                            Base64Txt := StrapiManager.DownloadFileB64('', Base64Txt, Rec."File Name", true);
                    end;
                end;
            }

            action(MoveFile)
            {
                ApplicationArea = All;
                Caption = 'Mover';
                Image = Change;
                ToolTip = 'Mueve el archivo a otra carpeta.';
                Visible = true;
                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    GoogleDriveList: Page "Google Drive List";
                    destino: Text;
                    TempFiles: Record "Name/Value Buffer" temporary;
                    GoogleDrive: Codeunit "Google Drive Manager";
                    root: Boolean;
                    CarpetaAnterior: List of [Text];
                    Inf: Record "Company Information";
                begin
                    Inf.Get();
                    case Rec."Storage Provider" of
                        Rec."Storage Provider"::"Google Drive":
                            begin
                                GoogleDrive.ListFolder(Inf."Root Folder ID", TempFiles, false);
                                GoogleDriveList.SetRecords(Inf."Root Folder ID", TempFiles, true);
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino);

                                // Here we would need to implement a folder selection dialog using TempFiles
                                // For now, we'll use a placeholder solution

                                if destino = '' then
                                    Message('no ha elegido destino')
                                else
                                    GoogleDrive.Movefile(Rec."Google Drive ID", Destino, '');


                            end;
                        Rec."Storage Provider"::OneDrive:
                            // OneDriveManager.MoveFile(Rec.GetDocumentID(), destino, Rec."File Name");
                            Message('Función de mover archivo no implementada aún.');
                        Rec."Storage Provider"::DropBox:
                            // DropBoxManager.MoveFile(Rec.GetDocumentID(), destino, Rec."File Name");
                            Message('Función de mover archivo no implementada aún.');
                        Rec."Storage Provider"::Strapi:
                            // StrapiManager.MoveFile(Rec.GetDocumentID(), destino, Rec."File Name");
                            Message('Función de mover archivo no implementada aún.');
                    end;
                end;
            }

            action(CopyFile)
            {
                ApplicationArea = All;
                Caption = 'Copiar Archivo';
                Image = Copy;
                ToolTip = 'Copia el archivo a otra carpeta.';
                Visible = true;
                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    GoogleDriveList: Page "Google Drive List";
                    destino: Text;
                    TempFiles: Record "Name/Value Buffer" temporary;
                    GoogleDrive: Codeunit "Google Drive Manager";
                    root: Boolean;
                    CarpetaAnterior: List of [Text];
                    Inf: Record "Company Information";
                // TODO: Implementar diálogo de selección de carpeta destino
                begin
                    case Rec."Storage Provider" of
                        Rec."Storage Provider"::"Google Drive":
                            begin
                                GoogleDrive.ListFolder(Inf."Root Folder ID", TempFiles, false);
                                GoogleDriveList.SetRecords(Inf."Root Folder ID", TempFiles, true);
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino);
                                if destino = '' then
                                    Message('no ha elegido destino')
                                else
                                    GoogleDrive.Copyfile(Rec."Google Drive ID", Destino);
                            end;
                        Rec."Storage Provider"::OneDrive:
                            // OneDriveManager.CopyFile(Rec.GetDocumentID(), destino);
                            Message('Función de copiar archivo no implementada aún.');
                        Rec."Storage Provider"::DropBox:
                            // DropBoxManager.CopyFile(Rec.GetDocumentID(), destino);
                            Message('Función de copiar archivo no implementada aún.');
                        Rec."Storage Provider"::Strapi:
                            // StrapiManager.CopyFile(Rec.GetDocumentID(), destino);
                            Message('Función de copiar archivo no implementada aún.');
                    end;
                end;
            }

            action(CreateFolder)
            {
                ApplicationArea = All;
                Caption = 'Crear Carpeta';
                Image = ToggleBreakpoint;
                ToolTip = 'Crea una carpeta en el almacenamiento en la nube.';
                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    DialogPage: Page "Dialogo Google Drive";
                    FolderName: Text;
                begin
                    DialogPage.SetTexto('Nombre Carpeta');
                    if DialogPage.RunModal() = Action::OK then begin
                        DialogPage.GetTexto(FolderName);
                        if FolderName <> '' then begin
                            case Rec."Storage Provider" of
                                Rec."Storage Provider"::"Google Drive":
                                    GoogleDriveManager.CreateFolder(FolderName, '', false);
                                Rec."Storage Provider"::OneDrive:
                                    OneDriveManager.CreateOneDriveFolder(FolderName, '', false);
                                Rec."Storage Provider"::DropBox:
                                    DropBoxManager.CreateFolder(FolderName);
                                Rec."Storage Provider"::Strapi:
                                    StrapiManager.CreateFolder(FolderName);
                            end;
                            Message('Carpeta "%1" creada correctamente.', FolderName);
                        end;
                    end;
                end;
            }

            action(DeleteFile)
            {
                ApplicationArea = All;
                Caption = 'Borrar';
                Image = Delete;
                ToolTip = 'Elimina el archivo del almacenamiento en la nube.';
                Visible = true;
                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    ConfirmMsg: Label '¿Está seguro de que desea eliminar el archivo "%1"?';
                begin
                    if not Confirm(ConfirmMsg, false, Rec."File Name") then
                        exit;

                    case Rec."Storage Provider" of
                        Rec."Storage Provider"::"Google Drive":
                            If not GoogleDriveManager.DeleteFile(Rec.GetDocumentID()) then
                                Message('Error al eliminar el archivo.');
                        Rec."Storage Provider"::OneDrive:
                            If not OneDriveManager.DeleteFile(Rec.GetDocumentID()) then
                                Message('Error al eliminar el archivo.');
                        Rec."Storage Provider"::DropBox:
                            DropBoxManager.DeleteFile(Rec.GetDocumentID());
                        Rec."Storage Provider"::Strapi:
                            StrapiManager.DeleteFile(Rec.GetDocumentID());
                    end;

                    // Eliminar el registro local
                    Rec.Delete();
                    Message('Archivo eliminado correctamente.');
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
            //                     SubFolder := FolderMapping.CreateSubfolderPath(Rec."Table ID",Rec."No.", 0D);
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