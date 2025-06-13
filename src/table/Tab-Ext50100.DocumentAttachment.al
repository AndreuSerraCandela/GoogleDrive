tableextension 50100 "Doc. Attachment GoogleDrive" extends "Document Attachment"
{
    fields
    {
        field(50100; "Google Drive URL"; Text[2048])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'No se utiliza';
            Caption = 'Google Drive URL';
            DataClassification = CustomerContent;
        }
        field(50101; "Store in Google Drive"; Boolean)
        {
            Caption = 'Store in Google Drive';
            DataClassification = CustomerContent;
            InitValue = false;
        }
        field(50102; "Google Drive ID"; Text[250])
        {
            Caption = 'Google Drive ID';
            DataClassification = CustomerContent;
        }
    }
}