codeunit 50100 "Google Drive Manager"
{
    // Codeunit to handle Google Drive operations

    var
        SecretKey: Text;
        ClientId: Text;
        TenantId: Text;
        RedirectURL: Text;
        OAuth2: Codeunit OAuth2;
        AuthCodeURL: Text;
        AccessToken: Text;
        GoogleDriveBaseURL: Label 'https://www.googleapis.com/drive/v3';
        GoogleDriveUploadURL: Label 'https://www.googleapis.com/upload/drive/v3/files';
        get_metadata: Label 'files/';
        create_folder: Label 'files';
        move_folder: Label 'files/';
        sharefolder: Label 'permissions';
        list_folder: Label 'files';
        delete: Label 'files/';
        grant_type_authorization_code: Label 'authorization_code';
        grant_type_refresh_token: Label 'refresh_token';
        oauth2_token: Label 'oauth2/v4/token';
        get_temporary_link: Label 'files/';
        Upload: Label 'upload/drive/v3/files';
        JObjectPDFToMerge: JsonObject;
        JArrayPDFToMerge: JsonArray;
        JObjectPDF: JsonObject;
        JnodeEntryToken: JsonToken;
        JsonEntry: JsonObject;
        JnodeProertiesToken: JsonToken;
        JsonProperties: JsonObject;
        JnodevsignToken: JsonToken;
        Base64Txt: Text;
        origen: Text;
        root: Text;
        origenfinal: Text;
        tipofinal: Text;

    procedure Initialize()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.GET();
        ClientId := CompanyInfo."Google Client ID";
        SecretKey := CompanyInfo."Google Client Secret";
        RedirectURL := 'https://businesscentral.dynamics.com/OAuthLanding.htm';
    end;

    procedure Authenticate(): Boolean
    var
        AuthUrl: Text;
        Scopes: List of [Text];
        ResponseJson: JsonObject;
        JToken: JsonToken;
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        ContentText: Text;
        ContentHeaders: HttpHeaders;
        AuthSuccess: Boolean;
    begin
        // Add necessary scopes for Google Drive
        Scopes.Add('https://www.googleapis.com/auth/drive.file');

        // This is a simplified authentication flow
        // Real implementation should handle OAuth flow properly

        // For demo purposes, assuming we already have a token
        AccessToken := 'demo-access-token';
        exit(true);
    end;

    procedure UploadFile(var DocumentAttachment: Record "Document Attachment"; TempBlob: Codeunit "Temp Blob"): Boolean
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        ContentText: Text;
        ResponseText: Text;
        JResponse: JsonObject;
        JToken: JsonToken;
        FileId: Text;
        FileName: Text;
        InStream: InStream;
        FileSize: Integer;
        URL: Text;
        RequestHeaders: HttpHeaders;
        CrLf: Text;
    begin
        CrLf := FORMAT(13) + FORMAT(10);
        if not Authenticate() then
            exit(false);

        // Get file data from TempBlob
        TempBlob.CreateInStream(InStream);
        FileSize := TempBlob.Length();
        FileName := DocumentAttachment."File Name";

        // Prepare the upload request
        Request.Method := 'POST';
        URL := StrSubstNo('%1?uploadType=multipart', GoogleDriveUploadURL);
        Request.SetRequestUri(URL);

        Request.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', StrSubstNo('Bearer %1', AccessToken));

        // Set up multipart content
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'multipart/related; boundary=boundary_123456');

        // Prepare multipart body
        ContentText := '--boundary_123456' + CrLf;
        ContentText += 'Content-Type: application/json; charset=UTF-8' + CrLf + CrLf;
        ContentText += '{ "name": "' + FileName + '" }' + CrLf;
        ContentText += '--boundary_123456' + CrLf;
        ContentText += 'Content-Type: ' + Format(DocumentAttachment."File Type") + CrLf + CrLf;

        // In a real implementation, you would append the file data to the ContentText
        // For this demo, we'll simulate it

        ContentText += '[FILE DATA WOULD BE HERE]' + CrLf;
        ContentText += '--boundary_123456--';

        Content.WriteFrom(ContentText);
        Request.Content := Content;

        // In a real implementation, send the request and handle the response
        // Client.Send(Request, Response);
        // Response.Content.ReadAs(ResponseText);

        // Parse the response to get the file ID and URL
        // JResponse.ReadFrom(ResponseText);
        // JResponse.Get('id', JToken);
        // FileId := JToken.AsValue().AsText();

        // For demo purposes:
        FileId := 'demo-file-id-123456';

        // Update the Document Attachment record with the Google Drive URL
        DocumentAttachment."Google Drive URL" := StrSubstNo('https://drive.google.com/file/d/%1/view', FileId);
        DocumentAttachment."Store in Google Drive" := true;
        DocumentAttachment.Modify();

        exit(true);
    end;

    procedure DownloadFile(var DocumentAttachment: Record "Document Attachment"; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        FileId: Text;
        URL: Text;
        RequestHeaders: HttpHeaders;
        OutStream: OutStream;
    begin
        if not DocumentAttachment."Store in Google Drive" then
            exit(false);

        if not Authenticate() then
            exit(false);

        // Extract file ID from URL
        // In a real implementation, you would parse the Google Drive URL to get the file ID
        FileId := ExtractFileIdFromUrl(DocumentAttachment."Google Drive URL");

        // Prepare the download request
        Request.Method := 'GET';
        URL := StrSubstNo('%1/%2?alt=media', GoogleDriveBaseURL, FileId);
        Request.SetRequestUri(URL);

        Request.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', StrSubstNo('Bearer %1', AccessToken));

        // In a real implementation, send the request and handle the response
        // Client.Send(Request, Response);
        // TempBlob.CreateOutStream(OutStream);
        // Response.Content.ReadAs(OutStream);

        // For demo purposes, we'll simulate success
        exit(true);
    end;

    procedure ExtractFileIdFromUrl(GoogleDriveUrl: Text): Text
    var
        Pos: Integer;
        FileId: Text;
    begin
        // Example URL: https://drive.google.com/file/d/FILE_ID/view
        Pos := StrPos(GoogleDriveUrl, '/d/');
        if Pos > 0 then begin
            FileId := CopyStr(GoogleDriveUrl, Pos + 3);
            Pos := StrPos(FileId, '/');
            if Pos > 0 then
                FileId := CopyStr(FileId, 1, Pos - 1);
        end;

        exit(FileId);
    end;

    local procedure GetSecretKey(): Text
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.GET();
        exit(CompanyInfo."Google Client Secret");
    end;

    local procedure GetClientId(): Text
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.GET();
        exit(CompanyInfo."Google Client ID");
    end;

    local procedure GetTenantId(): Text
    begin
        // Not needed for Google OAuth2
        exit('');
    end;

    local procedure GetRedirectURL(): Text
    begin
        exit('https://businesscentral.dynamics.com/OAuthLanding.htm');
    end;

    procedure Token(): Text
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.ChangeCompany('Malla Publicidad');
        CompanyInfo.GET();
        if CompanyInfo."Fecha Expiracion Token GoogleDrive" < CurrentDateTime then
            RefreshToken();
        Commit();
        CompanyInfo.GET();
        exit(CompanyInfo.GetTokenGoogleDrive());
    end;

    local procedure RefreshToken()
    var
        CompanyInfo: Record "Company Information";
        Client: HttpClient;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        JObject: JsonObject;
        JToken: JsonToken;
    begin
        CompanyInfo.GET();
        RequestContent.WriteFrom(StrSubstNo('client_id=%1&client_secret=%2&refresh_token=%3&grant_type=refresh_token',
            ClientId, SecretKey, CompanyInfo.GetRefreshTokenGoogleDrive()));

        Client.Post('https://oauth2.googleapis.com/token', RequestContent, ResponseMessage);
        ResponseMessage.Content().ReadAs(ResponseText);

        JObject.ReadFrom(ResponseText);
        JObject.Get('access_token', JToken);

        CompanyInfo.SetTokenGoogleDrive(JToken.AsValue().AsText());
        CompanyInfo."Fecha Expiracion Token GoogleDrive" := CurrentDateTime + 3600; // 1 hour
        CompanyInfo.Modify();
    end;

    procedure Carpetas(Carpeta: Text; Var Files: Record "Name/Value Buffer" temporary)
    var
        CompanyInfo: Record "Company Information";
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Inf: Record "Company Information";
        Url: Text;
        Json: Text;
        Body: JsonObject;
        StatusInfo: JsonObject;
        Respuesta: Text;
        GoogleDrive: Codeunit "Google Drive Manager";
        JTokO: JsonToken;
        JTok: JsonToken;
        JEntries: JsonArray;
        JEntry: JsonObject;
        JEntryToken: JsonToken;
        JEntryTokens: JsonToken;
        tag: Text;
        Cursor: Text;
        HasMore: Boolean;
        a: Integer;
    begin
        Files.DeleteAll();
        Ticket := GoogleDrive.Token();
        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + list_folder;

        Clear(Body);
        Body.add('q', StrSubstNo('''%1'' in parents and trashed = false', Carpeta));
        Body.add('fields', 'files(id, name, mimeType)');
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, Json);
        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        If StatusInfo.Get('files', JTok) Then begin
            JEntries := JTok.AsArray();
            foreach JEntryTokens in JEntries do begin
                JEntry := JEntryTokens.AsObject();
                If JEntry.Get('mimeType', JEntryToken) Then begin
                    tag := JEntryToken.AsValue().AsText();
                end;

                if JEntry.Get('name', JEntryToken) then begin
                    if tag = 'application/vnd.google-apps.folder' then begin
                        Files.Init();
                        a += 1;
                        Files.ID := a;
                        Files.Name := JEntryToken.AsValue().AsText();
                        Files.Value := 'Carpeta';
                        Files.Insert();
                    end else begin
                        Files.Init();
                        a += 1;
                        Files.ID := a;
                        Files.Name := JEntryToken.AsValue().AsText();
                        Files.Value := '';
                        Files.Insert();
                    end;
                end;
            end;
        end;
    end;

    procedure CreateFolder(Carpeta: Text): Text
    var
        GoogleDrive: Codeunit "Google Drive Manager";
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Inf: Record "Company Information";
        Url: Text;
        Json: Text;
        Body: JsonObject;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokO: JsonToken;
        JTok: JsonToken;
        Id: Text;
    begin
        Ticket := GoogleDrive.Token();
        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + create_folder;

        Body.Add('name', Carpeta);
        Body.add('mimeType', 'application/vnd.google-apps.folder');
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);
        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        If StatusInfo.Get('id', JnodeEntryToken) Then begin
            Id := JnodeEntryToken.AsValue().AsText();
        end;

        if Id = '' then begin
            if StatusInfo.Get('error', JTokO) then begin
                Error(JTokO.AsValue().AsText());
            end;
            Error('Error al crear la carpeta');
        end;

        exit(Id);
    end;

    procedure UploadFileB64(Carpeta: Text; Base64Data: InStream; Filename: Text): Text
    var
        Inf: Record "Company Information";
        RequestType: Option Get,patch,put,post,;
        Ticket: Text;
        GoogleDrive: Codeunit "Google Drive Manager";
        Url: Text;
        Body: JsonObject;
        Json: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Respuesta: Text;
        Id: Text;
    begin
        Inf.Get;
        Ticket := GoogleDrive.Token();
        Url := Inf."Url Api GoogleDrive" + Upload;

        Body.Add('name', Filename);
        if Carpeta <> '' then
            Body.Add('parents', Carpeta);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Base64Data);
        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        If StatusInfo.Get('id', JTokenLink) Then begin
            Id := JTokenLink.AsValue().AsText();
        end else
            error(Respuesta);

        exit(Id);
    end;

    procedure DeleteFolder(Carpeta: Text; HideDialog: Boolean): Text
    var
        GoogleDrive: Codeunit "Google Drive Manager";
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Inf: Record "Company Information";
        Url: Text;
        Json: Text;
        Body: JsonObject;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokO: JsonToken;
        JTok: JsonToken;
        Id: Text;
    begin
        If Not HideDialog Then
            If Not Confirm('¿Está seguro de que desea eliminar la carpeta?', true) Then
                exit('');

        Ticket := GoogleDrive.Token();
        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + delete + Carpeta;

        Respuesta := RestApiToken(Url, Ticket, RequestType::delete, Json);
        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        If StatusInfo.Get('id', JTokO) Then begin
            Id := JTokO.AsValue().AsText();
        end;

        if Id = '' then begin
            if StatusInfo.Get('error', JTok) then begin
                Error(JTok.AsValue().AsText());
            end;
            Error('Error al eliminar la carpeta');
        end;

        exit(Id);
    end;

    procedure RestApiToken(url: Text; Token: Text; RequestType: Option Get,patch,put,post,delete; payload: Text): Text
    var
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        RequestMessage: HttpRequestMessage;
        ResponseText: Text;
        contentHeaders: HttpHeaders;
    begin
        RequestHeaders := Client.DefaultRequestHeaders();
        RequestHeaders.Add('Authorization', StrSubstNo('Bearer %1', token));

        case RequestType of
            RequestType::Get:
                Client.Get(URL, ResponseMessage);
            RequestType::post:
                begin
                    RequestContent.WriteFrom(payload);
                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/json');
                    Client.Post(URL, RequestContent, ResponseMessage);
                end;
            RequestType::delete:
                Client.Delete(URL, ResponseMessage);
        end;

        ResponseMessage.Content().ReadAs(ResponseText);
        exit(ResponseText);
    end;

    procedure RestApiToken(url: Text; Token: Text; RequestType: Option Get,patch,put,post,delete; payload: InStream): Text
    var
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        contentHeaders: HttpHeaders;
    begin
        RequestHeaders := Client.DefaultRequestHeaders();
        RequestHeaders.Add('Authorization', StrSubstNo('Bearer %1', token));

        case RequestType of
            RequestType::post:
                begin
                    RequestContent.WriteFrom(payload);
                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/octet-stream');
                    Client.Post(URL, RequestContent, ResponseMessage);
                end;
        end;

        ResponseMessage.Content().ReadAs(ResponseText);
        exit(ResponseText);
    end;
}