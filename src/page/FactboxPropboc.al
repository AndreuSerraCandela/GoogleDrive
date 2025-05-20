page 50102 "Google Drive Factbox"
{
    Caption = 'Google Drive';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1000)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    StyleExpr = Carpetas;
                    trigger OnAssistEdit()
                    var
                        Base64Txt: Text;
                        Barra: Integer;
                        UltimaBarra: Text;
                    begin
                        Nombre := Rec.Name;
                        If Nombre = '..' Then begin
                            Accion := Accion::Anterior;
                            Rec.Value := 'Carpeta';
                            If (root = CarpetaPrincipal) Or (root = '/' + CarpetaPrincipal) Or
                                ('/' + root = CarpetaPrincipal) then
                                exit;
                            Rec.Name := root;
                            root := CarpetaPrincipal;
                            If StrPos(Rec.Name, '/') > 0 then begin
                                repeat
                                    Barra += 1;

                                    UltimaBarra := CopyStr(Rec.Name, barra);

                                until StrPos(UltimaBarra, '/') = 0;
                                Rec.Name := CopyStr(Rec.Name, 1, barra - 2);
                            end;
                            root := Rec.Name;
                            if StrLen(root) = 0 then
                                root := '/'
                            else if Copystr(root, 1, 1) <> '/' then
                                root := '/' + root;

                            Recargar(Copystr(root, 2));
                        end else begin
                            if Rec.Value = 'Carpeta' then begin
                                Accion := Accion::" ";
                                if StrLen(root) = 0 then
                                    root := '/'
                                else if Copystr(root, 1, 1) <> '/' then
                                    root := '/' + root;
                                If root = '/' then
                                    root := root + Rec.Name
                                else
                                    root := root + '/' + Rec.Name;
                                Recargar(Copystr(root, 2));

                            end else begin
                                Accion := Accion::"Descargar Archivo";
                                if StrLen(root) = 0 then
                                    root := '/'
                                else if Copystr(root, 1, 1) <> '/' then
                                    root := '/' + root;
                                GoogleDrive.DowloadFileB64(Copystr(root, 2), Base64Txt, Rec.Name, true);
                                Recargar(Copystr(root, 2));

                            end;
                        end;
                    end;
                }
                field(Tipo; Rec.Value)
                {
                    Caption = 'Tipo';
                    Visible = false;
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the value.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            // action("Seleccionar")
            // {
            //     ApplicationArea = All;
            //     Visible = (Not Mueve);
            //     Image = SelectChart;
            //     Scope=Repeater;
            //     trigger OnAction()
            //     begin
            //         Nombre := Rec.Name;
            //         Accion := Accion::"Seleccionar";
            //         CurrPage.Close();
            //     end;
            // }
            action("Anterior")
            {
                ApplicationArea = All;
                Visible = true;
                Image = PreviousRecord;
                Scope = Repeater;
                trigger OnAction()
                var
                    Barra: Integer;
                    UltimaBarra: Text;
                begin
                    Nombre := 'Anterior';
                    Rec.Value := 'Carpeta';
                    Accion := Accion::Anterior;
                    if not Mueve then
                        Accion := Accion::Anterior;
                    If (root = CarpetaPrincipal) Or (root = '/' + CarpetaPrincipal) Or
                        ('/' + root = CarpetaPrincipal) then
                        exit;
                    Rec.Name := root;
                    root := CarpetaPrincipal;
                    If StrPos(Rec.Name, '/') > 0 then begin
                        repeat
                            Barra += 1;

                            UltimaBarra := CopyStr(Rec.Name, barra);

                        until StrPos(UltimaBarra, '/') = 0;
                        Rec.Name := CopyStr(Rec.Name, 1, barra - 2);
                    end;
                    root := Rec.Name;
                    if StrLen(root) = 0 then
                        root := '/'
                    else if Copystr(root, 1, 1) <> '/' then
                        root := '/' + root;
                    Recargar(Copystr(root, 2));
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
                    if StrLen(root) = 0 then
                        root := '/'
                    else if Copystr(root, 1, 1) <> '/' then
                        root := '/' + root;
                    Google Drive.DowloadFileB64(Copystr(root, 2), Base64Txt, Rec.Name, true);
                    Recargar(Copystr(root, 2));
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
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::Mover;
                    if StrLen(root) = 0 then
                        root := '/'
                    else if Copystr(root, 1, 1) <> '/' then
                        root := '/' + root;
                    destino := Google Drive.ListFolder(Copystr(root, 2), Accion::Mover, Rec.Value, false);
                    if destino = '-' then
                        Message('no ha elegido destino')
                    else begin
                        If Rec.Value = 'Carpeta' then
                            Google Drive.MoveFolder(CopyStr(root, 2) + '/' + Rec.Name, destino + '/' + Rec.Name)
                        else
                        Google Drive.Movefile(Copystr(root, 2), Destino, Rec.Name);
                        root := destino;
                        Recargar(Copystr(root, 2));
                    end;
                end;
            }
            // action("Seleccionar Destino")
            // {
            //     ApplicationArea = All;
            //     Visible = Mueve;
            //     Image = Select;
            //     trigger OnAction()
            //     begin
            //         Nombre := Rec.Name;
            //         Accion := Accion::"Seleccionar Destino";
            //         Mueve := False;
            //         //Rec.Value := 'Seleccionada';
            //         CurrPage.Close();
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
                begin
                    Ventana.SetTexto('Nombre Carpeta');
                    Ventana.RunModal();
                    Ventana.GetTexto(Carpeta);
                    Nombre := Carpeta;
                    Accion := Accion::"Crear Carpeta";
                    if StrLen(root) = 0 then
                        root := '/'
                    else if Copystr(root, 1, 1) <> '/' then
                        root := '/' + root;
                    GoogleDrive.CreateFolder(Copystr(root, 2) + '/' + Carpeta);
                    Recargar(Copystr(root, 2));
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
                    if StrLen(root) = 0 then
                        root := '/'
                    else if Copystr(root, 1, 1) <> '/' then
                        root := '/' + root;
                    GoogleDrive.DeleteFolder(Copystr(root, 2) + '/' + Rec.Name, false);
                    Recargar(Copystr(root, 2));
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
                begin
                    Nombre := Rec.Name;
                    Accion := Accion::"Subir Archivo";
                    Rec.Value := 'Carpeta';
                    if StrLen(root) = 0 then
                        root := '/'
                    else if Copystr(root, 1, 1) <> '/' then
                        root := '/' + root;
                    UPLOADINTOSTREAM('Import', '', ' All Files (*.*)|*.*', Filename, NVInStream);
                    GoogleDrive.UploadFileB64(Copystr(root, 2), NVInStream, Filename);
                    Recargar(Copystr(root, 2));
                end;
            }
        }
        // area(Promoted)
        // {
        //     actionref(Seleccionar_Ref; "Seleccionar") { }
        //     actionref(Anterior_Ref; Anterior) { }
        //     actionref(Mover_Ref; "Mover") { }
        //     actionref(DescargarArchivo_Ref; "Descargar Archivo") { }
        //     actionref(CrearCarpeta_Ref; "Crear Carpeta") { }
        //     actionref(Borrar_Ref; Borrar) { }
        //     actionref(SubirArchivo_Ref; "Subir Archivo") { }

        //     // actionref(SeleccionarDestino_Ref; "Seleccionar Destino") { }
        // }
    }
    procedure Navegar(root: Text)
    begin
        Caption := root;
        Acciones := True;
        Nombre := '-';
    end;

    var
        Acciones: Boolean;
        GoogleDrive: Codeunit "Google Drive Manager";
        Nombre: Text;
        Carpeta: Boolean;
        Archivo: Boolean;
        Mueve: Boolean;
        Accion: Option " ","Seleccionar","Anterior","Descargar Archivo","Mover","Crear Carpeta",Borrar,"Subir Archivo";
        root: Text;
        CarpetaPrincipal: Text;
        Carpetas: Text;
        CarpetaPrincipalSeteada: Boolean;

    Procedure GetNombre(Var Nom: Text; Var Valor: Text; Var pAccion: Option "  ","Seleccionar","Anterior","Descargar Archivo","Mover","Crear Carpeta",Borrar,"Subir Archivo")
    begin
        Nom := Nombre;
        If Accion in [Accion::Anterior, Accion::"Crear Carpeta"] then
            Valor := 'Carpeta'
        else
            Valor := Rec.Value;
        // if Mueve then
        //   pAccion := Accion::Mover;
        pAccion := Accion;
    end;

    trigger OnAfterGetRecord()
    begin

        if Rec.Value = 'Carpeta' then begin
            Carpeta := True;
            Carpetas := 'StrongAccent';
            Archivo := False;
        end
        else begin
            Carpeta := False;
            Carpetas := 'Standard';
            Archivo := True;
        end;

    end;

    procedure Mover()
    begin
        Mueve := True;
        Rec.SetRange(Value, 'Carpeta');
    end;

    procedure AddItem(ItemName: Text[250]; ItemValue: Text[250])
    var
        NextID: Integer;
    begin
        Rec.LockTable();
        Rec.SetCurrentKey("ID");
        if Rec.FindLast() then
            NextID := Rec.ID + 1
        else
            NextID := 1;

        Rec.Init();
        Rec.ID := NextID;
        Rec.Name := ItemName;
        Rec.Value := ItemValue;
        If Rec.Insert() Then;
    end;

    procedure Recargar(Carpeta: Text)
    var
        Tipo: Text;
        Accion: Option " ","Seleccionar","Anterior","Descargar Archivo","Mover","Seleccionar Destino","Crear Carpeta",Borrar,"Subir Archivo",Base64;
        Pfiles: Record "Name/Value Buffer" temporary;
    begin
        if not CarpetaPrincipalSeteada then begin
            CarpetaPrincipal := Carpeta;
            CarpetaPrincipalSeteada := true;
        end;
        root := Carpeta;
        Google Drive.Carpetas(Carpeta, Pfiles);
        Rec.Reset();
        Rec.DeleteAll();
        Pfiles.Reset();
        Rec.ID := -99;
        Rec.Value := 'Carpeta';
        Rec.Name := '..';
        If Rec.Insert() Then;
        if Pfiles.FindSet() then
            repeat
                If Rec.Get(Pfiles.ID) then begin
                    Rec.Name := Pfiles.Name;
                    Rec.Value := Pfiles.Value;
                end else begin
                    Rec.Init();
                    Rec := Pfiles;
                    if Rec.Insert() Then;
                end;
            until Pfiles.Next() = 0;
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;


}