page 95100 "Google Drive Factbox"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    DeleteAllowed = false;

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
                        a: Integer;
                    begin
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
                                GoogleDriveManager.OpenFileInBrowser(Rec."Google Drive ID");
                                Recargar(root, CarpetaAnterior[Indice], Indice, GRecRef);
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
            action("Descargar Archivo")
            {
                ApplicationArea = All;
                Scope = Repeater;
                Visible = (Archivo and Not Mueve);
                Image = Download;
                trigger OnAction()
                var
                    Base64Txt: Text;
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::"Descargar Archivo";
                    Base64Txt := GoogleDrive.DownloadFileB64(Rec."Google Drive ID", Rec.Name, true);
                    Recargar(root, CarpetaAnterior[Indice], Indice, GRecRef);
                end;
            }
            action("M&over")
            {
                Caption = 'Mover';
                ApplicationArea = All;
                Visible = Not Mueve;
                Scope = Repeater;
                Image = Change;
                trigger OnAction()
                var
                    destino: Text;
                    TempFiles: Record "Name/Value Buffer" temporary;
                    GoogleDriveList: Page "Google Drive List";
                    Inf: Record "Company Information";
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::Mover;


                    // Get folder list
                    Inf.Get();
                    GoogleDrive.ListFolder(Inf."Google Drive Root Folder ID", TempFiles, false);
                    GoogleDriveList.SetRecords(Inf."Google Drive Root Folder ID", TempFiles, true);
                    GoogleDriveList.RunModal();
                    GoogleDriveList.GetDestino(destino);
                    // Here we would need to implement a folder selection dialog using TempFiles
                    // For now, we'll use a placeholder solution

                    if destino = '' then
                        Message('no ha elegido destino')
                    else begin
                        If Rec.Value = 'Carpeta' then
                            GoogleDrive.MoveFolder(Rec."Google Drive ID", destino)
                        else
                            GoogleDrive.Movefile(Rec."Google Drive ID", Destino, root);
                        Recargar(root, CarpetaAnterior[Indice], Indice, GRecRef);
                    end;
                end;
            }
            action("Copiar Archivo")
            {
                ApplicationArea = All;
                Image = Copy;
                Visible = not Mueve;
                Scope = Repeater;
                trigger OnAction()
                var
                    destino: Text;
                    TempFiles: Record "Name/Value Buffer" temporary;
                    GoogleDriveList: Page "Google Drive List";
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::Copiar;
                    // Get folder list
                    GoogleDrive.ListFolder(root, TempFiles, false);
                    GoogleDriveList.SetRecords(root, TempFiles, true);
                    GoogleDriveList.RunModal();
                    GoogleDriveList.GetDestino(destino);
                    // Here we would need to implement a folder selection dialog using TempFiles
                    // For now, we'll use a placeholder solution
                    if destino = '' then
                        Message('no ha elegido destino')
                    else begin
                        GoogleDrive.CopyFile(Rec."Google Drive ID", destino);
                        Recargar(root, CarpetaAnterior[Indice], Indice, GRecRef);
                    end;
                end;
            }
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
                begin
                    Ventana.SetTexto('Nombre Carpeta');
                    Ventana.RunModal();
                    Ventana.GetTexto(Carpeta);
                    Nombre := Carpeta;
                    Accion := Accion::"Crear Carpeta";
                    If CarpetaAnterior[Indice] = '' then
                        GoogleDrive.CreateFolder(Carpeta, CarpetaPrincipal, false)
                    else
                        GoogleDrive.CreateFolder(Carpeta, root, false);
                    Recargar(root, CarpetaAnterior[Indice], Indice, GRecRef);
                end;
            }
            action(Borrar)
            {
                ApplicationArea = All;
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
                        GoogleDrive.DeleteFolder(Rec."Google Drive ID", false)
                    else begin
                        GoogleDrive.DeleteFile(Rec."Google Drive ID");
                        Doc.SetRange("Google Drive ID", Rec."Google Drive ID");
                        If Doc.FindFirst Then
                            Doc.Delete;
                    end;
                    Recargar(root, CarpetaAnterior[Indice], Indice, GRecRef);
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
                    Id: Text;
                    Doc: Record "Document Attachment";
                    a: Integer;
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::"Subir Archivo";
                    Rec.Value := 'Carpeta';
                    UPLOADINTOSTREAM('Import', '', ' All Files (*.*)|*.*', Filename, NVInStream);
                    FileExtension := FileMgt.GetExtension(FileName);
                    Id := GoogleDrive.UploadFileB64(root, NVInStream, Filename, FileExtension);
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
        Inf: Record "Company Information";
        RootFolder: Text;
        i: Integer;
    begin
        GRecRef := RecRef;
        if FolderId = '' then FolderId := CarpetaPrincipal;
        GoogleDrive.Carpetas(FolderId, Files);
        Rec.DeleteAll();
        Inf.Get();
        RootFolder := Inf."Google Drive Root Folder";
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
}