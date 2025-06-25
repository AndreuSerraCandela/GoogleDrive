page 95105 "Google Drive List"
{
    Caption = 'Google Drive';
    Editable = false;
    PageType = List;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Nombre';
                    DrillDown = true;
                    StyleExpr = Stilo;
                    trigger OnDrillDown()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                        OneDriveManager: Codeunit "OneDrive Manager";
                        DropBoxManager: Codeunit "DropBox Manager";
                        StrapiManager: Codeunit "Strapi Manager";
                        a: Integer;
                        Inf: Record "Company Information";
                    begin
                        Inf.Get();
                        Nombre := Rec.Name;
                        If Nombre = '..' Then begin
                            // Subir al nivel anterior
                            Accion := Accion::Anterior;
                            Indice := Indice - 1;
                            if Indice < 1 then begin
                                Indice := 1;
                                Message('No se puede subir al nivel anterior, esta en la raiz para esta ficha');
                            end;
                            Rec.Value := 'Carpeta';
                            Rec."Google Drive ID" := root;
                            a := Indice;
                            if Indice = 1 then
                                Recargar('', '', Indice)
                            else
                                Recargar(CarpetaAnterior[Indice], CarpetaAnterior[Indice - 1], Indice - 1);
                            Indice := a;
                        end else begin
                            if Rec.Value = 'Carpeta' then begin
                                // Navegar a la subcarpeta
                                Accion := Accion::" ";
                                Indice := Indice + 1;
                                Recargar(Rec."Google Drive ID", Rec."Google Drive Parent ID", Indice);
                            end else begin
                                // Descargar archivo
                                Accion := Accion::"Descargar Archivo";
                                //Base64Txt := GoogleDrive.DownloadFileB64(Rec."Google Drive ID", Rec.Name, true);
                                case Inf."Data Storage Provider" of
                                    Inf."Data Storage Provider"::"Google Drive":
                                        GoogleDriveManager.OpenFileInBrowser(Rec."Google Drive ID");
                                    Inf."Data Storage Provider"::OneDrive:
                                        OneDriveManager.OpenFileInBrowser(Rec."Google Drive ID");
                                    Inf."Data Storage Provider"::DropBox:
                                        DropBoxManager.OpenFileInBrowser(Rec."Google Drive ID");
                                    Inf."Data Storage Provider"::Strapi:
                                        StrapiManager.OpenFileInBrowser(Rec."Google Drive ID");
                                end;
                                Recargar(root, CarpetaAnterior[Indice], Indice);
                            end;
                        end;
                    end;
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Tipo';
                    Visible = false;
                }
                field("File Extension"; Rec."File Extension")
                {
                    ApplicationArea = All;
                    Caption = 'Extensión';
                    Visible = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Seleccionar")
            {
                ApplicationArea = All;
                Scope = Repeater;
                Visible = (Not arChivo and Mueve);
                Image = Select;
                trigger OnAction()
                begin
                    wdestino := Rec."Google Drive ID";
                    wNombre := Rec.Name;
                    CurrPage.Close();
                end;
            }
            action("Descargar Archivo")
            {
                ApplicationArea = All;
                Scope = Repeater;
                Visible = (Archivo and Not Mueve);
                Image = Download;
                trigger OnAction()
                var
                    Base64Data: Text;
                    TempBlob: Codeunit "Temp Blob";
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                    CompanyInfo: Record "Company Information";
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::"Descargar Archivo";
                    CompanyInfo.Get();
                    if CompanyInfo."Data Storage Provider" = CompanyInfo."Data Storage Provider"::"Google Drive" then begin
                        Base64Data := GoogleDriveManager.DownloadFileB64(Rec."Google Drive ID", Rec.Name, true);

                    end;
                    if CompanyInfo."Data Storage Provider" = CompanyInfo."Data Storage Provider"::OneDrive then begin
                        Base64Data := OneDriveManager.DownloadFileB64(Rec."Google Drive ID", Rec.Name, true);

                    end;
                    if CompanyInfo."Data Storage Provider" = CompanyInfo."Data Storage Provider"::DropBox then begin
                        Base64Data := DropBoxManager.DownloadFileB64('', Rec."Google Drive ID", Rec.Name, true);

                    end;
                    if CompanyInfo."Data Storage Provider" = CompanyInfo."Data Storage Provider"::Strapi then begin
                        Base64Data := StrapiManager.DownloadFileB64('', Rec."Google Drive ID", Rec.Name, true);
                    end;
                    Recargar(root, CarpetaAnterior[Indice], Indice);
                end;
            }
            // action("M&over")
            // {
            //     Caption = 'Mover';
            //     ApplicationArea = All;
            //     Visible = Not Mueve;
            //     Scope = Repeater;
            //     Image = Change;
            //     trigger OnAction()
            //     var
            //         destino: Text;
            //         TempFiles: Record "Name/Value Buffer" temporary;
            //         GoogleDriveList: Page "Google Drive List";
            //     begin
            //         Nombre := Rec.Name;
            //         Accion := Accion::Mover;


            //         // Get folder list
            //         GoogleDrive.ListFolder(root, TempFiles, false);
            //         GoogleDriveList.SetRecords(root, TempFiles, true);
            //         GoogleDriveList.RunModal();
            //         GoogleDriveList.GetDestino(destino);
            //         // Here we would need to implement a folder selection dialog using TempFiles
            //         // For now, we'll use a placeholder solution

            //         if destino = '' then
            //             Message('no ha elegido destino')
            //         else begin
            //             If Rec.Value = 'Carpeta' then
            //                 GoogleDrive.MoveFolder(Rec."Google Drive ID", destino)
            //             else
            //                 GoogleDrive.Movefile(Rec."Google Drive ID", Destino, root);
            //             Recargar(root, CarpetaAnterior[Indice], Indice);
            //         end;
            //     end;
            // }
            // action("Copiar Archivo")
            // {
            //     ApplicationArea = All;
            //     Image = Copy;
            //     Visible = not Mueve;
            //     Scope = Repeater;
            //     trigger OnAction()
            //     var
            //         destino: Text;
            //         TempFiles: Record "Name/Value Buffer" temporary;
            //         GoogleDriveList: Page "Google Drive List";
            //     begin
            //         Nombre := Rec.Name;
            //         Accion := Accion::Copiar;
            //         // Get folder list
            //         GoogleDrive.ListFolder(root, TempFiles, false);
            //         GoogleDriveList.SetRecords(root, TempFiles, true);
            //         GoogleDriveList.RunModal();
            //         GoogleDriveList.GetDestino(destino);
            //         // Here we would need to implement a folder selection dialog using TempFiles
            //         // For now, we'll use a placeholder solution
            //         if destino = '' then
            //             Message('no ha elegido destino')
            //         else begin
            //             GoogleDrive.CopyFile(Rec."Google Drive ID", destino);
            //             Recargar(root, CarpetaAnterior[Indice], Indice);
            //         end;
            //     end;
            // }
            action("Crear Carpeta")
            {
                ApplicationArea = All;
                Image = ToggleBreakpoint;
                Visible = not Mueve;
                Caption = 'Crear Carpeta';
                ToolTip = 'Crea una carpeta en Google Drive';
                trigger OnAction()
                var
                    DorpBox: Codeunit "Google Drive Manager";
                    Ventana: Page "Dialogo Google Drive";
                    Carpeta: Text;
                    Inf: Record "Company Information";
                begin
                    Ventana.SetTexto('Nombre Carpeta');
                    Ventana.RunModal();
                    Ventana.GetTexto(Carpeta);
                    Nombre := Carpeta;
                    Accion := Accion::"Crear Carpeta";
                    Inf.Get();
                    if Carpeta <> '' then begin
                        case Inf."Data Storage Provider" of
                            Inf."Data Storage Provider"::"Google Drive":
                                begin
                                    If CarpetaAnterior[Indice] = '' then
                                        GoogleDrive.CreateFolder(Carpeta, CarpetaPrincipal, false)
                                    else
                                        GoogleDrive.CreateFolder(Carpeta, root, false);
                                end;
                            Inf."Data Storage Provider"::OneDrive:
                                begin
                                    If CarpetaAnterior[Indice] = '' then
                                        OneDrive.CreateOneDriveFolder(Carpeta, CarpetaPrincipal, false)
                                    else
                                        OneDrive.CreateOneDriveFolder(Carpeta, root, false);

                                end;
                            Inf."Data Storage Provider"::DropBox:
                                begin
                                    If CarpetaAnterior[Indice] = '' then
                                        DropBox.CreateFolder(Carpeta, CarpetaPrincipal, false)
                                    else
                                        DropBox.CreateFolder(Carpeta, root, false);
                                end;
                            Inf."Data Storage Provider"::Strapi:
                                begin
                                    If CarpetaAnterior[Indice] = '' then
                                        Strapi.CreateFolder(Carpeta, CarpetaPrincipal, false)
                                    else
                                        Strapi.CreateFolder(Carpeta, root, false);
                                end;
                        end;
                        Message('Carpeta "%1" creada correctamente.', Carpeta);
                    end;
                    Recargar(root, CarpetaAnterior[Indice], Indice);
                end;
            }
            action(Borrar)
            {
                ApplicationArea = All;
                Image = Delete;
                Visible = not Mueve;
                Scope = Repeater;
                trigger OnAction()
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::Borrar;
                    If Rec.Value = 'Carpeta' then
                        DeleteFolder(Rec."Google Drive ID", false)
                    else
                        DeleteFile(Rec."Google Drive ID");
                    Recargar(root, CarpetaAnterior[Indice], Indice);
                end;
            }
            action("Subir Archivo")
            {
                ApplicationArea = All;
                Image = Import;
                Visible = (not Mueve);
                trigger OnAction()
                var
                    NVInStream: InStream;
                    Filename: Text;
                    FileExtension: Text;
                    FileMgt: Codeunit "File Management";
                    CompanyInfo: Record "Company Information";
                    Id: Text;
                    Path: Text;
                    OneDriveManager: Codeunit "OneDrive Manager";
                    DropBoxManager: Codeunit "DropBox Manager";
                    StrapiManager: Codeunit "Strapi Manager";
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::"Subir Archivo";
                    Rec.Value := 'Carpeta';
                    UPLOADINTOSTREAM('Import', '', ' All Files (*.*)|*.*', Filename, NVInStream);
                    FileExtension := FileMgt.GetExtension(FileName);
                    case CompanyInfo."Data Storage Provider" of
                        CompanyInfo."Data Storage Provider"::"Google Drive":
                            begin
                                Id := GoogleDrive.UploadFileB64(root, NVInStream, Filename, FileExtension);
                            end;
                        CompanyInfo.
                        "Data Storage Provider"::OneDrive:
                            begin
                                Path := OneDriveManager.OptenerPath(Rec."Google Drive ID");
                                Id := OneDriveManager.UploadFileB64(Path, NVInStream, FileName, FileExtension);
                            end;
                        CompanyInfo."Data Storage Provider"::DropBox:
                            begin
                                Path := DropBoxManager.OptenerPath(Rec."Google Drive ID");
                                Id := DropBoxManager.UploadFileB64(Path, NVInStream, FileName + FileExtension);
                            end;
                        CompanyInfo."Data Storage Provider"::Strapi:
                            begin
                                Id := StrapiManager.UploadFileB64(Path, NVInStream, FileName + FileExtension);
                            end;
                    end;
                    Recargar(root, CarpetaAnterior[Indice], Indice);
                end;
            }
        }
    }

    var
        GoogleDrive: Codeunit "Google Drive Manager";
        OneDrive: Codeunit "OneDrive Manager";
        DropBox: Codeunit "DropBox Manager";
        Strapi: Codeunit "Strapi Manager";
        Base64Txt: Text;
        CarpetaAnterior: array[10] of Text;
        Indice: Integer;
        CarpetaPrincipal: Text;
        root: Text;
        Nombre: Text;
        Accion: Option " ","Descargar Archivo",Anterior,Mover,"Crear Carpeta",Borrar,"Subir Archivo","Copiar";
        Mueve: Boolean;
        Stilo: Text;
        wdestino: Text;
        wNombre: Text;
        Archivo: Boolean;

    procedure SetRecords(FolderId: Text; var Files: Record "Name/Value Buffer" temporary; Moviendo: Boolean)
    begin
        Rec.Copy(Files, true);
        root := FolderId;
        Indice := 1;
        CarpetaPrincipal := FolderId;
        Mueve := Moviendo;
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

    procedure Recargar(FolderId: Text; ParentId: Text; IndiceActual: Integer)
    var
        Files: Record "Name/Value Buffer" temporary;
        Inf: Record "Company Information";
        RootFolder: Text;
        i: Integer;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
    begin
        Inf.Get();
        if FolderId = '' then FolderId := CarpetaPrincipal;
        case Inf."Data Storage Provider" of
            Inf."Data Storage Provider"::"Google Drive":
                GoogleDrive.Carpetas(FolderId, Files);
            Inf."Data Storage Provider"::OneDrive:
                OneDriveManager.ListFolder(FolderId, Files, true);
            Inf."Data Storage Provider"::DropBox:
                DropBoxManager.ListFolder(FolderId, Files, true);
            Inf."Data Storage Provider"::Strapi:
                StrapiManager.ListFolder(FolderId, Files, true);
        end;
        Rec.DeleteAll();
        Inf.Get();
        RootFolder := Inf."Root Folder";
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

    internal procedure GetDestino(var destino: Text; var nombre: Text)
    begin
        destino := wdestino;
        nombre := wNombre;
    end;

    procedure DeleteFile(Id: Text)
    var
        GoogleDrive: Codeunit "Google Drive Manager";
        Inf: Record "Company Information";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
    begin
        Inf.Get();
        case Inf."Data Storage Provider" of
            Inf."Data Storage Provider"::"Google Drive":
                GoogleDrive.DeleteFile(Id);
            Inf."Data Storage Provider"::OneDrive:
                OneDriveManager.DeleteFile(Id);
            Inf."Data Storage Provider"::DropBox:
                DropBoxManager.DeleteFile(Id);
            Inf."Data Storage Provider"::Strapi:
                StrapiManager.DeleteFile(Id);
        end;
    end;

    procedure DeleteFolder(Id: Text; HideDialog: Boolean)
    var
        GoogleDrive: Codeunit "Google Drive Manager";
        Inf: Record "Company Information";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
    begin
        Inf.Get();
        case Inf."Data Storage Provider" of
            Inf."Data Storage Provider"::"Google Drive":
                GoogleDrive.DeleteFolder(Id, HideDialog);
            Inf."Data Storage Provider"::OneDrive:
                OneDriveManager.DeleteFolder(Id, HideDialog);
            Inf."Data Storage Provider"::DropBox:
                DropBoxManager.DeleteFolder(Id, HideDialog);
            Inf."Data Storage Provider"::Strapi:
                StrapiManager.DeleteFolder(Id, HideDialog);
        end;
    end;
}