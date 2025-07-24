tableextension 95100 "Doc. Attachment GoogleDrive" extends "Document Attachment"
{
    fields
    {
        field(95100; "Google Drive URL"; Text[2048])
        {
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

        // Campo para identificar el proveedor de almacenamiento
        field(95103; "Storage Provider"; Enum "Data Storage Provider")
        {
            Caption = 'Storage Provider';
            DataClassification = CustomerContent;
        }

        // Campos para OneDrive
        field(95104; "OneDrive ID"; Text[250])
        {
            Caption = 'OneDrive ID';
            DataClassification = CustomerContent;
        }
        field(95105; "OneDrive URL"; Text[2048])
        {
            Caption = 'OneDrive URL';
            DataClassification = CustomerContent;
        }
        field(95106; "Store in OneDrive"; Boolean)
        {
            Caption = 'Store in OneDrive';
            DataClassification = CustomerContent;
            InitValue = false;
        }

        // Campos para DropBox
        field(95107; "DropBox ID"; Text[250])
        {
            Caption = 'DropBox ID';
            DataClassification = CustomerContent;
        }
        field(95108; "DropBox URL"; Text[2048])
        {
            Caption = 'DropBox URL';
            DataClassification = CustomerContent;
        }
        field(95109; "Store in DropBox"; Boolean)
        {
            Caption = 'Store in DropBox';
            DataClassification = CustomerContent;
            InitValue = false;
        }

        // Campos para Strapi
        field(95110; "Strapi ID"; Text[250])
        {
            Caption = 'Strapi ID';
            DataClassification = CustomerContent;
        }
        field(95111; "Strapi URL"; Text[2048])
        {
            Caption = 'Strapi URL';
            DataClassification = CustomerContent;
        }
        field(95112; "Store in Strapi"; Boolean)
        {
            Caption = 'Store in Strapi';
            DataClassification = CustomerContent;
            InitValue = false;
        }
        field(95113; "Store in SharePoint"; Boolean)
        {
            Caption = 'Store in SharePoint';
            DataClassification = CustomerContent;
            InitValue = false;
        }
        field(95114; "SharePoint ID"; Text[250])
        {
            Caption = 'SharePoint ID';
            DataClassification = CustomerContent;
        }
        field(95115; "Posted Document"; Boolean)
        {
            Caption = 'Posted Document';
            DataClassification = CustomerContent;
            InitValue = false;
        }
        field(95116; "Moved Document"; Boolean)
        {
            Caption = 'Moved Document';
            DataClassification = CustomerContent;
            InitValue = false;
        }


        // Campo genérico para URL del documento

    }

    procedure Url(): Text[2048]
    var
        GoogleDrive: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
    begin
        case Rec."Storage Provider" of
            Rec."Storage Provider"::"Google Drive":
                exit(GoogleDrive.GetUrl(Rec."Google Drive ID"));
            Rec."Storage Provider"::OneDrive:
                exit(OneDriveManager.GetUrl(Rec."OneDrive ID"));
            Rec."Storage Provider"::DropBox:
                exit(DropBoxManager.GetUrl(Rec."DropBox ID"));
            Rec."Storage Provider"::Strapi:
                exit(StrapiManager.GetUrl(Rec."Strapi ID"));
            else
                exit('');
        end;
    end;

    procedure ToBase64StringOcr(bUrl: Text; var Base64: Text; Filename: Text; Origen: Enum "Data Storage Provider"): Boolean
    var
        GeneralLedgerSetup: Record 98;
        JsonObj: JsonObject;
        Json: Text;
        RestapiC: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        RequestType: Option Get,patch,put,post,delete;
        base64Token: JsonToken;

    begin
        case Origen of
            Origen::"Google Drive":
                if RestapiC.DownloadFileB64(bUrl, base64, false, base64) then
                    exit(true);
            Origen::OneDrive:
                if OneDriveManager.DownloadFileB64(bUrl, base64, false, base64) then
                    exit(true);
            Origen::DropBox:
                if DropBoxManager.DownloadFileB64(bUrl, base64, false, base64) then
                    exit(true);
            Origen::Strapi:
                if StrapiManager.DownloadFileB64(bUrl, base64, Filename, false) <> '' then
                    exit(true);
            else
                exit(false);
        end;
    end;

    procedure GetDocumentID(): Text
    begin
        case Rec."Storage Provider" of
            Rec."Storage Provider"::"Google Drive":
                exit(Rec."Google Drive ID");
            Rec."Storage Provider"::OneDrive:
                exit(Rec."OneDrive ID");
            Rec."Storage Provider"::DropBox:
                exit(Rec."DropBox ID");
            Rec."Storage Provider"::Strapi:
                exit(Rec."Strapi ID");
            else
                exit('');
        end;
    end;

    procedure SetDocumentID(DocumentID: Text)
    begin
        case Rec."Storage Provider" of
            Rec."Storage Provider"::"Google Drive":
                Rec."Google Drive ID" := DocumentID;
            Rec."Storage Provider"::OneDrive:
                Rec."OneDrive ID" := DocumentID;
            Rec."Storage Provider"::DropBox:
                Rec."DropBox ID" := DocumentID;
            Rec."Storage Provider"::Strapi:
                Rec."Strapi ID" := DocumentID;

        end;
    end;

    procedure GetDocumentURL(): Text
    begin
        case Rec."Storage Provider" of
            Rec."Storage Provider"::"Google Drive":
                exit(Rec."Google Drive URL");
            Rec."Storage Provider"::OneDrive:
                exit(Rec."OneDrive URL");
            Rec."Storage Provider"::DropBox:
                exit(Rec."DropBox URL");
            Rec."Storage Provider"::Strapi:
                exit(Rec."Strapi URL");
            else
                exit('');
        end;
    end;

    procedure SetDocumentURL(DocumentURL: Text)
    begin
        case Rec."Storage Provider" of
            Rec."Storage Provider"::"Google Drive":
                Rec."Google Drive URL" := DocumentURL;
            Rec."Storage Provider"::OneDrive:
                Rec."OneDrive URL" := DocumentURL;
            Rec."Storage Provider"::DropBox:
                Rec."DropBox URL" := DocumentURL;
            Rec."Storage Provider"::Strapi:
                Rec."Strapi URL" := DocumentURL;

        end;
    end;

    procedure IsStoredInProvider(): Boolean
    begin
        case Rec."Storage Provider" of
            Rec."Storage Provider"::"Google Drive":
                exit(Rec."Store in Google Drive");
            Rec."Storage Provider"::OneDrive:
                exit(Rec."Store in OneDrive");
            Rec."Storage Provider"::DropBox:
                exit(Rec."Store in DropBox");
            Rec."Storage Provider"::Strapi:
                exit(Rec."Store in Strapi");
            else
                exit(false);
        end;
    end;

    procedure FormBase64ToUrl(Base64: text; Filename: Text; var Id: Integer) ReturnValue: Text
    VAR
        Outstr: OutStream;
        GeneralLedgerSetup: Record 98;
        Token: Text;
        JsonObj: JsonObject;
        UrlToken: JsonToken;
        RequestType: Option Get,patch,put,post,delete;
        FileMgt: Codeunit "File Management";
        Json: Text;
        IdToken: JsonToken;
        Ok: Boolean;
        Url: Text;
    begin
        GeneralLedgerSetup.Get();
        case FileMgt.GetExtension(Filename) of
            'jpg', 'png', 'bmp', 'tif':
                Base64 := 'image/' + FileMgt.GetExtension(Filename) + ';base64,' + Base64;
            else
                Base64 := 'application/' + FileMgt.GetExtension(Filename) + ';base64,' + Base64;
        end;

        Repeat

            JsonObj.add('base64', base64);
            jsonobj.add('filename', filename);
            JsonObj.WriteTo(Json);
            Json := RestApi('https://base64-api.deploy.malla.es/save', RequestType::Post, Json);
            Clear(JsonObj);
            Ok := JsonObj.ReadFrom(Json);
            if not Ok then
                sleep(5000);
        Until Ok;
        JsonObj.Get('url', UrlToken);
        JsonObj.Get('_id', IdToken);
        Url := UrlToken.AsValue().AsText;
        Id := IdToken.AsValue().AsInteger;
        exit(url);
    end;

    procedure DeleteBase64(Id: Integer)
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        Url: Text;
        RequestType: Option Get,patch,put,post,delete;
    begin
        Url := 'https://base64-api.deploy.malla.es/delete/' + Format(Id);
        RestApi(Url, RequestType::Delete, '');
    end;

    procedure RestApi(url: Text; RequestType: Option Get,patch,put,post,delete; payload: Text): Text
    var
        Ok: Boolean;
        Respuesta: Text;
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        contentHeaders: HttpHeaders;
        ResponseText: Text;
    begin
        RequestHeaders := Client.DefaultRequestHeaders();
        //RequestHeaders.Add('Authorization', CreateBasicAuthHeader(Username, Password));

        case RequestType of
            RequestType::Get:
                Client.Get(URL, ResponseMessage);
            RequestType::patch:
                begin
                    RequestContent.WriteFrom(payload);

                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/json-patch+json');

                    RequestMessage.Content := RequestContent;

                    RequestMessage.SetRequestUri(URL);
                    RequestMessage.Method := 'PATCH';

                    client.Send(RequestMessage, ResponseMessage);
                end;
            RequestType::post:
                begin
                    RequestContent.WriteFrom(payload);

                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/json');

                    Client.Post(URL, RequestContent, ResponseMessage);
                end;
            RequestType::delete:
                begin


                    Client.Delete(URL, ResponseMessage);
                end;
        end;

        ResponseMessage.Content().ReadAs(ResponseText);
        exit(ResponseText);

    end;


}