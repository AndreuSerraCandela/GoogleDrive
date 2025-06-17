page 95120 "Google Drive Manual Viewer"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Manual de Google Drive';
    Editable = false;

    layout
    {
        area(Content)
        {
            group(FastTabGroup)
            {
                ShowCaption = false;

                field(ManualContent; ManualContent)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ShowCaption = false;
                    ExtendedDatatype = RichContent;

                    //RichText = true;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        GoogleDriveManualMgt: Codeunit "Google Drive Manual Mgt";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
    begin
        GoogleDriveManualMgt.GetManualContent(TempBlob);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(ManualContent);
    end;

    var
        ManualContent: Text;
}