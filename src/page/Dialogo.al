/// <summary>
/// Page Dialogo (ID 50015).
/// </summary>
page 95101 "Dialogo Google Drive"
{
    Caption = 'Dialogo';
    PageType = StandardDialog;
    layout
    {
        area(content)
        {

            field(Caption; CaptionValue)
            {
                Editable = false;
                ApplicationArea = ALL;
                Visible = VerCaptionTexto;
                ShowCaption = false;
            }
            field(Date; DateValue)
            {
                ApplicationArea = ALL;
                Visible = VerFecha;
                Caption = 'Teclee fecha';
            }
            field(Date1; DateValue1)
            {
                ApplicationArea = ALL;
                Visible = VerFecha1;
                Caption = 'Teclee fecha';
            }
            field(Valor; ValorValue)
            {
                ApplicationArea = ALL;
                Visible = VerValor;
                Caption = 'Teclee valor';
            }
            field(Valor1; ValorValue1)
            {
                ApplicationArea = ALL;
                Visible = VerValor1;
                Caption = 'Teclee valor';
            }
            field(Texto; TextValue)
            {
                ApplicationArea = ALL;
                Visible = VerTexto;
            }


        }
    }
    var
        DateValue: Date;
        DateValue1: Date;
        ValorValue: Code[20];
        ValorValue1: Code[20];
        TextValue: Text;
        CaptionValue: Text;
        VerTexto: Boolean;
        VerFecha: Boolean;
        VerFecha1: Boolean;
        VerValor: Boolean;
        VerValor1: Boolean;
        VerCaptionTexto: Boolean;

    /// <summary>
    /// SetValues.
    /// </summary>
    /// <param name="Fecha">Date.</param>
    /// <param name="Texto">Text.</param>
    procedure SetValues(Fecha: Date; Texto: Text)
    begin
        DateValue := Fecha;
        TextValue := Texto;
        VerFecha := true;
        VerFecha1 := false;
        VerValor := false;
        VerValor1 := false;
        VerTexto := true;
        VerCaptionTexto := false;
    end;

    /// <summary>
    /// SetFecha.
    /// </summary>
    /// <param name="Fecha">Date.</param>
    /// <param name="Texto">Text.</param>
    procedure SetFecha(Fecha: Date; Texto: Text)
    begin
        DateValue := Fecha;
        CaptionValue := Texto;
        VerFecha := true;
        VerFecha1 := false;
        VerTexto := false;
        VerCaptionTexto := true;
        VerValor := false;
        VerValor1 := false;
    end;

    /// <summary>
    /// GetFecha.
    /// </summary>
    /// <param name="Fecha">VAR Date.</param>
    procedure GetFecha(var Fecha: Date)
    begin
        Fecha := DateValue;

    end;

    /// <summary>
    /// SetFechas.
    /// </summary>
    /// <param name="Desde">Date.</param>
    /// <param name="Hasta">Date.</param>
    /// <param name="Texto">Text.</param>
    procedure SetFechas(Desde: Date; Hasta: Date; Texto: Text)
    begin
        DateValue := Desde;
        DateValue1 := Hasta;
        CaptionValue := Texto;
        VerFecha := true;
        VerFecha1 := true;
        VerTexto := false;
        VerCaptionTexto := true;
        VerValor := false;
        VerValor1 := false;
    end;

    /// <summary>
    /// GetFechas.
    /// </summary>
    /// <param name="Desde">VAR Date.</param>
    /// <param name="Hasta">VAR Date.</param>
    procedure GetFechas(var Desde: Date; var Hasta: Date)
    begin
        Desde := DateValue;
        Hasta := DateValue1;

    end;

    /// <summary>
    /// SetCodes.
    /// </summary>
    /// <param name="Desde">Code[20].</param>
    /// <param name="Hasta">Code[20].</param>
    /// <param name="Texto">Text.</param>
    procedure SetCodes(Desde: Code[20]; Hasta: Code[20]; Texto: Text)
    begin
        ValorValue := Desde;
        ValorValue1 := Hasta;
        CaptionValue := Texto;
        VerFecha := false;
        VerFecha1 := false;
        VerTexto := false;
        VerCaptionTexto := true;
        VerValor := true;
        VerValor1 := true;
    end;

    /// <summary>
    /// SetTexto.
    /// </summary>
    /// <param name="Texto">Text.</param>
    procedure SetTexto(Texto: Text)
    begin
        ValorValue := '';
        ValorValue1 := '';
        CaptionValue := Texto;
        VerFecha := false;
        VerFecha1 := false;
        VerTexto := true;
        VerCaptionTexto := true;
        VerValor := false;
        VerValor1 := false;
    end;

    procedure SetTextValue(Texto: Text)
    begin
        TextValue := Texto;
    end;

    /// <summary>
    /// GetCodes.
    /// </summary>
    /// <param name="Desde">VAR Code[20].</param>
    /// <param name="Hasta">VAR Code[20].</param>
    procedure GetCodes(var Desde: Code[20]; var Hasta: Code[20])
    begin
        Desde := ValorValue;
        Hasta := ValorValue1;

    end;

    /// <summary>
    /// GetTexto.
    /// </summary>
    /// <param name="Texto">VAR Text.</param>
    procedure GetTexto(var Texto: Text)
    begin
        Texto := TextValue

    end;

    /// <summary>
    /// GetValues.
    /// </summary>
    /// <param name="Fecha">VAR Date.</param>
    /// <param name="Texto">VAR Text.</param>
    procedure GetValues(var Fecha: Date; var Texto: Text)
    begin
        Fecha := DateValue;
        Texto := TextValue;
    end;

}