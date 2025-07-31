page 95100 "Google Drive Factbox"
{
    Caption = 'Drive Factbox';
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    DeleteAllowed = false;
    Permissions = tabledata "Company Information" = RIMD,
                  tabledata "Document Attachment" = RIMD,
                  tabledata "Name/Value Buffer" = RIMD,
                  tabledata "Google Drive Folder Mapping" = RIMD;
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    DrillDown = true;
                    StyleExpr = Stilo;
                    trigger OnDrillDown()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                        SharePointManager: Codeunit "SharePoint Manager";
                        OneDriveManager: Codeunit "OneDrive Manager";
                        DropBoxManager: Codeunit "DropBox Manager";
                        StrapiManager: Codeunit "Strapi Manager";
                        DataStorageProvider: Enum "Data Storage Provider";
                        DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                        a: Integer;
                    begin
                        Nombre := Rec.Name;
                        If Nombre = '..' Then begin
                            // Subir al nivel anterior
                            Accion := Accion::Anterior;
                            Indice := Indice - 1;
                            if Indice < 1 then begin
                                Indice := 1;
                                Error(NoRootLevelErr);
                            end;
                            Rec.Value := 'Carpeta';
                            Rec."Google Drive ID" := root;
                            a := Indice;
                            if Indice = 1 then
                                Recargar('', '', Indice, GRecRef)
                            else
                                Recargar(CarpetaAnterior[Indice], CarpetaAnterior[Indice - 1], Indice - 1, GRecRef);
                            Indice := a;
                        end else begin
                            if Rec.Value = 'Carpeta' then begin
                                // Navegar a la subcarpeta
                                Accion := Accion::" ";
                                Indice := Indice + 1;
                                Recargar(Rec."Google Drive ID", Rec."Google Drive Parent ID", Indice, GRecRef);
                            end else begin
                                // Descargar archivo
                                Accion := Accion::"Descargar Archivo";
                                //Base64Txt := GoogleDrive.DownloadFileB64(Rec."Google Drive ID", Rec.Name, true);
                                DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
                                case DataStorageProvider of
                                    DataStorageProvider::"Google Drive":
                                        GoogleDriveManager.OpenFileInBrowser(Rec."Google Drive ID");
                                    DataStorageProvider::OneDrive:
                                        OneDriveManager.OpenFileInBrowser(Rec."Google Drive ID", false);
                                    DataStorageProvider::DropBox:
                                        DropBoxManager.OpenFileInBrowser(Rec."Google Drive ID");
                                    DataStorageProvider::Strapi:
                                        StrapiManager.OpenFileInBrowser(Rec."Google Drive ID");
                                    DataStorageProvider::SharePoint:
                                        SharePointManager.OpenFileInBrowser(Rec."Google Drive ID", false);
                                end;
                                Recargar(root, CarpetaAnterior[Indice], Indice, GRecRef);
                            end;
                        end;
                    end;
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    Visible = false;
                }
                field("File Extension"; Rec."File Extension")
                {
                    ApplicationArea = All;
                    Caption = 'Extension';
                    Visible = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditInDrive)
            {
                ApplicationArea = All;
                Caption = 'Edit in Drive';
                Image = Edit;
                ToolTip = 'Opens the file in the cloud storage for editing.';


                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    GoogleDrive: Codeunit "Google Drive Manager";
                    OneDrive: Codeunit "OneDrive Manager";
                    DropBox: Codeunit "DropBox Manager";
                    Strapi: Codeunit "Strapi Manager";
                    SharePoint: Codeunit "SharePoint Manager";
                    DataStorageProvider: Enum "Data Storage Provider";
                    DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                begin
                    DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
                    case DataStorageProvider of
                        DataStorageProvider::"Google Drive":
                            GoogleDrive.EditFile(Rec."Google Drive ID");
                        DataStorageProvider::OneDrive:
                            OneDrive.EditFile(Rec."Google Drive ID");
                        DataStorageProvider::DropBox:
                            DropBox.EditFile(Rec."Google Drive ID");
                        DataStorageProvider::Strapi:
                            Strapi.EditFile(Rec."Google Drive ID");
                        DataStorageProvider::SharePoint:
                            SharePoint.EditFile(Rec."Google Drive ID");
                    end;
                end;
            }
            action("Download File")
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Download File',
                            ESP = 'Descargar Archivo';
                Scope = Repeater;
                Visible = (Archivo and Not Mueve);
                Image = Download;
                trigger OnAction()
                var
                    Base64Data: Text;
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    SharePointManager: Codeunit "SharePoint Manager";
                    DataStorageProvider: Enum "Data Storage Provider";
                    DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                    a: Integer;
                    Nombre: Text;

                begin
                    Nombre := Rec.Name;
                    Accion := Accion::"Descargar Archivo";
                    DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
                    if DataStorageProvider = DataStorageProvider::"Google Drive" then begin
                        If Not GoogleDriveManager.DownloadFileB64(Rec."Google Drive ID", Rec.Name, true, Base64Data) then
                            exit;

                    end;
                    if DataStorageProvider = DataStorageProvider::OneDrive then begin
                        If Not OneDriveManager.DownloadFileB64(Rec."Google Drive ID", Rec.Name, true, Base64Data) then
                            exit;

                    end;
                    if DataStorageProvider = DataStorageProvider::DropBox then begin
                        If Not DropBoxManager.DownloadFileB64('', Rec.Name, true, Base64Data) then
                            exit;

                    end;
                    if DataStorageProvider = DataStorageProvider::Strapi then begin
                        Base64Data := StrapiManager.DownloadFileB64('', Rec."Google Drive ID", Rec.Name, true);
                    end;
                    if DataStorageProvider = DataStorageProvider::SharePoint then begin
                        SharePointManager.DownloadFileB64(Rec."Google Drive ID", Rec.Name, true, Base64Data);
                    end;
                    Recargar(root, CarpetaAnterior[Indice], Indice, GRecRef);
                end;
            }
            action("M&over")
            {
                Caption = 'Move';
                ApplicationArea = All;
                Visible = Not Mueve;
                Scope = Repeater;
                Image = Change;
                trigger OnAction()
                var
                    destino: Text;
                    TempFiles: Record "Name/Value Buffer" temporary;
                    GoogleDriveList: Page "Google Drive List";
                    DataStorageProvider: Enum "Data Storage Provider";
                    DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                    NewId: Text;
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    SharePointManager: Codeunit "SharePoint Manager";
                    NombreCarpetaDestino: Text;
                    DocRef: RecordRef;
                    FieldRef: FieldRef;
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::Mover;


                    // Get folder list
                    DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
                    case DataStorageProvider of
                        DataStorageProvider::"Google Drive":
                            begin
                                GoogleDrive.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, false);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);

                                // Here we would need to implement a folder selection dialog using TempFiles
                                // For now, we'll use a placeholder solution

                                if destino = '' then
                                    Error(NoDestinationSelectedErr)
                                else
                                    GoogleDrive.Movefile(Rec."Google Drive ID", Destino, '');


                            end;
                        DataStorageProvider::OneDrive:
                            begin
                                OneDriveManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                Commit;
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                if destino = '' then
                                    Error(NoDestinationSelectedErr)
                                else
                                    NewId := OneDriveManager.Movefile(Rec."Google Drive ID", Destino, '', true, Rec."Name" + '.' + Rec."File Extension");
                                if NewId <> '' then begin
                                    Rec."Google Drive ID" := NewId;
                                    Rec.Modify();
                                end;
                            end;
                        DataStorageProvider::DropBox:
                            // DropBoxManager.MoveFile(Rec.GetDocumentID(), destino, Rec."File Name");
                            begin
                                DropBoxManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                Commit;
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                if destino = '' then
                                    Error(NoDestinationSelectedErr)
                                else
                                    NewId := DropBoxManager.MoveFile(Rec."Google Drive ID", destino, Rec.Name + '.' + Rec."File Extension", true);
                                if NewId <> '' then begin
                                    Rec."Google Drive ID" := NewId;
                                    Rec.Modify();
                                end;
                            end;
                        DataStorageProvider::Strapi:
                            // StrapiManager.MoveFile(Rec.GetDocumentID(), destino, Rec."File Name");
                            begin
                                StrapiManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                Commit;
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                if destino = '' then
                                    Error(NoDestinationSelectedErr)
                                else
                                    NewId := StrapiManager.MoveFile(Rec."Google Drive ID", destino, Rec.Name + '.' + Rec."File Extension");
                                if NewId <> '' then begin
                                    Rec."Google Drive ID" := NewId;
                                    Rec.Modify();
                                end;
                            end;
                        DataStorageProvider::SharePoint:
                            begin
                                SharePointManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                Commit;
                                GoogleDriveList.RunModal();
                                GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                if destino = '' then
                                    error(NoDestinationSelectedErr)
                                else
                                    NewId := SharePointManager.MoveFile(Rec."Google Drive ID", destino, true, Rec.Name + '.' + Rec."File Extension");
                                if NewId <> '' then begin
                                    Rec."Google Drive ID" := NewId;
                                    Rec.Modify();
                                end;
                            end;
                    end;

                    Recargar(root, CarpetaAnterior[Indice], Indice, GRecRef);
                end;

            }
            action("Copy File")
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Copy File',
                            ESP = 'Copiar Archivo';
                Image = Copy;
                Visible = not Mueve;
                Scope = Repeater;
                trigger OnAction()
                var
                    destino: Text;
                    TempFiles: Record "Name/Value Buffer" temporary;
                    GoogleDriveList: Page "Google Drive List";
                    DataStorageProvider: Enum "Data Storage Provider";
                    DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    SharePointManager: Codeunit "SharePoint Manager";
                    NewId: Text;
                    NombreCarpetaDestino: Text;
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::Copiar;
                    // Get folder list
                    GoogleDrive.ListFolder(root, TempFiles, false);
                    GoogleDriveList.SetRecords(root, TempFiles, true);
                    GoogleDriveList.RunModal();
                    GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                    // Here we would need to implement a folder selection dialog using TempFiles
                    // For now, we'll use a placeholder solution
                    if destino = '' then
                        Error(NoDestinationSelectedErr)
                    else begin
                        DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
                        case DataStorageProvider of
                            DataStorageProvider::"Google Drive":
                                GoogleDrive.CopyFile(Rec."Google Drive ID", destino);
                            DataStorageProvider::OneDrive:
                                begin
                                    OneDriveManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                    GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                    Commit;
                                    GoogleDriveList.RunModal();
                                    GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                    if destino = '' then
                                        Error(NoDestinationSelectedErr)
                                    else
                                        NewId := OneDriveManager.Movefile(Rec."Google Drive ID", Destino, '', true, Rec."Name" + '.' + Rec."File Extension");
                                    if NewId <> '' then begin
                                        Rec."Google Drive ID" := NewId;
                                        Rec.Modify();
                                    end;
                                end;
                            DataStorageProvider::DropBox:
                                begin
                                    // DropBoxManager.MoveFile(Rec.GetDocumentID(), destino, Rec."File Name");
                                    DropBoxManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                    GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                    Commit;
                                    GoogleDriveList.RunModal();
                                    GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                    if destino = '' then
                                        Error(NoDestinationSelectedErr)
                                    else
                                        NewId := DropBoxManager.MoveFile(Rec."Google Drive ID", destino, Rec.Name + '.' + Rec."File Extension", false);
                                    if NewId <> '' then begin
                                        Rec."Google Drive ID" := NewId;
                                        Rec.Modify();
                                    end;
                                end;
                            DataStorageProvider::Strapi:
                                begin
                                    // StrapiManager.MoveFile(Rec.GetDocumentID(), destino, Rec."File Name");
                                    StrapiManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                    GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                    Commit;
                                    GoogleDriveList.RunModal();
                                    GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                    if destino = '' then
                                        Error(NoDestinationSelectedErr)
                                    else
                                        NewId := StrapiManager.MoveFile(Rec."Google Drive ID", destino, Rec.Name + '.' + Rec."File Extension");
                                    if NewId <> '' then begin
                                        Rec."Google Drive ID" := NewId;
                                        Rec.Modify();
                                    end;
                                end;
                            DataStorageProvider::SharePoint:
                                begin
                                    SharePointManager.ListFolder(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                    GoogleDriveList.SetRecords(DocAttachmentMgmtGDrive.GetRootFolderId(), TempFiles, true);
                                    Commit;
                                    GoogleDriveList.RunModal();
                                    GoogleDriveList.GetDestino(destino, NombreCarpetaDestino);
                                    if destino = '' then
                                        Error(NoDestinationSelectedErr)
                                    else
                                        NewId := SharePointManager.MoveFile(Rec."Google Drive ID", destino, true, Rec.Name + '.' + Rec."File Extension");
                                    if NewId <> '' then begin
                                        Rec."Google Drive ID" := NewId;
                                        Rec.Modify();
                                    end;
                                end;

                        end;
                        Recargar(root, CarpetaAnterior[Indice], Indice, GRecRef);
                    end;
                end;
            }

            action(CreateFolder)
            {
                ApplicationArea = All;
                Caption = 'Create Folder';
                Image = ToggleBreakpoint;
                Visible = not Mueve;
                ToolTip = 'Creates a folder in cloud storage.';
                trigger OnAction()
                var
                    DorpBox: Codeunit "Google Drive Manager";
                    Ventana: Page "Dialogo Google Drive";
                    Carpeta: Text;
                    DataStorageProvider: Enum "Data Storage Provider";
                    DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                begin
                    Ventana.SetTexto('Folder Name');
                    Ventana.RunModal();
                    Ventana.GetTexto(Carpeta);
                    Nombre := Carpeta;
                    Accion := Accion::"Crear Carpeta";
                    DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
                    if Carpeta <> '' then begin
                        case DataStorageProvider of
                            DataStorageProvider::"Google Drive":
                                begin
                                    If CarpetaAnterior[Indice] = '' then
                                        GoogleDrive.CreateFolder(Carpeta, CarpetaPrincipal, false)
                                    else
                                        GoogleDrive.CreateFolder(Carpeta, root, false);
                                end;
                            DataStorageProvider::OneDrive:
                                begin
                                    If CarpetaAnterior[Indice] = '' then
                                        OneDrive.CreateOneDriveFolder(Carpeta, CarpetaPrincipal, false)
                                    else
                                        OneDrive.CreateOneDriveFolder(Carpeta, root, false);

                                end;
                            DataStorageProvider::DropBox:
                                begin
                                    If CarpetaAnterior[Indice] = '' then
                                        DropBox.CreateFolder(Carpeta, CarpetaPrincipal, false)
                                    else
                                        DropBox.CreateFolder(Carpeta, root, false);
                                end;
                            DataStorageProvider::Strapi:
                                begin
                                    If CarpetaAnterior[Indice] = '' then
                                        Strapi.CreateFolder(Carpeta, CarpetaPrincipal, false)
                                    else
                                        Strapi.CreateFolder(Carpeta, root, false);
                                end;
                            DataStorageProvider::SharePoint:
                                begin
                                    If CarpetaAnterior[Indice] = '' then
                                        SharePoint.CreateSharePointFolder(Carpeta, CarpetaPrincipal, false)
                                    else
                                        SharePoint.CreateSharePointFolder(Carpeta, root, false);
                                end;
                        end;
                        Message(FolderCreatedSuccessfullyMsg, Carpeta);
                    end;

                    Recargar(root, CarpetaAnterior[Indice], Indice, GRecRef);
                end;
            }
            action(Delete)
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Delete',
                            ESP = 'Borrar';
                Image = Delete;
                Visible = not Mueve;
                Scope = Repeater;
                trigger OnAction()
                var
                    Doc: Record "Document Attachment";
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::Borrar;
                    If Rec.Value = 'Carpeta' then
                        DeleteFolder(Rec."Google Drive ID", false)
                    else begin
                        DeleteFile(Rec."Google Drive ID");
                        Doc.SetRange("Google Drive ID", Rec."Google Drive ID");
                        If Doc.FindFirst Then
                            Doc.Delete;
                    end;
                    Recargar(root, CarpetaAnterior[Indice], Indice, GRecRef);
                end;
            }
            action("Upload File")
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Upload File',
                            ESP = 'Subir Archivo';
                Image = Import;
                Visible = (not Mueve);
                trigger OnAction()
                var
                    NVInStream: InStream;
                    Filename: Text;
                    FileExtension: Text;
                    FileMgt: Codeunit "File Management";
                    Id: Text;
                    Doc: Record "Document Attachment";
                    a: Integer;
                    FolderMapping: Record "Google Drive Folder Mapping";
                    DataStorageProvider: Enum "Data Storage Provider";
                    DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
                    Folder: Text;
                    SubFolder: Text;
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    SharePointManager: Codeunit "SharePoint Manager";
                    Path: Text;
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::"Subir Archivo";
                    Rec.Value := 'Carpeta';
                    UPLOADINTOSTREAM('Import', '', ' All Files (*.*)|*.*', Filename, NVInStream);
                    FileExtension := FileMgt.GetExtension(FileName);
                    Id := GoogleDrive.UploadFileB64(root, NVInStream, Filename, FileExtension);
                    DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
                    case DataStorageProvider of
                        DataStorageProvider::"Google Drive":
                            begin
                                Id := GoogleDrive.UploadFileB64(root, NVInStream, Filename, FileExtension);
                            end;
                        DataStorageProvider::OneDrive:
                            begin
                                Path := OneDriveManager.OptenerPath(Rec."Google Drive ID");
                                Id := OneDriveManager.UploadFileB64(Path, NVInStream, FileName, FileExtension);
                            end;
                        DataStorageProvider::DropBox:
                            begin
                                Path := DropBoxManager.OptenerPath(Rec."Google Drive ID");
                                Id := DropBoxManager.UploadFileB64(Path, NVInStream, FileName + FileExtension);
                            end;
                        DataStorageProvider::Strapi:
                            begin
                                Id := StrapiManager.UploadFileB64(Path, NVInStream, FileName + FileExtension);
                            end;
                        DataStorageProvider::SharePoint:
                            begin
                                Id := SharePointManager.UploadFileB64(Path, NVInStream, FileName, FileExtension);
                            end;
                    end;

                    Doc.SetRange("Table ID", GRecRef.Number);
                    If Doc.Findlast Then a := Doc.ID + 1;
                    Doc.InitFieldsFromRecRef(GRecRef);
                    Doc.ID := a;
                    Doc."Google Drive ID" := Id;
                    doc."File Name" := Filename;
                    doc."File Extension" := FileExtension;
                    Doc."Store in Google Drive" := true;
                    Doc.Insert();
                    Recargar(root, CarpetaAnterior[Indice], Indice, GRecRef);
                end;
            }
        }
    }

    var
        GoogleDrive: Codeunit "Google Drive Manager";
        OneDrive: Codeunit "OneDrive Manager";
        DropBox: Codeunit "DropBox Manager";
        Strapi: Codeunit "Strapi Manager";
        SharePoint: Codeunit "SharePoint Manager";
        Base64Txt: Text;
        CarpetaAnterior: array[10] of Text;
        Indice: Integer;
        CarpetaPrincipal: Text;
        root: Text;
        Nombre: Text;
        Accion: Option " ","Descargar Archivo",Anterior,Mover,"Crear Carpeta",Borrar,"Subir Archivo","Copiar";
        Mueve: Boolean;
        Stilo: Text;
        Archivo: Boolean;
        GRecRef: Recordref;
        NoRootLevelErr: Label 'Cannot go up to previous level, you are at the root level for this record.';
        NoDestinationSelectedErr: Label 'No destination selected.';
        FolderCreatedSuccessfullyMsg: Label 'Folder "%1" created successfully.';

    procedure SetRecords(FolderId: Text; var Files: Record "Name/Value Buffer" temporary)
    begin
        Rec.Copy(Files, true);
        root := FolderId;
        Indice := 1;
        CarpetaPrincipal := FolderId;
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec.Value = 'Carpeta' then
            Stilo := 'Strong'
        else
            Stilo := 'Standard';

    end;

    procedure GetSelectionFilter(var Files: Record "Name/Value Buffer" temporary)
    begin
        Files.Copy(Rec, true);
    end;

    procedure Recargar(FolderId: Text; ParentId: Text; IndiceActual: Integer; RecRef: RecordRef)
    var
        Files: Record "Name/Value Buffer" temporary;
        DataStorageProvider: Enum "Data Storage Provider";
        DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
        RootFolder: Text;
        i: Integer;
    begin
        GRecRef := RecRef;
        if FolderId = '' then FolderId := CarpetaPrincipal;
        GoogleDrive.Carpetas(FolderId, Files);
        Rec.DeleteAll();
        RootFolder := DocAttachmentMgmtGDrive.GetRootFolder();
        // Agregar la carpeta ".." al inicio
        Rec.Init();
        Rec.ID := -99;
        Rec.Name := '..';
        Rec.Value := 'Carpeta';
        Rec."Google Drive ID" := FolderId;
        Rec."Google Drive Parent ID" := ParentId;
        Rec.Insert();

        // Copiar el resto de los archivos y carpetas
        if Files.FindSet() then
            repeat
                Rec.Init();
                Rec := Files;
                Rec.Insert();
            until Files.Next() = 0;

        Indice := IndiceActual;
        root := FolderId;
        CarpetaAnterior[Indice] := ParentId;
        if Indice = 1 then
            CarpetaPrincipal := FolderId;
        if Rec.FindLast() then
            rec.FindFirst();
        CurrPage.Update(false);

    end;

    procedure DeleteFile(Id: Text)
    var
        GoogleDrive: Codeunit "Google Drive Manager";
        DataStorageProvider: Enum "Data Storage Provider";
        DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        SharePointManager: Codeunit "SharePoint Manager";
    begin
        DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
        case DataStorageProvider of
            DataStorageProvider::"Google Drive":
                GoogleDrive.DeleteFile(Id);
            DataStorageProvider::OneDrive:
                OneDriveManager.DeleteFile(Id);
            DataStorageProvider::DropBox:
                DropBoxManager.DeleteFile(Id);
            DataStorageProvider::Strapi:
                StrapiManager.DeleteFile(Id);
            DataStorageProvider::SharePoint:
                SharePointManager.DeleteFile(Id);
        end;
    end;

    procedure DeleteFolder(Id: Text; HideDialog: Boolean)
    var
        GoogleDrive: Codeunit "Google Drive Manager";
        DataStorageProvider: Enum "Data Storage Provider";
        DocAttachmentMgmtGDrive: Codeunit "Doc. Attachment Mgmt. GDrive";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        SharePointManager: Codeunit "SharePoint Manager";
    begin
        DataStorageProvider := DocAttachmentMgmtGDrive.GetDataStorageProvider();
        case DataStorageProvider of
            DataStorageProvider::"Google Drive":
                GoogleDrive.DeleteFolder(Id, HideDialog);
            DataStorageProvider::OneDrive:
                OneDriveManager.DeleteFolder(Id, HideDialog);
            DataStorageProvider::DropBox:
                DropBoxManager.DeleteFolder(Id, HideDialog);
            DataStorageProvider::Strapi:
                StrapiManager.DeleteFolder(Id, HideDialog);
            DataStorageProvider::SharePoint:
                SharePointManager.DeleteFolder(Id, HideDialog);
        end;
    end;
}
