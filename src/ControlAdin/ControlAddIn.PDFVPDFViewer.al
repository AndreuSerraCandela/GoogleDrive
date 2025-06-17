/// <summary>
/// ControlAddIn PDFV PDF Viewer.
/// </summary>
controladdin "PDFV PDF Viewer"
{
    Scripts = 'https://ajax.aspnetcdn.com/ajax/jQuery/jquery-3.3.1.min.js', 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.8.335/pdf.min.js', 'JavaScript/script.js';
    StartupScript = 'JavaScript/Startup.js';
    StyleSheets = 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.2.0/css/all.min.css', 'JavaScript/stylesheet.css';


    MinimumHeight = 1;
    MinimumWidth = 1;
    MaximumHeight = 2000;
    HorizontalStretch = true;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalShrink = true;
    /// <summary>
    /// ControlAddinReady.
    /// </summary>
    event ControlAddinReady();
    /// <summary>
    /// onView.
    /// </summary>
    event onView()
    /// <summary>
    /// OnSiguiente.
    /// </summary>
    event OnSiguiente()
    /// <summary>
    /// OnAnterior.
    /// </summary>
    event OnAnterior()
    /// <summary>
    /// OnPrint.
    /// </summary>
    //event OnPrint();
    /// <summary>
    /// OnDowload.
    /// </summary>
    event OnDownload();
    procedure LoadPDF(PDFDocument: Text; IsFactbox: Boolean)
    procedure LoadOtros(PDFDocument: Text; IsFactbox: Boolean)
    procedure Fichero(Numero: Integer)
    procedure Ficheros(NumerodeFicheros: Integer)
    procedure SetVisible(IsVisible: Boolean)
}