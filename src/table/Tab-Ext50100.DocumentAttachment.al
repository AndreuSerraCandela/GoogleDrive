tableextension 95100 "Doc. Attachment GoogleDrive" extends "Document Attachment"
{
    fields
    {
        field(95100; "Google Drive URL"; Text[2048])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'No se utiliza';
            Caption = 'Google Drive URL';
            DataClassification = CustomerContent;
        }
        field(95101; "Store in Google Drive"; Boolean)
        {
            Caption = 'Store in Google Drive';
            DataClassification = CustomerContent;
            InitValue = false;
        }
        field(95102; "Google Drive ID"; Text[250])
        {
            Caption = 'Google Drive ID';
            DataClassification = CustomerContent;
        }
    }
    procedure Url(): Text[2048]
    var
        GogleeDive: Codeunit "Google Drive Manager";
    begin
        exit(GogleeDive.GetUrl(Rec."Google Drive ID"));
    end;

    procedure ToBase64StringOcr(bUrl: Text): Text
    var
        GeneralLedgerSetup: Record 98;
        JsonObj: JsonObject;
        Json: Text;
        RestapiC: Codeunit "Google Drive Manager";
        RequestType: Option Get,patch,put,post,delete;
        base64Token: JsonToken;
        base64: Text;
    begin
        exit(RestapiC.DownloadFileB64(bUrl, base64, false));


    end;


}