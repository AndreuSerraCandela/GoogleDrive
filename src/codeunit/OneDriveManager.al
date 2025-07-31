codeunit 95102 "OneDrive Manager"
{
    permissions = tabledata "Company Information" = RIMD,
                  tabledata "Document Attachment" = RIMD,
                  tabledata "Name/Value Buffer" = RIMD;

    var
        CompanyInfo: Record "Company Information";
        // Endpoints de OneDrive API
        auth_endpoint: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/authorize';
        token_endpoint: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token';
        graph_endpoint: Label 'https://graph.microsoft.com/v1.0';
        drive_endpoint: Label '/me/drive';
        files_endpoint: Label '/me/drive/root:/%1:/children';
        upload_endpoint: Label '/me/drive/root:/%1:/content';
        download_endpoint: Label '/me/drive/items/%1/content';
        create_folder_endpoint: Label '/me/drive/root:/%1:/children';
        delete_endpoint: Label '/me/drive/items/%1';
        move_endpoint: Label '/me/drive/items/%1/move';
        copy_endpoint: Label '/me/drive/items/%1/copy';
        sites_endpoint: Label '/sites';
        site_endpoint: Label '/sites/%1';
        shared_sites_endpoint: Label '/sites?search=%1';
        // Message Labels
        SharingDisabledMsg: Label 'Sharing is disabled on this site. Using direct file URL.';
        SharingDisabledOpenMsg: Label 'Sharing is disabled on this site. Opening direct file URL.';
        SharingDisabledErrorMsg: Label 'Sharing is disabled on this site and could not get direct URL. Contact administrator to enable sharing.';
        ShErrorMessage: Label 'Error accessing file: %1';
        FileLinkErrorMsg: Label 'Could not get file link. Check that the file ID is correct and you have permission to access it.';
        NoRefreshTokenMsg: Label 'No refresh token configured for OneDrive.';
        AuthenticationErrorMsg: Label 'Could not authenticate with OneDrive. Please verify your credentials.';
        FolderNotFoundMsg: Label 'Folder not found: %1';
        NoResponseMsg: Label 'No response received from OneDrive server.';
        CopyFileErrorMsg: Label 'Error copying file: %1. Complete response: %2';
        FileCopiedButNotDeletedMsg: Label 'File was copied but could not delete original. Copied file ID: %1';
        CopyFileFailedMsg: Label 'Could not copy file';
        GetFilePathErrorMsg: Label 'Could not get file path';
        SiteIdNotConfiguredMsg: Label 'OneDrive site ID is not configured. Please configure the site ID in the company.';
        CreateFolderErrorMsg: Label 'Failed to create folder in OneDrive: %1 with this URL: %2 and this JSON: %3';
        GetSiteErrorMsg: Label 'Error getting site: %1';
        GetSiteIdErrorMsg: Label 'Could not get site ID. Verify that the site URL is correct.';
        GetSiteByHostnameErrorMsg: Label 'Could not get site ID. Verify that the hostname and path are correct.';
        SearchSitesErrorMsg: Label 'Error searching sites: %1';
        GetSiteDriveErrorMsg: Label 'Error getting site drive: %1';
        GetSiteDriveIdErrorMsg: Label 'Could not get site drive ID. Verify that the site ID is correct.';
        UploadToSharedSiteErrorMsg: Label 'Error uploading file to shared site: %1';
        UploadToSharedSiteFolderErrorMsg: Label 'Error uploading file to shared site folder: %1';
        CreateFolderInSharedSiteErrorMsg: Label 'Error creating folder in shared site: %1 with this URL: %2 and this JSON: %3';
        // Confirmation Labels
        DeleteFolderConfirmMsg: Label 'Are you sure you want to delete the folder?';

        // Error Labels
        TokenRequestFailedErr: Label 'The request to the token endpoint failed.';
        TokenEndpointErrorErr: Label 'The token endpoint returned an error. Status: %1, Body: %2';
        NotAuthenticatedErr: Label 'Could not authenticate with OneDrive. Please verify your credentials.';
        NoServerResponseErr: Label 'No response received from OneDrive server.';
        FileAccessErrorErr: Label 'Error accessing file: %1';
        FileLinkErrorErr: Label 'Could not get file link. Verify that the file ID is correct and you have permission to access it.';
        CopyFileErrorErr: Label 'Error copying file: %1. Complete response: %2';
        FileCopiedButNotDeletedErr: Label 'File was copied but could not delete original. Copied file ID: %1';
        CopyFileFailedErr: Label 'Could not copy file';
        GetFilePathErrorErr: Label 'Could not get file path';
        CreateFolderErrorErr: Label 'Failed to create folder in OneDrive: %1 with this URL: %2 and this JSON: %3';
        GetSiteErrorErr: Label 'Error getting site: %1';

    procedure Initialize()
    begin
        CompanyInfo.Get();
    end;

    procedure Authenticate(): Boolean
    begin
        CompanyInfo.Get();
        CompanyInfo.CalcFields("OneDrive Access Token");
        // Verificar si el token está válido
        if not CompanyInfo."OneDrive Access Token".HasValue then
            StartOAuthFlow()
        else
            if CompanyInfo."OneDrive Token Expiration" < CurrentDateTime then
                RefreshAccessToken();

        exit(CompanyInfo."OneDrive Access Token".HasValue);
    end;

    procedure StartOAuthFlow()
    var
        OAuthURL: Text;
    //RedirectURI: Text;
    begin
        // Construir URL de autorización de OneDrive/Microsoft Graph
        //RedirectURI := 'https://businesscentral.dynamics.com/OAuthLanding.htm'; // Para aplicaciones de escritorio

        OAuthURL := StrSubstNo(auth_endpoint, CompanyInfo."OneDrive Tenant ID") +
                   '?client_id=' + CompanyInfo."OneDrive Client ID" +
                   '&response_type=code' +
                   '&scope=Files.ReadWrite.All%20offline_access' +
                   '&redirect_uri=https://login.microsoftonline.com/common/oauth2/nativeclient' +
                   '&state=12345' +
                   '&response_mode=query';

        // Abrir navegador o mostrar URL
        Hyperlink(OAuthURL);
    end;

    procedure RefreshAccessToken()
    var
        DriveTokenManagement: Record "Drive Token Management";
    begin
        If not DriveTokenManagement.Get(DriveTokenManagement."Storage Provider"::"OneDrive") then begin
            DriveTokenManagement.Init();
            DriveTokenManagement."Storage Provider" := DriveTokenManagement."Storage Provider"::"OneDrive";
            DriveTokenManagement.Insert();
        end;
        DriveTokenManagement.CalcFields("Access Token", "Refresh Token");
        if not DriveTokenManagement."Access Token".HasValue Then
            ObtenerToken(CompanyInfo."Code Ondrive", DriveTokenManagement);

        if not CompanyInfo."OneDrive Refresh Token".HasValue then
            Error(NoRefreshTokenMsg);

        RefreshToken();
    end;

    procedure ValidateConfiguration(): Boolean
    begin
        if CompanyInfo."OneDrive Client ID" = '' then
            exit(false);
        if CompanyInfo."OneDrive Client Secret" = '' then
            exit(false);
        if CompanyInfo."OneDrive Tenant ID" = '' then
            exit(false);
        CompanyInfo.CalcFields("OneDrive Access Token");
        if not CompanyInfo."OneDrive Access Token".HasValue then
            exit(false);

        exit(true);
    end;

    procedure GetUrl(DocumentID: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Json: Text;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokenLink: JsonToken;
        Inf: Record "Company Information";
        SiteId: Text;
    begin
        if DocumentID = '' then
            exit('');
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        if SiteId <> '' then
            exit(GetWebUrlSite(DocumentID, SiteId));

        Ticket := Format(Token());
        Url := graph_endpoint + download_endpoint;
        Url := StrSubstNo(Url, DocumentID);

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        // Para OneDrive, la respuesta directa es el contenido del archivo
        // Necesitamos obtener la URL de descarga web
        exit(GetWebUrl(DocumentID));
    end;

    procedure Token(): Text
    var
        AccessToken: Text;
        InStr: InStream;
    begin
        CompanyInfo.Get();
        if CompanyInfo."OneDrive Token Expiration" < CurrentDateTime then
            RefreshAccessToken();

        CompanyInfo.CalcFields("OneDrive Access Token");
        if CompanyInfo."OneDrive Access Token".HasValue then begin
            CompanyInfo."OneDrive Access Token".CreateInStream(InStr);
            InStr.ReadText(AccessToken);
        end;
        exit(AccessToken);
    end;

    procedure ObtenerToken(CodeOneDrive: Text; var DriveTokenManagement: Record "Drive Token Management"): Text
    var
        Url: Text;
        BodyText: Text;
        StatusInfo: JsonObject;
        JnodeEntryToken: JsonToken;
        Id: Text;
        RedirectURI: Text;
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        Headers: HttpHeaders;
        JsonText: Text;
        AccessToken: Text;
        RefreshToken: Text;
        OutStr: OutStream;
    begin
        CompanyInfo.Get();
        RedirectURI := 'https://login.microsoftonline.com/common/oauth2/nativeclient';
        Url := StrSubstNo(token_endpoint, CompanyInfo."OneDrive Tenant ID");

        BodyText := 'grant_type=authorization_code' +
                    '&code=' + UrlEncode(CodeOneDrive) +
                    '&redirect_uri=' + UrlEncode(RedirectURI) +
                    '&client_id=' + UrlEncode(CompanyInfo."OneDrive Client ID") +
                    '&client_secret=' + UrlEncode(CompanyInfo."OneDrive Client Secret") +
                    '&scope=' + UrlEncode('Files.ReadWrite.All offline_access');

        HttpContent.WriteFrom(BodyText);
        HttpContent.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        HttpRequest.SetRequestUri(Url);
        HttpRequest.Method('POST');
        HttpRequest.Content := HttpContent;

        if not HttpClient.Send(HttpRequest, HttpResponse) then
            Error(TokenRequestFailedErr);

        HttpResponse.Content().ReadAs(JsonText);
        if not HttpResponse.IsSuccessStatusCode() then
            Error(TokenEndpointErrorErr, HttpResponse.HttpStatusCode(), JsonText);

        StatusInfo.ReadFrom(JsonText);

        if StatusInfo.Get('refresh_token', JnodeEntryToken) then begin
            RefreshToken := JnodeEntryToken.AsValue().AsText();
            CompanyInfo."OneDrive Refresh Token".CreateOutStream(OutStr);
            DriveTokenManagement.SetRefreshToken(RefreshToken);
            OutStr.WriteText(RefreshToken);
        end;

        if StatusInfo.Get('access_token', JnodeEntryToken) then begin
            AccessToken := JnodeEntryToken.AsValue().AsText();
            CompanyInfo."OneDrive Access Token".CreateOutStream(OutStr);
            OutStr.WriteText(AccessToken);
            Id := AccessToken;
            DriveTokenManagement.SetAccessToken(AccessToken);
            if StatusInfo.Get('expires_in', JnodeEntryToken) then begin
                CompanyInfo."OneDrive Token Expiration" := CurrentDateTime + (JnodeEntryToken.AsValue().AsInteger() * 1000);
            end else begin
                CompanyInfo."OneDrive Token Expiration" := CurrentDateTime + 3600000; // 1 hora por defecto
            end;
        end;

        if CompanyInfo.WritePermission() then
            CompanyInfo.Modify();
        exit(Id);
    end;

    procedure RefreshToken(): Text
    var
        Url: Text;
        BodyText: Text;
        StatusInfo: JsonObject;
        JnodeEntryToken: JsonToken;
        Id: Text;
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        Headers: HttpHeaders;
        JsonText: Text;
        AccessToken: Text;
        RefreshToken: Text;
        OldRefreshToken: Text;
        OutStr: OutStream;
        InStr: InStream;
        DriveTokenManagement: Record "Drive Token Management";
    begin
        CompanyInfo.Get();
        If not DriveTokenManagement.Get(DriveTokenManagement."Storage Provider"::"OneDrive") then begin
            DriveTokenManagement.Init();
            DriveTokenManagement."Storage Provider" := DriveTokenManagement."Storage Provider"::"OneDrive";
            DriveTokenManagement.Insert();
        end;
        Url := StrSubstNo(token_endpoint, CompanyInfo."OneDrive Tenant ID");

        CompanyInfo.CalcFields("OneDrive Refresh Token");
        if CompanyInfo."OneDrive Refresh Token".HasValue then begin
            CompanyInfo."OneDrive Refresh Token".CreateInStream(InStr);
            InStr.ReadText(OldRefreshToken);
        end;

        BodyText := 'grant_type=refresh_token' +
                    '&refresh_token=' + UrlEncode(OldRefreshToken) +
                    '&client_id=' + UrlEncode(CompanyInfo."OneDrive Client ID") +
                    '&client_secret=' + UrlEncode(CompanyInfo."OneDrive Client Secret") +
                    '&scope=' + UrlEncode('Files.ReadWrite.All offline_access');

        HttpContent.WriteFrom(BodyText);
        HttpContent.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        HttpRequest.SetRequestUri(Url);
        HttpRequest.Method('POST');
        HttpRequest.Content := HttpContent;

        if not HttpClient.Send(HttpRequest, HttpResponse) then
            Error(TokenRequestFailedErr);

        HttpResponse.Content().ReadAs(JsonText);

        if not HttpResponse.IsSuccessStatusCode() then
            Error(TokenEndpointErrorErr, HttpResponse.HttpStatusCode(), JsonText);

        StatusInfo.ReadFrom(JsonText);

        if StatusInfo.Get('access_token', JnodeEntryToken) then begin
            AccessToken := JnodeEntryToken.AsValue().AsText();
            CompanyInfo."OneDrive Access Token".CreateOutStream(OutStr);
            OutStr.WriteText(AccessToken);
            Id := AccessToken;
            DriveTokenManagement.SetAccessToken(AccessToken);
            if StatusInfo.Get('expires_in', JnodeEntryToken) then begin
                CompanyInfo."OneDrive Token Expiration" := CurrentDateTime + (JnodeEntryToken.AsValue().AsInteger() * 1000);
            end else begin
                CompanyInfo."OneDrive Token Expiration" := CurrentDateTime + 3600000; // 1 hora por defecto
            end;

            if StatusInfo.Get('refresh_token', JnodeEntryToken) then begin
                RefreshToken := JnodeEntryToken.AsValue().AsText();
                CompanyInfo."OneDrive Refresh Token".CreateOutStream(OutStr);
                OutStr.WriteText(RefreshToken);
                DriveTokenManagement.SetRefreshToken(RefreshToken);
            end;
        end;
        if CompanyInfo.WritePermission() then
            CompanyInfo.Modify();
        exit(Id);
    end;

    procedure UploadFile(Carpeta: Text; var DocumentAttach: Record "Document Attachment"): Text
    var
        DocumentStream: OutStream;
        TempBlob: Codeunit "Temp Blob";
        Int: Instream;
        FileMang: Codeunit "File Management";
        Extension: Text;
    begin
        TempBlob.CreateOutStream(DocumentStream);
        DocumentAttach."Document Reference ID".ExportStream(DocumentStream);
        If DocumentAttach."File Extension" = '' then
            Extension := FileMang.GetExtension(DocumentAttach."File Name")
        else
            Extension := DocumentAttach."File Extension";
        TempBlob.CreateInStream(Int);

        exit(UploadFileB64(Carpeta, Int, DocumentAttach."File Name", Extension));
    end;


    procedure UploadFileB64(Carpeta: Text; Base64Data: InStream; Filename: Text; FileExtension: Text[30]): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Id: Text;
        Inf: Record "Company Information";
        SiteId: Text;
    begin
        Ticket := Format(Token());
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        if SiteId <> '' then
            exit(UploadFileB64ToSharedSite(SiteId, Carpeta, Base64Data, Filename, FileExtension));

        // Construir la ruta del archivo
        //https://graph.microsoft.com/v1.0/me/drive/root:/RUTA/CARPETA/archivo.txt:/content
        Url := graph_endpoint + upload_endpoint;
        Url := StrSubstNo(Url, Carpeta + Filename + '.' + FileExtension);
        //Falta Token
        Respuesta := RestApiOfset(Url, Ticket, RequestType::put, Base64Data);

        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('id', JTokenLink) then begin
            Id := JTokenLink.AsValue().AsText();
        end else
            Error(Respuesta);

        exit(Id);
    end;

    procedure DownloadFileB64(OneDriveID: Text[250]; FileName: Text; BajarFichero: Boolean; var Base64Data: Text): Boolean
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        Link: Text;
        ErrorMessage: Text;
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        Bs64: Codeunit "Base64 Convert";
        Inf: Record "Company Information";
        SiteId: Text;
    begin
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        if SiteId <> '' then
            exit(DownloadFileB64Site(OneDriveID, FileName, BajarFichero, Base64Data, SiteId));

        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        Url := StrSubstNo(graph_endpoint + '/me/drive/items/%1?select=id,name,webUrl,@microsoft.graph.downloadUrl', OneDriveID);

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta = '' then
            exit(false);

        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            exit(false);
        end;

        if StatusInfo.Get('@microsoft.graph.downloadUrl', JToken) then begin
            Link := JToken.AsValue().AsText();

            // Descargar el contenido del archivo
            TempBlob.CreateOutStream(OutStr);
            RestApiGetContentStream(Link, RequestType::get, InStr);

            // Convertir a base64
            Base64Data := Bs64.ToBase64(InStr);

            if BajarFichero then begin
                DownloadFromStream(InStr, SaveAsDialogTxt, 'C:\Temp', 'ALL Files (*.*)|*.*', FileName);
            end;

            exit(true);
        end else begin
            exit(false);
        end;
    end;

    procedure DeleteFolder(Carpeta: Text; HideDialog: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        Id: Text;
        Inf: Record "Company Information";
        SiteId: Text;
    begin
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        if SiteId <> '' then
            exit(DeleteFolderSite(Carpeta, HideDialog, SiteId));
        if not HideDialog then
            if not Confirm(DeleteFolderMsg, true) then
                exit('');

        Ticket := Format(Token());

        // Obtener el ID del archivo/carpeta
        Id := GetFileId(Carpeta);

        if Id = '' then
            Error(FolderNotFoundMsg, Carpeta);

        Url := graph_endpoint + delete_endpoint;
        Url := StrSubstNo(Url, Id);

        Respuesta := RestApiToken(Url, Ticket, RequestType::delete, '');

        exit(Id);
    end;

    local procedure GetFileId(FilePath: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Json: Text;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokenLink: JsonToken;
        Id: Text;
        Inf: Record "Company Information";
        SiteId: Text;
    begin
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        if SiteId <> '' then
            exit(GetFileIdSite(FilePath, SiteId));
        Ticket := Format(Token());

        // Obtener información del archivo
        Url := graph_endpoint + '/me/drive/root:/' + FilePath;

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('id', JTokenLink) then begin
            Id := JTokenLink.AsValue().AsText();
        end;

        exit(Id);
    end;

    local procedure GetWebUrl(FileId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Json: Text;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokenLink: JsonToken;
        WebUrl: Text;
        Inf: Record "Company Information";
        SiteId: Text;
    begin
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        if SiteId <> '' then
            exit(GetWebUrlSite(FileId, SiteId));
        Ticket := Format(Token());

        Url := graph_endpoint + '/me/drive/items/' + FileId + '?select=webUrl';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('webUrl', JTokenLink) then begin
            WebUrl := JTokenLink.AsValue().AsText();
        end;

        exit(WebUrl);
    end;

    procedure RestApi(url: Text; RequestType: Option Get,patch,put,post,delete; payload: Text; User: Text; Pass: Text): Text
    var
        Client: HttpClient;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        RequestMessage: HttpRequestMessage;
        ResponseText: Text;
        contentHeaders: HttpHeaders;
    begin
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
                    if payload <> '' then
                        RequestContent.WriteFrom(payload);
                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');
                    Client.Post(URL, RequestContent, ResponseMessage);
                end;
            RequestType::delete:
                Client.Delete(URL, ResponseMessage);
        end;

        ResponseMessage.Content().ReadAs(ResponseText);
        exit(ResponseText);
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
            RequestType::put:
                begin
                    RequestContent.WriteFrom(payload);
                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/json');
                    Client.Put(URL, RequestContent, ResponseMessage);
                end;
            RequestType::delete:
                Client.Delete(URL, ResponseMessage);
        end;

        ResponseMessage.Content().ReadAs(ResponseText);
        exit(ResponseText);
    end;

    procedure RestApiTokenResponse(url: Text; Token: Text; RequestType: Option Get,patch,put,post,delete; payload: Text): HttpResponseMessage
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
            RequestType::put:
                begin
                    RequestContent.WriteFrom(payload);
                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/json');
                    Client.Put(URL, RequestContent, ResponseMessage);
                end;
            RequestType::delete:
                Client.Delete(URL, ResponseMessage);
        end;

        exit(ResponseMessage);
    end;

    procedure RestApiOfset(url: Text; Token: Text; RequestType: Option Get,patch,put,post,delete; payload: instream): Text
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
            RequestType::patch:
                begin
                    RequestContent.WriteFrom(payload);
                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/octet-stream');
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
                    contentHeaders.Add('Content-Type', 'application/octet-stream');
                    Client.Post(URL, RequestContent, ResponseMessage);
                end;
            RequestType::put:
                begin
                    RequestContent.WriteFrom(payload);
                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/octet-stream');
                    Client.Put(URL, RequestContent, ResponseMessage);
                end;
            RequestType::delete:
                Client.Delete(URL, ResponseMessage);
        end;

        ResponseMessage.Content().ReadAs(ResponseText);
        exit(ResponseText);
    end;

    procedure RestApiGetContentStream(url: Text; RequestType: Option Get,patch,put,post,delete; var payload: InStream)
    var
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        RequestMessage: HttpRequestMessage;
        contentHeaders: HttpHeaders;
    begin
        RequestHeaders := Client.DefaultRequestHeaders();

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
                Client.Delete(URL, ResponseMessage);
        end;

        ResponseMessage.Content().ReadAs(payload);
    end;

    internal procedure CreateFolderStructure(BaseFolderId: Text; FolderName: Text): Text
    var
        NewFolderId: Text;
        Inf: Record "Company Information";
        SiteId: Text;
    begin
        if FolderName = '' then
            exit(BaseFolderId);
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        // Split path by '/'
        //PathParts := FolderPath.Split('/');
        //CurrentFolderId := BaseFolderId;
        if SiteId = '' then
            NewFolderId := FindOrCreateSubfolder(BaseFolderId, FolderName, true)
        else
            NewFolderId := FindOrCreateSubfolderInSharedSite(BaseFolderId, FolderName, true);
        //NewFolderId := FindOrCreateSubfolder(BaseFolderId, FolderName, true);
        // for i := 1 to PathParts.Count do begin
        //     FolderName := PathParts.Get(i);
        //     if FolderName <> '' then begin
        //         // Check if folder already exists
        //         NewFolderId := FindOrCreateSubfolder(CurrentFolderId, FolderName, true);
        //         if NewFolderId <> '' then
        //             CurrentFolderId := NewFolderId
        //         else
        //             exit(CurrentFolderId); // Return last successful folder if creation fails
        //     end;
        // end;

        exit(NewFolderId);
    end;

    internal procedure CreateFolderStructureSite(BaseFolderId: Text; FolderName: Text; SiteId: Text): Text
    var
        NewFolderId: Text;
    begin
        if FolderName = '' then
            exit(BaseFolderId);

        // Split path by '/'
        //PathParts := FolderPath.Split('/');
        //CurrentFolderId := BaseFolderId;
        NewFolderId := FindOrCreateSubfolderInSharedSite(BaseFolderId, FolderName, true);
        // for i := 1 to PathParts.Count do begin
        //     FolderName := PathParts.Get(i);
        //     if FolderName <> '' then begin
        //         // Check if folder already exists
        //         NewFolderId := FindOrCreateSubfolder(CurrentFolderId, FolderName, true);
        //         if NewFolderId <> '' then
        //             CurrentFolderId := NewFolderId
        //         else
        //             exit(CurrentFolderId); // Return last successful folder if creation fails
        //     end;
        // end;

        exit(NewFolderId);
    end;

    internal procedure GetPdfBase64(OneDriveID: Text[250]): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        Response: HttpResponseMessage;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        Link: JsonObject;
        LinkToken: JsonToken;
        WebUrl: Text;
        ErrorMessage: Text;
        Json: Text;
        Stream: InStream;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        Base64: Text;
        Base64Convert: Codeunit "Base64 Convert";
        Inf: Record "Company Information";
        SiteId: Text;
    begin
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        if SiteId <> '' then
            exit(GetPdfBase64Site(OneDriveID, SiteId));
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        // Obtener metadatos del archivo incluyendo el enlace web
        //Url := StrSubstNo(graph_endpoint + '/me/drive/items/%1?select=id,name,webUrl,@microsoft.graph.downloadUrl', OneDriveID);
        Url := graph_endpoint + '/me/drive/items/' + OneDriveID + '/content?format=pdf';
        Json := '{"type": "view","scope": "anonymous"}';
        //if Istrue then
        //Json := '{"type": "edit","scope": "anonymous"}';
        Response := RestApiTokenResponse(Url, Ticket, RequestType::get, Json);
        TempBlob.CreateInStream(Stream);
        Response.Content().ReadAs(Stream);
        exit(Base64Convert.ToBase64(Stream));

    end;

    internal procedure GetUrlLink(OneDriveID: Text[250]): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        Link: JsonObject;
        LinkToken: JsonToken;
        WebUrl: Text;
        ErrorMessage: Text;
        Json: Text;
        Inf: Record "Company Information";
        SiteId: Text;
    begin
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        if SiteId <> '' then
            exit(GetUrlLinkSite(OneDriveID, SiteId));
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        // Obtener metadatos del archivo incluyendo el enlace web
        //Url := StrSubstNo(graph_endpoint + '/me/drive/items/%1?select=id,name,webUrl,@microsoft.graph.downloadUrl', OneDriveID);
        Url := graph_endpoint + '/me/drive/items/' + OneDriveID + '/createLink';
        Json := '{"type": "view","scope": "anonymous"}';
        //if Istrue then
        Json := '{"type": "edit","scope": "anonymous"}';
        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta = '' then
            Error(NoServerResponseErr);
        StatusInfo.ReadFrom(Respuesta);
        if StatusInfo.Get('error', JToken) then begin
            if JToken.AsObject().Get('message', JToken) then begin
                ErrorMessage := JToken.AsValue().AsText();
                Error(FileAccessErrorErr, ErrorMessage);
            end;
        end;
        //{"@odata.context":"https://graph.microsoft.com/v1.0/$metadata#microsoft.graph.permission",
        //"id":"2b09a13e-84fe-435b-a1eb-e1c1ef07132f","roles":["read"],"shareId":"u!aHR0cHM6Ly9tYWxsYXBhbG1hLW15LnNoYXJlcG9pbnQuY29tLzppOi9nL3BlcnNvbmFsL2FuZHJldXNlcnJhX21hbGxhcGFsbWFfb25taWNyb3NvZnRfY29tL0VkTVFCOFloLUJsTWp1TlVfUkRTVnA0QjQtc2JSakpBMWw3M1ZVVXBSZVhRdmc","hasPassword":false,//
        //"link":{"scope":"anonymous","type":"view","webUrl":"https://mallapalma-my.sharepoint.com/:i:/g/personal/andreuserra_mallapalma_onmicrosoft_com/EdMQB8Yh-BlMjuNU_RDSVp4B4-sbRjJA1l73VUUpReXQvg","preventsDownload":false}}
        // Intentar obtener el enlace web
        if StatusInfo.Get('link', JToken) then begin
            Link := JToken.AsObject();
            if Link.Get('webUrl', LinkToken) then begin
                WebUrl := LinkToken.AsValue().AsText();
                exit(WebUrl);
            end;
        end else begin
            Error(FileLinkErrorErr);
        end;
    end;

    internal procedure OpenFileInBrowser(OneDriveID: Text[250]; IsEdit: Boolean)
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        Link: JsonObject;
        LinkToken: JsonToken;
        WebUrl: Text;
        ErrorMessage: Text;
        Json: Text;
        Inf: Record "Company Information";
        SiteId: Text;
    begin
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        if SiteId <> '' then begin
            OpenFileInBrowserSite(OneDriveID, IsEdit, SiteId);
            exit;
        end;
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        // Obtener metadatos del archivo incluyendo el enlace web
        //Url := StrSubstNo(graph_endpoint + '/me/drive/items/%1?select=id,name,webUrl,@microsoft.graph.downloadUrl', OneDriveID);
        Url := graph_endpoint + '/me/drive/items/' + OneDriveID + '/createLink';
        Json := '{"type": "view","scope": "anonymous"}';
        if IsEdit then
            Json := '{"type": "edit","scope": "anonymous"}';
        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta = '' then
            Error(NoServerResponseErr);
        StatusInfo.ReadFrom(Respuesta);
        if StatusInfo.Get('error', JToken) then begin
            if JToken.AsObject().Get('message', JToken) then begin
                ErrorMessage := JToken.AsValue().AsText();
                Error(FileAccessErrorErr, ErrorMessage);
            end;
        end;
        //{"@odata.context":"https://graph.microsoft.com/v1.0/$metadata#microsoft.graph.permission",
        //"id":"2b09a13e-84fe-435b-a1eb-e1c1ef07132f","roles":["read"],"shareId":"u!aHR0cHM6Ly9tYWxsYXBhbG1hLW15LnNoYXJlcG9pbnQuY29tLzppOi9nL3BlcnNvbmFsL2FuZHJldXNlcnJhX21hbGxhcGFsbWFfb25taWNyb3NvZnRfY29tL0VkTVFCOFloLUJsTWp1TlVfUkRTVnA0QjQtc2JSakpBMWw3M1ZVVXBSZVhRdmc","hasPassword":false,//
        //"link":{"scope":"anonymous","type":"view","webUrl":"https://mallapalma-my.sharepoint.com/:i:/g/personal/andreuserra_mallapalma_onmicrosoft_com/EdMQB8Yh-BlMjuNU_RDSVp4B4-sbRjJA1l73VUUpReXQvg","preventsDownload":false}}
        // Intentar obtener el enlace web
        if StatusInfo.Get('link', JToken) then begin
            Link := JToken.AsObject();
            if Link.Get('webUrl', LinkToken) then begin
                WebUrl := LinkToken.AsValue().AsText();
                Hyperlink(WebUrl);
            end;
        end else begin
            Error(FileLinkErrorErr);
        end;
    end;

    internal procedure GetFolderMapping(TableID: Integer; Var Id: Text): Record "Google Drive Folder Mapping"
    var
        FolderMapping: Record "Google Drive Folder Mapping";
    begin
        FolderMapping.SetRange("Table ID", TableID);
        if FolderMapping.FindFirst() then
            Id := FolderMapping."Default Folder ID";
        exit(FolderMapping);
    end;

    internal procedure Movefile(OneDriveID: Text[250]; Destino: Text; Nombre: Text; Mover: Boolean; Filename: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Body: JsonObject;
        JDestino: JsonObject;
        Json: Text;
        ErrorMessage: Text;
        CopiedFileId: Text;
        JEntryToken: JsonToken;
        JEntries: JsonArray;
        JEntryTokens: JsonToken;
        JEntry: JsonObject;
        ItemId: Text;
        ItemName: Text;
        Inf: Record "Company Information";
        SiteId: Text;
    begin
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        if SiteId <> '' then
            exit(MovefileSite(OneDriveID, Destino, Nombre, Mover, Filename, SiteId));
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Primero copiar el archivo al destino
        Url := StrSubstNo(graph_endpoint + '/me/drive/items/%1/copy', OneDriveID);

        Clear(Body);
        Clear(JDestino);
        JDestino.Add('id', Destino);
        Body.Add('parentReference', JDestino);
        if Nombre <> '' then
            Body.Add('name', Nombre);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('error', JTokenLink) then begin
                ErrorMessage := JTokenLink.AsValue().AsText();
                Error(CopyFileErrorErr, ErrorMessage, Respuesta);
            end;

            // Obtener el ID del archivo copiado
            if StatusInfo.Get('id', JTokenLink) then begin
                CopiedFileId := JTokenLink.AsValue().AsText();
            end;
        end else begin
            // Un get de los archivos de la carpeta destino y, buscar por nombre
            Url := StrSubstNo(graph_endpoint + '/me/drive/items/%1/children', Destino);
            Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
            if Respuesta <> '' then begin
                StatusInfo.ReadFrom(Respuesta);
                if StatusInfo.Get('value', JEntryToken) then begin
                    JEntries := JEntryToken.AsArray();

                    foreach JEntryTokens in JEntries do begin
                        JEntry := JEntryTokens.AsObject();
                        if JEntry.Get('id', JEntryToken) then
                            ItemId := JEntryToken.AsValue().AsText()
                        else
                            ItemId := '';

                        // Obtener el nombre del elemento
                        if JEntry.Get('name', JEntryToken) then
                            ItemName := JEntryToken.AsValue().AsText()
                        else
                            ItemName := '';
                        if ItemName = Filename then begin
                            CopiedFileId := ItemId;
                            break;
                        end;
                    end;
                end;
            end;
        end;


        // Si la copia fue exitosa, eliminar el archivo original
        if (Mover) and (CopiedFileId <> '') then begin
            if not DeleteFile(OneDriveID) then begin
                Error(FileCopiedButNotDeletedMsg, Filename);
            end;
        end;
        if CopiedFileId = '' then Error(CopyFileFailedMsg);
        exit(CopiedFileId);
    end;

    internal procedure OptenerPath(OneDriveID: Text[250]): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Json: JsonObject;
        JsonParent: JsonObject;
        Name: JsonToken;
        Parent: JsonToken;
        PathBase: JsonToken;
        RutaCompleta: Text;
        Inf: Record "Company Information";
        SiteId: Text;
    begin
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        if SiteId <> '' then
            exit(OptenerPathSite(OneDriveID, SiteId));
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        //GET https://graph.microsoft.com/v1.0/me/drive/items/{item-id}
        Url := StrSubstNo(graph_endpoint + '/me/drive/items/%1', OneDriveID);
        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        Json.ReadFrom(Respuesta);

        Json.Get('name', Name);
        if Json.Get('parentReference', Parent) Then begin
            JsonParent := Parent.AsObject();
            if JsonParent.Get('path', PathBase) then
                RutaCompleta := PathBase.AsValue().AsText();
        end
        else
            Error(GetFilePathErrorErr);

        exit(RutaCompleta);
    end;

    internal procedure EditFile(OneDriveID: Text[250])
    begin
        OpenFileInBrowser(OneDriveID, true);
    end;

    internal procedure RenameFolder(RootFolderID: Text[250]; RootFolder: Text[250]): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        JsonParent: JsonObject;
        Name: JsonToken;
        Parent: JsonToken;
        PathBase: JsonToken;
        RutaCompleta: Text;
        Inf: Record "Company Information";
        SiteId: Text;
        Json: Text;

    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);
        Ticket := Token();
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        if SiteId <> '' then
            Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + RootFolderID
        else
            Url := graph_endpoint + '/me/drive/items/' + RootFolderID;
        Json := '{"name":"' + RootFolder + '"}';
        Respuesta := RestApiToken(Url, Ticket, RequestType::patch, Json);
        exit(Respuesta);
    end;

    procedure DeleteFile(GetDocumentID: Text): Boolean
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        ResponseMessage: HttpResponseMessage;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Inf: Record "Company Information";
        SiteId: Text;
    begin
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        if SiteId <> '' then
            exit(DeleteFileSite(GetDocumentID, SiteId));
        Ticket := Token();
        Url := graph_endpoint + delete_endpoint;
        Url := StrSubstNo(Url, GetDocumentID);
        ResponseMessage := RestApiTokenResponse(Url, Ticket, RequestType::delete, '');
        //Si la respuesta es 204, el archivo se ha eliminado correctamente
        if ResponseMessage.IsSuccessStatusCode() then
            exit(true)
        else
            exit(false);
    end;

    procedure FindOrCreateSubfolder(ParentFolderId: Text; FolderName: Text; SoloSubfolder: Boolean): Text
    var
        Files: Record "Name/Value Buffer" temporary;
        FolderId: Text;
        FoundFolder: Boolean;
    begin
        // First, try to find existing folder
        ListFolder(ParentFolderId, Files, SoloSubfolder);

        Files.Reset();
        if Files.FindSet() then begin
            repeat
                if (Files.Name = FolderName) and (Files.Value = 'Carpeta') then begin
                    // Extract folder ID from Value field
                    FolderId := Files."Google Drive ID";
                    FoundFolder := true;
                end;
            until (Files.Next() = 0) or FoundFolder;
        end;

        if FoundFolder then
            exit(FolderId);

        // Folder doesn't exist, create it
        exit(CreateOneDriveFolder(ParentFolderId, FolderName, false));
    end;

    procedure GetTargetFolderForDocument(TableID: Integer; DocumentNo: Text; DocumentDate: Date; Origen: Enum "Data Storage Provider"): Text
    var
        FolderMapping: Record "Google Drive Folder Mapping";
        TargetFolderId: Text;
        SubfolderPath: Text;
    begin
        // Get the configured folder for this table
        TargetFolderId := FolderMapping.GetDefaultFolderForTable(TableID);

        if TargetFolderId = '' then begin
            // No specific configuration, use root or default folder
            exit(''); // Empty means root folder
        end;
        if DocumentNo = '' then
            exit(TargetFolderId);
        // Check if we need to create subfolders
        SubfolderPath := FolderMapping.CreateSubfolderPath(TableID, DocumentNo, DocumentDate, Origen);

        if SubfolderPath <> TargetFolderId then begin
            // Need to create subfolder structure
            TargetFolderId := CreateFolderStructure(TargetFolderId, SubfolderPath);
        end;

        exit(TargetFolderId);
    end;

    procedure ListFolder(FolderId: Text; var Files: Record "Name/Value Buffer" temporary; SoloSubfolder: Boolean)
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JEntries: JsonArray;
        JEntry: JsonObject;
        JEntryToken: JsonToken;
        JEntryTokens: JsonToken;
        JValue: JsonToken;
        a: Integer;
        FilesTemp: Record "Name/Value Buffer" temporary;
        ItemType: Text;
        ItemName: Text;
        ItemId: Text;
        ParentFolderPath: Text;
    begin
        Files.DeleteAll();
        Ticket := Token();

        // Construir la URL para listar el contenido de la carpeta
        if SoloSubfolder then begin
            if FolderId <> '' then begin
                // Listar contenido de una carpeta específica
                Url := graph_endpoint + '/me/drive/items/' + FolderId + '/children';
            end else begin
                // Listar contenido de la carpeta raíz
                Url := graph_endpoint + '/me/drive/root/children';
            end;
        end else begin
            // Listar contenido de la carpeta raíz
            Url := graph_endpoint + '/me/drive/root/children';
        end;

        // Añadir parámetros para obtener información completa
        Url := Url + '?$select=id,name,size,lastModifiedDateTime,folder,file,@microsoft.graph.downloadUrl';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);

            if StatusInfo.Get('value', JEntryToken) then begin
                JEntries := JEntryToken.AsArray();

                foreach JEntryTokens in JEntries do begin
                    JEntry := JEntryTokens.AsObject();

                    // Obtener el ID del elemento
                    if JEntry.Get('id', JEntryToken) then
                        ItemId := JEntryToken.AsValue().AsText()
                    else
                        ItemId := '';

                    // Obtener el nombre del elemento
                    if JEntry.Get('name', JEntryToken) then
                        ItemName := JEntryToken.AsValue().AsText()
                    else
                        ItemName := '';

                    // Determinar si es carpeta o archivo
                    if JEntry.Get('folder', JEntryToken) then begin
                        ItemType := 'Carpeta';
                    end else if JEntry.Get('file', JEntryToken) then begin
                        ItemType := '';
                    end else begin
                        ItemType := '';
                    end;

                    // Crear registro temporal
                    FilesTemp.Init();
                    a += 1;
                    FilesTemp.ID := a;
                    FilesTemp.Name := ItemName;
                    FilesTemp."Google Drive ID" := ItemId; // Reutilizamos el campo para OneDrive ID
                    FilesTemp."Google Drive Parent ID" := FolderId; // Reutilizamos el campo para Parent ID
                    FilesTemp.Value := ItemType;

                    // Si es archivo, obtener la extensión
                    if ItemType = '' then begin
                        FilesTemp."File Extension" := GetFileExtension(ItemName);
                    end;

                    FilesTemp.Insert();
                end;
            end;
        end;

        // Ordenar: primero carpetas, luego archivos
        a := 0;
        FilesTemp.SetRange(Value, 'Carpeta');
        if FilesTemp.FindSet() then
            repeat
                a += 1;
                Files := FilesTemp;
                Files.ID := a;
                Files.Insert();
            until FilesTemp.Next() = 0;

        FilesTemp.SetRange(Value, '');
        if FilesTemp.FindSet() then
            repeat
                a += 1;
                Files := FilesTemp;
                Files.ID := a;
                Files.Insert();
            until FilesTemp.Next() = 0;
    end;

    local procedure GetFileExtension(FileName: Text): Text
    var
        FileMgt: Codeunit "File Management";
    begin
        exit(FileMgt.GetExtension(FileName));
    end;

    local procedure UrlEncode(InputText: Text): Text
    var
        i: Integer;
        Result: Text;
        CurrentChar: Text[1];
    begin
        Result := '';
        for i := 1 to StrLen(InputText) do begin
            CurrentChar := CopyStr(InputText, i, 1);
            case CurrentChar of
                ' ':
                    Result += '%20';
                '!':
                    Result += '%21';
                '"':
                    Result += '%22';
                '#':
                    Result += '%23';
                '$':
                    Result += '%24';
                '%':
                    Result += '%25';
                '&':
                    Result += '%26';
                '''':
                    Result += '%27';
                '(':
                    Result += '%28';
                ')':
                    Result += '%29';
                '*':
                    Result += '%2A';
                '+':
                    Result += '%2B';
                ',':
                    Result += '%2C';
                '/':
                    Result += '%2F';
                ':':
                    Result += '%3A';
                ';':
                    Result += '%3B';
                '<':
                    Result += '%3C';
                '=':
                    Result += '%3D';
                '>':
                    Result += '%3E';
                '?':
                    Result += '%3F';
                '@':
                    Result += '%40';
                '[':
                    Result += '%5B';
                '\':
                    Result += '%5C';
                ']':
                    Result += '%5D';
                '^':
                    Result += '%5E';
                '`':
                    Result += '%60';
                '{':
                    Result += '%7B';
                '|':
                    Result += '%7C';
                '}':
                    Result += '%7D';
                '~':
                    Result += '%7E';
                else
                    Result += CurrentChar;
            end;
        end;
        exit(Result);
    end;

    local procedure FindOrCreateSubfolderInSharedSite(ParentFolderId: Text; FolderName: Text; SoloSubfolder: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        JValue: JsonArray;
        JEntry: JsonObject;
        JEntryTokens: JsonToken;
        a: Integer;
        Files: Record "Name/Value Buffer" temporary;
        Inf: Record "Company Information";
        SiteId: Text;
        FolderId: Text;
        FoundFolder: Boolean;
    begin
        Inf.Get();
        SiteId := Inf."OneDrive Site ID";
        ListFolderSite(SiteId, ParentFolderId, Files, SoloSubfolder);

        Files.Reset();
        if Files.FindSet() then begin
            repeat
                if (Files.Name = FolderName) and (Files.Value = 'Carpeta') then begin
                    // Extract folder ID from Value field
                    FolderId := Files."Google Drive ID";
                    FoundFolder := true;
                end;
            until (Files.Next() = 0) or FoundFolder;
        end;

        if FoundFolder then
            exit(FolderId);

        // Folder doesn't exist, create it
        exit(CreateFolderInSharedSite(SiteId, ParentFolderId, FolderName, false));
    end;

    local procedure ListFolderSite(SiteId: Text; FolderId: Text; var Files: Record "Name/Value Buffer" temporary; SoloSubfolder: Boolean)
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        JValue: JsonArray;
        JEntry: JsonObject;
        JEntryTokens: JsonToken;
        a: Integer;
        FilesTemp: Record "Name/Value Buffer" temporary;
        ItemType: Text;
        ItemName: Text;
        ItemId: Text;
        ParentFolderPath: Text;
        JEntries: JsonArray;
        JEntryToken: JsonToken;
    begin
        Files.DeleteAll();
        Ticket := Token();
        if FolderId = '' then
            Url := graph_endpoint + '/sites/' + SiteId + '/drive/root/children'
        else
            Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + FolderId + '/children';
        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);

            if StatusInfo.Get('value', JEntryToken) then begin
                JEntries := JEntryToken.AsArray();

                foreach JEntryTokens in JEntries do begin
                    JEntry := JEntryTokens.AsObject();

                    // Obtener el ID del elemento
                    if JEntry.Get('id', JEntryToken) then
                        ItemId := JEntryToken.AsValue().AsText()
                    else
                        ItemId := '';

                    // Obtener el nombre del elemento
                    if JEntry.Get('name', JEntryToken) then
                        ItemName := JEntryToken.AsValue().AsText()
                    else
                        ItemName := '';

                    // Determinar si es carpeta o archivo
                    if JEntry.Get('folder', JEntryToken) then begin
                        ItemType := 'Carpeta';
                    end else if JEntry.Get('file', JEntryToken) then begin
                        ItemType := '';
                    end else begin
                        ItemType := '';
                    end;

                    // Crear registro temporal
                    FilesTemp.Init();
                    a += 1;
                    FilesTemp.ID := a;
                    FilesTemp.Name := ItemName;
                    FilesTemp."Google Drive ID" := ItemId; // Reutilizamos el campo para OneDrive ID
                    FilesTemp."Google Drive Parent ID" := FolderId; // Reutilizamos el campo para Parent ID
                    FilesTemp.Value := ItemType;

                    // Si es archivo, obtener la extensión
                    if ItemType = '' then begin
                        FilesTemp."File Extension" := GetFileExtension(ItemName);
                    end;

                    FilesTemp.Insert();
                end;
            end;
        end;

        // Ordenar: primero carpetas, luego archivos
        a := 0;
        FilesTemp.SetRange(Value, 'Carpeta');
        if FilesTemp.FindSet() then
            repeat
                a += 1;
                Files := FilesTemp;
                Files.ID := a;
                Files.Insert();
            until FilesTemp.Next() = 0;

        FilesTemp.SetRange(Value, '');
        if FilesTemp.FindSet() then
            repeat
                a += 1;
                Files := FilesTemp;
                Files.ID := a;
                Files.Insert();
            until FilesTemp.Next() = 0;
    end;



    procedure RecuperaIdFolderSite(IdCarpeta: Text; Carpeta: Text; var Files: Record "Name/Value Buffer" temporary; Crear: Boolean; RootFolder: Boolean; SiteId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JValue: JsonArray;
        JEntry: JsonObject;
        JToken: JsonToken;
        JEntryTokens: JsonToken;
        ItemName: Text;
        Found: Boolean;
        ResultId: Text;
        a: Integer;
        Extension: Text;
    begin
        Files.DeleteAll();
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        CompanyInfo.Get();
        If IdCarpeta = '' Then
            IdCarpeta := CompanyInfo."Root Folder ID";
        if RootFolder then
            Url := StrSubstNo(graph_endpoint + '/sites/%1/drive/root/children', SiteId)
        else
            Url := StrSubstNo(graph_endpoint + '/sites/%1/drive/items/%2/children', SiteId, IdCarpeta);

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('value', JToken) then begin
                JValue := JToken.AsArray();
                a := 0;
                foreach JEntryTokens in JValue do begin
                    JEntry := JEntryTokens.AsObject();
                    a += 1;
                    Files.Init();
                    Files.ID := a;

                    if JEntry.Get('name', JToken) then
                        Files.Name := JToken.AsValue().AsText();

                    if JEntry.Get('id', JToken) then
                        Files."Google Drive ID" := JToken.AsValue().AsText();

                    if JEntry.Get('folder', JToken) then begin
                        Files.Value := 'Carpeta';
                        if Files.Name = Carpeta then begin
                            Found := true;
                            ResultId := Files."Google Drive ID";
                        end;
                    end else begin
                        Files.Value := '';
                        if JEntry.Get('file', JToken) then begin
                            Extension := GetFileExtension(Files.Name);
                            if StrLen(Extension) < 30 then
                                Files."File Extension" := Extension;
                        end;
                    end;
                    Files.Insert();
                end;
            end;
        end;

        if Found then
            exit(ResultId);

        if Crear then begin
            ResultId := CreateFolderInSharedSite(SiteId, IdCarpeta, Carpeta, RootFolder);
            exit(ResultId);
        end;

        exit('');
    end;

    procedure RecuperaIdFolder(IdCarpeta: Text; Carpeta: Text; var Files: Record "Name/Value Buffer" temporary; Crear: Boolean; RootFolder: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JValue: JsonArray;
        JEntry: JsonObject;
        JToken: JsonToken;
        JEntryTokens: JsonToken;
        ItemName: Text;
        Found: Boolean;
        ResultId: Text;
        a: Integer;
        Extension: Text;
    begin
        Files.DeleteAll();
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        CompanyInfo.Get();
        if (CompanyInfo."OneDrive Site ID" = '') and (CompanyInfo."OneDrive Site URL" <> '') then
            Error(SiteIdNotConfiguredMsg);

        If CompanyInfo."OneDrive Site ID" <> '' then begin
            exit(RecuperaIdFolderSite(IdCarpeta, Carpeta, Files, Crear, RootFolder, CompanyInfo."OneDrive Site ID"));
        end;
        If IdCarpeta = '' Then
            IdCarpeta := CompanyInfo."Root Folder ID";
        if RootFolder then
            Url := StrSubstNo(graph_endpoint + '/me/drive/root/children')
        else
            Url := StrSubstNo(graph_endpoint + '/me/drive/items/%1/children', IdCarpeta);


        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('value', JToken) then begin
                JValue := JToken.AsArray();
                a := 0;
                foreach JEntryTokens in JValue do begin
                    JEntry := JEntryTokens.AsObject();
                    a += 1;
                    Files.Init();
                    Files.ID := a;

                    if JEntry.Get('name', JToken) then
                        Files.Name := JToken.AsValue().AsText();

                    if JEntry.Get('id', JToken) then
                        Files."Google Drive ID" := JToken.AsValue().AsText();

                    if JEntry.Get('folder', JToken) then begin
                        Files.Value := 'Carpeta';
                        if Files.Name = Carpeta then begin
                            Found := true;
                            ResultId := Files."Google Drive ID";
                        end;
                    end else begin
                        Files.Value := '';
                        if JEntry.Get('file', JToken) then begin
                            Extension := GetFileExtension(Files.Name);
                            if StrLen(Extension) < 30 then
                                Files."File Extension" := Extension;
                        end;
                    end;
                    Files.Insert();
                end;
            end;
        end;

        if Found then
            exit(ResultId);

        if Crear then begin
            ResultId := CreateOneDriveFolder(IdCarpeta, Carpeta, RootFolder);
            exit(ResultId);
        end;

        exit('');
    end;

    procedure CreateOneDriveFolder(ParentFolderId: Text; Foldername: Text; RootFolder: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        FolderObject: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        NewFolderId: Text;
    begin
        Ticket := Token();
        if RootFolder then
            Url := StrSubstNo(graph_endpoint + '/me/drive/root/children')
        else
            Url := StrSubstNo(graph_endpoint + '/me/drive/items/%1/children', ParentFolderId);

        Clear(Body);
        Body.Add('name', FolderName);
        Clear(FolderObject);
        Body.Add('folder', FolderObject);
        Body.Add('@microsoft.graph.conflictBehavior', 'rename');
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('id', JToken) then
                NewFolderId := JToken.AsValue().AsText()
            else
                Error(CreateFolderErrorErr, Respuesta, Url, Json);
        end;
        exit(NewFolderId);
    end;

    // Métodos para recuperar ID de sitios compartidos de OneDrive
    procedure GetSharedSiteId(SiteUrl: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        SiteId: Text;
        ErrorMessage: Text;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Obtener el ID del sitio usando la URL del sitio
        Url := graph_endpoint + '/sites/' + SiteUrl;

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta = '' then
            Error(NoResponseMsg);

        StatusInfo.ReadFrom(Respuesta);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            Error(GetSiteErrorErr, ErrorMessage);
        end;

        // Obtener el ID del sitio
        if StatusInfo.Get('id', JToken) then begin
            SiteId := JToken.AsValue().AsText();
            exit(SiteId);
        end else begin
            Error(GetSiteIdErrorMsg);
        end;
    end;

    procedure GetSharedSiteIdByHostname(SiteHostname: Text; SitePath: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        SiteId: Text;
        ErrorMessage: Text;
        FullSiteUrl: Text;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Construir la URL completa del sitio
        if SitePath <> '' then
            FullSiteUrl := SiteHostname + ':/sites/' + SitePath
        else
            FullSiteUrl := SiteHostname;

        // Obtener el ID del sitio usando el hostname y path
        Url := graph_endpoint + '/sites/' + FullSiteUrl;

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta = '' then
            Error(NoResponseMsg);

        StatusInfo.ReadFrom(Respuesta);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            Error(GetSiteErrorErr, ErrorMessage);
        end;

        // Obtener el ID del sitio
        if StatusInfo.Get('id', JToken) then begin
            SiteId := JToken.AsValue().AsText();
            exit(SiteId);
        end else begin
            Error(GetSiteByHostnameErrorMsg);
        end;
    end;

    procedure SearchSharedSites(SearchTerm: Text; var Sites: Record "Name/Value Buffer" temporary)
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        JEntries: JsonArray;
        JEntry: JsonObject;
        JEntryTokens: JsonToken;
        SiteId: Text;
        SiteName: Text;
        SiteUrl: Text;
        a: Integer;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Buscar sitios que coincidan con el término de búsqueda
        Url := graph_endpoint + '/sites?search=' + UrlEncode(SearchTerm);

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta = '' then
            Error(NoResponseMsg);

        StatusInfo.ReadFrom(Respuesta);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            Error(SearchSitesErrorMsg, JToken.AsValue().AsText());
        end;

        // Procesar los resultados
        if StatusInfo.Get('value', JToken) then begin
            JEntries := JToken.AsArray();
            a := 0;

            foreach JEntryTokens in JEntries do begin
                JEntry := JEntryTokens.AsObject();
                a += 1;

                Sites.Init();
                Sites.ID := a;

                // Obtener el ID del sitio
                if JEntry.Get('id', JToken) then
                    Sites."Google Drive ID" := JToken.AsValue().AsText();

                // Obtener el nombre del sitio
                if JEntry.Get('displayName', JToken) then
                    Sites.Name := JToken.AsValue().AsText();

                // Obtener la URL del sitio
                if JEntry.Get('webUrl', JToken) then
                    Sites.Value := JToken.AsValue().AsText();

                Sites.Insert();
            end;
        end;
    end;

    procedure GetSharedSiteDriveId(SiteId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        DriveId: Text;
        ErrorMessage: Text;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Obtener el drive del sitio compartido
        Url := graph_endpoint + '/sites/' + SiteId + '/drive';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta = '' then
            Error(NoResponseMsg);

        StatusInfo.ReadFrom(Respuesta);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            Error(GetSiteDriveErrorMsg, ErrorMessage);
        end;

        // Obtener el ID del drive
        if StatusInfo.Get('id', JToken) then begin
            DriveId := JToken.AsValue().AsText();
            exit(DriveId);
        end else begin
            Error(GetSiteDriveIdErrorMsg);
        end;
    end;

    procedure ListSharedSiteFiles(SiteId: Text; var Files: Record "Name/Value Buffer" temporary)
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JEntries: JsonArray;
        JEntry: JsonObject;
        JEntryToken: JsonToken;
        JEntryTokens: JsonToken;
        a: Integer;
        ItemType: Text;
        ItemName: Text;
        ItemId: Text;
        FilesTemp: Record "Name/Value Buffer" temporary;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Files.DeleteAll();
        Ticket := Token();

        // Listar archivos del sitio compartido
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/root/children';
        Url := Url + '?$select=id,name,size,lastModifiedDateTime,folder,file,@microsoft.graph.downloadUrl';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);

            if StatusInfo.Get('value', JEntryToken) then begin
                JEntries := JEntryToken.AsArray();

                foreach JEntryTokens in JEntries do begin
                    JEntry := JEntryTokens.AsObject();

                    // Obtener el ID del elemento
                    if JEntry.Get('id', JEntryToken) then
                        ItemId := JEntryToken.AsValue().AsText()
                    else
                        ItemId := '';

                    // Obtener el nombre del elemento
                    if JEntry.Get('name', JEntryToken) then
                        ItemName := JEntryToken.AsValue().AsText()
                    else
                        ItemName := '';

                    // Determinar si es carpeta o archivo
                    if JEntry.Get('folder', JEntryToken) then begin
                        ItemType := 'Carpeta';
                    end else if JEntry.Get('file', JEntryToken) then begin
                        ItemType := '';
                    end else begin
                        ItemType := '';
                    end;

                    // Crear registro temporal
                    FilesTemp.Init();
                    a += 1;
                    FilesTemp.ID := a;
                    FilesTemp.Name := ItemName;
                    FilesTemp."Google Drive ID" := ItemId;
                    FilesTemp.Value := ItemType;

                    // Si es archivo, obtener la extensión
                    if ItemType = '' then begin
                        FilesTemp."File Extension" := GetFileExtension(ItemName);
                    end;

                    FilesTemp.Insert();
                end;
            end;
        end;

        // Ordenar: primero carpetas, luego archivos
        a := 0;
        FilesTemp.SetRange(Value, 'Carpeta');
        if FilesTemp.FindSet() then
            repeat
                a += 1;
                Files := FilesTemp;
                Files.ID := a;
                Files.Insert();
            until FilesTemp.Next() = 0;

        FilesTemp.SetRange(Value, '');
        if FilesTemp.FindSet() then
            repeat
                a += 1;
                Files := FilesTemp;
                Files.ID := a;
                Files.Insert();
            until FilesTemp.Next() = 0;
    end;

    // Métodos para subir archivos a sitios compartidos
    procedure UploadFileToSharedSite(SiteId: Text; Carpeta: Text; var DocumentAttach: Record "Document Attachment"): Text
    var
        DocumentStream: OutStream;
        TempBlob: Codeunit "Temp Blob";
        Int: Instream;
        FileMang: Codeunit "File Management";
        Extension: Text;
    begin
        TempBlob.CreateOutStream(DocumentStream);
        DocumentAttach."Document Reference ID".ExportStream(DocumentStream);
        If DocumentAttach."File Extension" = '' then
            Extension := FileMang.GetExtension(DocumentAttach."File Name")
        else
            Extension := DocumentAttach."File Extension";
        TempBlob.CreateInStream(Int);

        exit(UploadFileB64ToSharedSite(SiteId, Carpeta, Int, DocumentAttach."File Name", Extension));
    end;

    procedure UploadFileB64ToSharedSite(SiteId: Text; Carpeta: Text; Base64Data: InStream; Filename: Text; FileExtension: Text[30]): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Id: Text;
    begin
        Ticket := Format(Token());

        // Construir la ruta del archivo para sitio compartido
        // https://graph.microsoft.com/v1.0/sites/{site-id}/drive/root:/RUTA/CARPETA/archivo.txt:/content
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/root:/' + Carpeta + Filename + '.' + FileExtension + ':/content';

        Respuesta := RestApiOfset(Url, Ticket, RequestType::put, Base64Data);

        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('id', JTokenLink) then begin
            Id := JTokenLink.AsValue().AsText();
        end else
            Error(UploadToSharedSiteErrorMsg, Respuesta);

        exit(Id);
    end;

    procedure UploadFileToSharedSiteFolder(SiteId: Text; FolderId: Text; var DocumentAttach: Record "Document Attachment"): Text
    var
        DocumentStream: OutStream;
        TempBlob: Codeunit "Temp Blob";
        Int: Instream;
        FileMang: Codeunit "File Management";
        Extension: Text;
    begin
        TempBlob.CreateOutStream(DocumentStream);
        DocumentAttach."Document Reference ID".ExportStream(DocumentStream);
        If DocumentAttach."File Extension" = '' then
            Extension := FileMang.GetExtension(DocumentAttach."File Name")
        else
            Extension := DocumentAttach."File Extension";
        TempBlob.CreateInStream(Int);

        exit(UploadFileB64ToSharedSiteFolder(SiteId, FolderId, Int, DocumentAttach."File Name", Extension));
    end;

    procedure UploadFileB64ToSharedSiteFolder(SiteId: Text; FolderId: Text; Base64Data: InStream; Filename: Text; FileExtension: Text[30]): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Id: Text;
    begin
        Ticket := Format(Token());

        // Construir la ruta del archivo para carpeta específica en sitio compartido
        // https://graph.microsoft.com/v1.0/sites/{site-id}/drive/items/{folder-id}:/{filename}:/content
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + FolderId + ':/' + Filename + '.' + FileExtension + ':/content';

        Respuesta := RestApiOfset(Url, Ticket, RequestType::put, Base64Data);

        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('id', JTokenLink) then begin
            Id := JTokenLink.AsValue().AsText();
        end else
            Error(UploadToSharedSiteFolderErrorMsg, Respuesta);

        exit(Id);
    end;

    procedure CreateFolderInSharedSite(SiteId: Text; ParentFolderId: Text; FolderName: Text; RootFolder: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        FolderObject: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        NewFolderId: Text;
    begin
        Ticket := Token();

        if RootFolder then
            // Crear en la raíz del sitio
            Url := graph_endpoint + '/sites/' + SiteId + '/drive/root/children'
        else
            // Crear en una carpeta específica
            Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + ParentFolderId + '/children';

        Clear(Body);
        Body.Add('name', FolderName);
        Clear(FolderObject);
        Body.Add('folder', FolderObject);
        Body.Add('@microsoft.graph.conflictBehavior', 'rename');
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('id', JToken) then
                NewFolderId := JToken.AsValue().AsText()
            else
                Error(CreateFolderInSharedSiteErrorMsg, Respuesta, Url, Json);
        end;
        exit(NewFolderId);
    end;

    procedure GetSharedSiteFileId(SiteId: Text; FilePath: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokenLink: JsonToken;
        Id: Text;
    begin
        Ticket := Token();

        // Obtener información del archivo en sitio compartido
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/root:/' + FilePath;

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('id', JTokenLink) then begin
            Id := JTokenLink.AsValue().AsText();
        end;

        exit(Id);
    end;

    procedure DeleteFileFromSharedSite(SiteId: Text; FileId: Text): Boolean
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        ResponseMessage: HttpResponseMessage;
    begin
        Ticket := Token();
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + FileId;
        ResponseMessage := RestApiTokenResponse(Url, Ticket, RequestType::delete, '');

        if ResponseMessage.IsSuccessStatusCode() then
            exit(true)
        else
            exit(false);
    end;

    procedure GetSharedSiteFileUrl(SiteId: Text; FileId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokenLink: JsonToken;
        WebUrl: Text;
    begin
        Ticket := Token();

        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + FileId + '?select=webUrl';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('webUrl', JTokenLink) then begin
            WebUrl := JTokenLink.AsValue().AsText();
        end;

        exit(WebUrl);
    end;

    // Métodos que faltan para sitios compartidos
    procedure GetWebUrlSite(FileId: Text; SiteId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokenLink: JsonToken;
        WebUrl: Text;
    begin
        Ticket := Token();

        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + FileId + '?select=webUrl';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('webUrl', JTokenLink) then begin
            WebUrl := JTokenLink.AsValue().AsText();
        end;

        exit(WebUrl);
    end;

    procedure DownloadFileB64Site(OneDriveID: Text[250]; FileName: Text; BajarFichero: Boolean; var Base64Data: Text; SiteId: Text): Boolean
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        Link: Text;
        ErrorMessage: Text;
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        Bs64: Codeunit "Base64 Convert";
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        Url := StrSubstNo(graph_endpoint + '/sites/%1/drive/items/%2?select=id,name,webUrl,@microsoft.graph.downloadUrl', SiteId, OneDriveID);

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta = '' then
            exit(false);

        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            exit(false);
        end;

        if StatusInfo.Get('@microsoft.graph.downloadUrl', JToken) then begin
            Link := JToken.AsValue().AsText();

            // Descargar el contenido del archivo
            TempBlob.CreateOutStream(OutStr);
            RestApiGetContentStream(Link, RequestType::get, InStr);

            // Convertir a base64
            Base64Data := Bs64.ToBase64(InStr);

            if BajarFichero then begin
                DownloadFromStream(InStr, 'Guardar', 'C:\Temp', 'ALL Files (*.*)|*.*', FileName);
            end;

            exit(true);
        end else begin
            exit(false);
        end;
    end;

    procedure DeleteFolderSite(Carpeta: Text; HideDialog: Boolean; SiteId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        Id: Text;
    begin
        if not HideDialog then
            if not Confirm(DeleteFolderMsg, true) then
                exit('');

        Ticket := Format(Token());

        // Obtener el ID del archivo/carpeta
        Id := GetFileIdSite(Carpeta, SiteId);

        if Id = '' then
            Error(FolderNotFoundMsg, Carpeta);

        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + Id;

        Respuesta := RestApiToken(Url, Ticket, RequestType::delete, '');

        exit(Id);
    end;

    procedure GetFileIdSite(FilePath: Text; SiteId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokenLink: JsonToken;
        Id: Text;
    begin
        Ticket := Token();

        // Obtener información del archivo en sitio compartido
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/root:/' + FilePath;

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('id', JTokenLink) then begin
            Id := JTokenLink.AsValue().AsText();
        end;

        exit(Id);
    end;

    procedure GetPdfBase64Site(OneDriveID: Text[250]; SiteId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        Response: HttpResponseMessage;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        Link: JsonObject;
        LinkToken: JsonToken;
        WebUrl: Text;
        ErrorMessage: Text;
        Json: Text;
        Stream: InStream;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        Base64: Text;
        Base64Convert: Codeunit "Base64 Convert";
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        // Obtener metadatos del archivo incluyendo el enlace web
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + OneDriveID + '/content?format=pdf';
        Json := '{"type": "view","scope": "anonymous"}';

        Response := RestApiTokenResponse(Url, Ticket, RequestType::get, Json);
        TempBlob.CreateInStream(Stream);
        Response.Content().ReadAs(Stream);
        exit(Base64Convert.ToBase64(Stream));
    end;

    procedure GetUrlLinkSite(OneDriveID: Text[250]; SiteId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        Link: JsonObject;
        LinkToken: JsonToken;
        WebUrl: Text;
        ErrorMessage: Text;
        Json: Text;
        ErrorCode: Text;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        // Obtener metadatos del archivo incluyendo el enlace web
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + OneDriveID + '/createLink';
        Json := '{"type": "view","scope": "anonymous"}';
        //if Istrue then
        Json := '{"type": "edit","scope": "anonymous"}';
        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta = '' then
            Error(NoResponseMsg);

        StatusInfo.ReadFrom(Respuesta);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            ErrorCode := '';

            // Obtener el código de error específico
            if StatusInfo.Get('error', JToken) then begin
                if JToken.IsObject() then begin
                    if JToken.AsObject().Get('code', JToken) then
                        ErrorCode := JToken.AsValue().AsText();
                end;
            end;

            // Si el error es de sharing disabled, intentar obtener la URL directa
            if ErrorCode = 'notAllowed' then begin
                // Intentar obtener la URL web directa del archivo
                WebUrl := GetSharedSiteFileUrl(SiteId, OneDriveID);
                if WebUrl <> '' then begin
                    Message(SharingDisabledMsg);
                    exit(WebUrl);
                end else begin
                    Error(SharingDisabledErrorMsg);
                end;
            end else begin
                Error(ShErrorMessage, ErrorMessage);
            end;
        end;

        // Intentar obtener el enlace web
        if StatusInfo.Get('link', JToken) then begin
            Link := JToken.AsObject();
            if Link.Get('webUrl', LinkToken) then begin
                WebUrl := LinkToken.AsValue().AsText();
                exit(WebUrl);
            end;
        end else begin
            Error(FileLinkErrorMsg);
        end;
    end;

    procedure OpenFileInBrowserSite(OneDriveID: Text[250]; IsEdit: Boolean; SiteId: Text)
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        Link: JsonObject;
        LinkToken: JsonToken;
        WebUrl: Text;
        ErrorMessage: Text;
        Json: Text;
        ErrorCode: Text;
        ErrorJson: JsonObject;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        // Obtener metadatos del archivo incluyendo el enlace web
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + OneDriveID + '/createLink';
        Json := '{"type": "view","scope": "anonymous"}';
        if IsEdit then
            Json := '{"type": "edit","scope": "anonymous"}';
        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta = '' then
            Error(NoResponseMsg);

        StatusInfo.ReadFrom(Respuesta);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            ErrorJson := JToken.AsObject();
            if ErrorJson.Get('code', JToken) then
                ErrorCode := JToken.AsValue().AsText();
            if ErrorJson.Get('message', JToken) then
                ErrorMessage := JToken.AsValue().AsText();
            if ErrorJson.Get('innererror', JToken) then
                ErrorJson := JToken.AsObject();


            // Si el error es de sharing disabled, intentar obtener la URL directa
            if ErrorCode = 'notAllowed' then begin
                // Intentar obtener la URL web directa del archivo
                WebUrl := GetSharedSiteFileUrl(SiteId, OneDriveID);
                if WebUrl <> '' then begin
                    Message(SharingDisabledOpenMsg);
                    Hyperlink(WebUrl);
                    exit;
                end else begin
                    Error(SharingDisabledErrorMsg);
                end;
            end else begin
                Error(ShErrorMessage, ErrorMessage);
            end;
        end;

        // Intentar obtener el enlace web
        if StatusInfo.Get('link', JToken) then begin
            Link := JToken.AsObject();
            if Link.Get('webUrl', LinkToken) then begin
                WebUrl := LinkToken.AsValue().AsText();
                Hyperlink(WebUrl);
            end;
        end else begin
            Error(FileLinkErrorMsg);
        end;
    end;

    procedure MovefileSite(OneDriveID: Text[250]; Destino: Text; arg: Text; Mover: Boolean; Filename: Text; SiteId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Body: JsonObject;
        JDestino: JsonObject;
        Json: Text;
        ErrorMessage: Text;
        CopiedFileId: Text;
        JEntryToken: JsonToken;
        JEntries: JsonArray;
        JEntryTokens: JsonToken;
        JEntry: JsonObject;
        ItemId: Text;
        ItemName: Text;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Primero copiar el archivo al destino
        Url := StrSubstNo(graph_endpoint + '/sites/%1/drive/items/%2/copy', SiteId, OneDriveID);

        Clear(Body);
        Clear(JDestino);
        JDestino.Add('id', Destino);
        Body.Add('parentReference', JDestino);
        if arg <> '' then
            Body.Add('name', arg);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('error', JTokenLink) then begin
                ErrorMessage := JTokenLink.AsValue().AsText();
                Error(CopyFileErrorMsg, ErrorMessage, Respuesta);
            end;

            // Obtener el ID del archivo copiado
            if StatusInfo.Get('id', JTokenLink) then begin
                CopiedFileId := JTokenLink.AsValue().AsText();
            end;
        end else begin
            // Un get de los archivos de la carpeta destino y, buscar por nombre
            Url := StrSubstNo(graph_endpoint + '/sites/%1/drive/items/%2/children', SiteId, Destino);
            Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
            if Respuesta <> '' then begin
                StatusInfo.ReadFrom(Respuesta);
                if StatusInfo.Get('value', JEntryToken) then begin
                    JEntries := JEntryToken.AsArray();

                    foreach JEntryTokens in JEntries do begin
                        JEntry := JEntryTokens.AsObject();
                        if JEntry.Get('id', JEntryToken) then
                            ItemId := JEntryToken.AsValue().AsText()
                        else
                            ItemId := '';

                        // Obtener el nombre del elemento
                        if JEntry.Get('name', JEntryToken) then
                            ItemName := JEntryToken.AsValue().AsText()
                        else
                            ItemName := '';
                        if ItemName = Filename then begin
                            CopiedFileId := ItemId;
                            break;
                        end;
                    end;
                end;
            end;
        end;

        // Si la copia fue exitosa, eliminar el archivo original
        if (Mover) and (CopiedFileId <> '') then begin
            if not DeleteFileSite(OneDriveID, SiteId) then begin
                Error(FileCopiedButNotDeletedMsg, Filename);
            end;
        end;
        if CopiedFileId = '' then Error(CopyFileFailedMsg);
        exit(CopiedFileId);
    end;

    procedure OptenerPathSite(OneDriveID: Text[250]; SiteId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Json: JsonObject;
        JsonParent: JsonObject;
        Name: JsonToken;
        Parent: JsonToken;
        PathBase: JsonToken;
        RutaCompleta: Text;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        //GET https://graph.microsoft.com/v1.0/sites/{site-id}/drive/items/{item-id}
        Url := StrSubstNo(graph_endpoint + '/sites/%1/drive/items/%2', SiteId, OneDriveID);
        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        Json.ReadFrom(Respuesta);

        Json.Get('name', Name);
        if Json.Get('parentReference', Parent) Then begin
            JsonParent := Parent.AsObject();
            if JsonParent.Get('path', PathBase) then
                RutaCompleta := PathBase.AsValue().AsText();
        end
        else
            Error(GetFilePathErrorErr);

        exit(RutaCompleta);
    end;

    procedure DeleteFileSite(GetDocumentID: Text; SiteId: Text): Boolean
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        ResponseMessage: HttpResponseMessage;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
    begin
        Ticket := Token();
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + GetDocumentID;
        ResponseMessage := RestApiTokenResponse(Url, Ticket, RequestType::delete, '');
        //Si la respuesta es 204, el archivo se ha eliminado correctamente
        if ResponseMessage.IsSuccessStatusCode() then
            exit(true)
        else
            exit(false);
    end;

    var
        DeleteFolderMsg: Label 'Are you sure you want to delete folder?';
        SaveAsDialogTxt: Label 'Save';

}
