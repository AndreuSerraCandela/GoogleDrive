tableextension 95103 "Incoming Doc. Attachment Ext" extends "Incoming Document Attachment"
{
    fields
    {
        field(95100; "URL"; Text[2048])
        {
            ObsoleteState = Removed;
            
            Caption = 'Storage URL';
            DataClassification = CustomerContent;
            ToolTip = 'URL del archivo en el almacenamiento (Google Drive, OneDrive, etc.) una vez creado el Document Attachment.';
        }
    }
}
