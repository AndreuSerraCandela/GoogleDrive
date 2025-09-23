/// <summary>
/// ControlAddIn OcrFirmas.
/// </summary>
controladdin OcrFirmas
{
    StartupScript = 'Scripts/startupOcr.js';
    Scripts = 'Scripts/wobocr.js';

    HorizontalStretch = true;
    HorizontalShrink = true;
    VerticalShrink = true;
    VerticalStretch = true;
    //MinimumWidth = 600;


    /// <summary>
    /// OnControlAddInReady.
    /// </summary>
    event OnControlAddInReady();
    procedure InitializeControl(url: Text);
}