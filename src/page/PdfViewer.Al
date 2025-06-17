page 95143 "Pdf Viewer"
{
    PageType = List;


    layout
    {
        area(Content)
        {
            usercontrol(PDFViewer; PDFViewer)
            {
                ApplicationArea = All;
                trigger OnControlAddInReady()
                begin
                    InitializePDFViewer();
                end;

                trigger OnPdfViewerReady()
                begin
                    ControlIsReady := true;
                    ShowData();
                end;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Ver)
            {
                Caption = 'Ver';
                ApplicationArea = ALL;
                Image = Find;
                trigger OnAction()
                begin
                    ShowData();

                end;
            }
        }

    }
    var
        ControlIsReady: Boolean;
        Data: JsonObject;
        ContentType: Option URL,BASE64;
        Content: Text;


    trigger OnAfterGetRecord()
    begin

        ShowData();
    end;

    local procedure InitializePDFViewer()
    var
        PDFViewerUrlTxt: Label 'https://bcpdfviewer.z6.web.core.windows.net/web/viewer.html?file=', Locked = true;
    begin
        CurrPage.PDFViewer.InitializeControl(PDFViewerUrlTxt);
    end;

    local procedure ShowData()
    begin
        if Content = '' then
            exit;

        Clear(Data);
        Data.Add('type', Format(ContentType));
        Data.Add('content', Content);

        CurrPage.PDFViewer.LoadDocument(Data);

        Clear(Data);
    end;

    /// <summary>
    /// LoadPdfViaUrl.
    /// </summary>
    /// <param name="Url">Text.</param>
    procedure LoadPdfViaUrl(Url: Text)
    begin
        ContentType := ContentType::URL;
        Content := Url;
    end;

    /// <summary>
    /// LoadPdfFromBlob.
    /// </summary>
    /// <param name="Base64Data">Text.</param>
    procedure LoadPdfFromBlob(Base64Data: Text)
    begin
        Clear(Data);
        Data.Add('type', 'base64');
        Data.Add('content', Base64Data);
        ContentType := ContentType::BASE64;
        Content := Base64Data;

    end;

    /// <summary>
    /// Next_PreviosDocumennt.
    /// </summary>
    /// <param name="Direction">Option Previos,Next.</param>


}