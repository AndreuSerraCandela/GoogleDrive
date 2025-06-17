
/// <summary>
/// ControlAddIn Visor.
/// </summary>
controladdin PDFViewer
{
    StartupScript = 'Scripts/startup.js';
    Scripts = 'Scripts/script.js';

    HorizontalStretch = true;
    HorizontalShrink = true;
    MinimumWidth = 350;

    /// <summary>
    /// OnControlAddInReady.
    /// </summary>
    event OnControlAddInReady();
    /// <summary>
    /// OnPdfViewerReady.
    /// </summary>
    event OnPdfViewerReady();
    procedure InitializeControl(url: Text);
    procedure LoadDocument(data: JsonObject);
}