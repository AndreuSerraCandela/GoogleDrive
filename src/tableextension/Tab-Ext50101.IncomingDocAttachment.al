tableextension 95103 "Incoming Doc. Attachment Ext" extends "Incoming Document Attachment"
{
    fields
    {
        field(95100; "URL"; Text[2048])
        {
            ObsoleteState = Removed;
            
            Caption = 'Storage URL';
            DataClassification = CustomerContent;
            ToolTip = 'URL of the file in storage (Google Drive, OneDrive, etc.) once the Document Attachment is created.';
        }
    }
}
