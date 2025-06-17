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
                    begin
                        Nombre := Rec.Name;
                        If Nombre = '..' Then begin
                            // Subir al nivel anterior
                            Accion := Accion::Anterior;
                            Indice := Indice - 1;
                            if Indice < 1 then
                                Indice := 1;
                            Rec.Value := 'Carpeta';
                            Rec."Google Drive ID" := root;
                            if Indice = 1 then
                                Recargar(CarpetaAnterior[Indice + 1], CarpetaAnterior[Indice], Indice)
                            else
                                Recargar(CarpetaAnterior[Indice], CarpetaAnterior[Indice - 1], Indice - 1);
                        end else begin
                            if Rec.Value = 'Carpeta' then begin
                                // Navegar a la subcarpeta
                                Accion := Accion::" ";
                                Indice := Indice + 1;
                                Recargar(Rec."Google Drive ID", Rec."Google Drive Parent ID", Indice);
                            end else begin
                                // Descargar archivo
                                Accion := Accion::"Descargar Archivo";
                                Base64Txt := GoogleDrive.DownloadFileB64(Rec."Google Drive ID", Rec.Name, true);
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
                    Base64Txt: Text;
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::"Descargar Archivo";
                    Base64Txt := GoogleDrive.DownloadFileB64(Rec."Google Drive ID", Rec.Name, true);
                    Recargar(root, CarpetaAnterior[Indice], Indice);
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
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::Mover;


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
                        If Rec.Value = 'Carpeta' then
                            GoogleDrive.MoveFolder(Rec."Google Drive ID", destino)
                        else
                            GoogleDrive.Movefile(Rec."Google Drive ID", Destino, root);
                        Recargar(root, CarpetaAnterior[Indice], Indice);
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
                        Recargar(root, CarpetaAnterior[Indice], Indice);
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
                        GoogleDrive.DeleteFolder(Rec."Google Drive ID", false)
                    else
                        GoogleDrive.DeleteFile(Rec."Google Drive ID");
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
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::"Subir Archivo";
                    Rec.Value := 'Carpeta';
                    UPLOADINTOSTREAM('Import', '', ' All Files (*.*)|*.*', Filename, NVInStream);
                    FileExtension := FileMgt.GetExtension(FileName);
                    GoogleDrive.UploadFileB64(root, NVInStream, Filename, FileExtension);
                    Recargar(root, CarpetaAnterior[Indice], Indice);
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
        wdestino: Text;
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
    begin
        GoogleDrive.Carpetas(FolderId, Files);
        Rec.DeleteAll();

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

    internal procedure GetDestino(var destino: Text)
    begin
        destino := wdestino;
    end;
}