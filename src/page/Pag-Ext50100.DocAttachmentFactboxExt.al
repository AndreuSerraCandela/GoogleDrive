pageextension 50100 "Doc. Attachment Factbox Ext" extends "Document Attachment Factbox"
{
    layout
    {
        addlast(Content)
        {
            field("Store in Google Drive"; Rec."Store in Google Drive")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether the attachment should be stored in Google Drive instead of in the database.';
                Caption = 'Store in Google Drive';
                Editable = true;
            }
            field("Google Drive URL"; Rec."Google Drive URL")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the URL to the file in Google Drive.';
                Caption = 'Google Drive URL';
                Editable = false;
                Visible = Rec."Store in Google Drive";

                trigger OnDrillDown()
                begin
                    if Rec."Google Drive URL" <> '' then
                        Hyperlink(Rec."Google Drive URL");
                end;
            }
        }
    }

    actions
    {
        // No action modifications needed
    }

    // Add triggers
    trigger OnOpenPage()
    var
        GoogleDriveManager: Codeunit "Google Drive Manager";
    begin
        // Initialize Google Drive Manager when the page opens
        GoogleDriveManager.Initialize();
    end;
}