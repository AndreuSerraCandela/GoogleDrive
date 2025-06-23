codeunit 95102 "OneDrive Manager"
{
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
        RedirectURI: Text;
    begin
        // Construir URL de autorización de OneDrive/Microsoft Graph
        RedirectURI := 'https://businesscentral.dynamics.com/OAuthLanding.htm'; // Para aplicaciones de escritorio

        OAuthURL := StrSubstNo(auth_endpoint, CompanyInfo."OneDrive Tenant ID") +
                   '?client_id=' + CompanyInfo."OneDrive Client ID" +
                   '&response_type=code' +
                   '&scope=Files.ReadWrite.All%20offline_access' +
                   '&response_mode=query';

        // Abrir navegador o mostrar URL
        Hyperlink(OAuthURL);
    end;

    procedure RefreshAccessToken()
    begin
        CompanyInfo.CalcFields("OneDrive Access Token", "OneDrive Refresh Token");
        if not CompanyInfo."OneDrive Access Token".HasValue Then
            ObtenerToken(CompanyInfo."Code Ondrive");

        if not CompanyInfo."OneDrive Refresh Token".HasValue then
            Error('No hay refresh token configurado para OneDrive.');

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
    begin
        if DocumentID = '' then
            exit('');

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

    procedure ObtenerToken(CodeOneDrive: Text): Text
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
        RedirectURI := 'https://oauth.pstmn.io/v1/callback';
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
            Error('The request to the token endpoint failed.');

        HttpResponse.Content().ReadAs(JsonText);

        if not HttpResponse.IsSuccessStatusCode() then
            Error('The token endpoint returned an error. Status: %1, Body: %2', HttpResponse.HttpStatusCode(), JsonText);

        StatusInfo.ReadFrom(JsonText);

        if StatusInfo.Get('refresh_token', JnodeEntryToken) then begin
            RefreshToken := JnodeEntryToken.AsValue().AsText();
            CompanyInfo."OneDrive Refresh Token".CreateOutStream(OutStr);
            OutStr.WriteText(RefreshToken);
        end;

        if StatusInfo.Get('access_token', JnodeEntryToken) then begin
            AccessToken := JnodeEntryToken.AsValue().AsText();
            CompanyInfo."OneDrive Access Token".CreateOutStream(OutStr);
            OutStr.WriteText(AccessToken);
            Id := AccessToken;

            if StatusInfo.Get('expires_in', JnodeEntryToken) then begin
                CompanyInfo."OneDrive Token Expiration" := CurrentDateTime + (JnodeEntryToken.AsValue().AsInteger() * 1000);
            end else begin
                CompanyInfo."OneDrive Token Expiration" := CurrentDateTime + 3600000; // 1 hora por defecto
            end;
        end;

        CompanyInfo.Modify(true);
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
    begin
        CompanyInfo.Get();
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
            Error('The request to the token endpoint failed.');

        HttpResponse.Content().ReadAs(JsonText);

        if not HttpResponse.IsSuccessStatusCode() then
            Error('The token endpoint returned an error. Status: %1, Body: %2', HttpResponse.HttpStatusCode(), JsonText);

        StatusInfo.ReadFrom(JsonText);

        if StatusInfo.Get('access_token', JnodeEntryToken) then begin
            AccessToken := JnodeEntryToken.AsValue().AsText();
            CompanyInfo."OneDrive Access Token".CreateOutStream(OutStr);
            OutStr.WriteText(AccessToken);
            Id := AccessToken;

            if StatusInfo.Get('expires_in', JnodeEntryToken) then begin
                CompanyInfo."OneDrive Token Expiration" := CurrentDateTime + (JnodeEntryToken.AsValue().AsInteger() * 1000);
            end else begin
                CompanyInfo."OneDrive Token Expiration" := CurrentDateTime + 3600000; // 1 hora por defecto
            end;

            if StatusInfo.Get('refresh_token', JnodeEntryToken) then begin
                RefreshToken := JnodeEntryToken.AsValue().AsText();
                CompanyInfo."OneDrive Refresh Token".CreateOutStream(OutStr);
                OutStr.WriteText(RefreshToken);
            end;
        end;
        CompanyInfo.Modify(true);
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

    begin
        Ticket := Format(Token());

        // Construir la ruta del archivo
        Url := graph_endpoint + upload_endpoint;
        Url := StrSubstNo(Url, Carpeta);
        //Falta Token
        Respuesta := RestApiOfset(Url, Ticket, RequestType::put, Base64Data);

        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('id', JTokenLink) then begin
            Id := JTokenLink.AsValue().AsText();
        end else
            Error(Respuesta);

        exit(Id);
    end;

    procedure DownloadFileB64(Carpeta: Text; var Base64Data: Text; Filename: Text; BajarFichero: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        Id: Text;
        TempBlob: Codeunit "Temp Blob";
        Int: Instream;
        Bs64: Codeunit "Base64 Convert";
        FilePath: Text;
    begin
        Ticket := Format(Token());

        // Primero necesitamos obtener el ID del archivo
        if Carpeta <> '' then
            FilePath := Carpeta + '/' + Filename
        else
            FilePath := Filename;

        Id := GetFileId(FilePath);

        if Id = '' then
            Error('Archivo no encontrado: %1', FilePath);

        Url := graph_endpoint + download_endpoint;
        Url := StrSubstNo(Url, Id);

        TempBlob.CreateInStream(Int);
        RestApiGetContentStream(Url, RequestType::Get, Int);
        Base64Data := Bs64.ToBase64(Int);

        if BajarFichero then begin
            DownloadFromStream(Int, 'Guardar', 'C:\Temp', 'ALL Files (*.*)|*.*', Filename);
        end;

        exit(Base64Data);
    end;



    procedure DeleteFolder(Carpeta: Text; HideDialog: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        Id: Text;
    begin
        if not HideDialog then
            if not Confirm('¿Está seguro de que desea eliminar la carpeta?', true) then
                exit('');

        Ticket := Format(Token());

        // Obtener el ID del archivo/carpeta
        Id := GetFileId(Carpeta);

        if Id = '' then
            Error('Carpeta no encontrada: %1', Carpeta);

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
    begin
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
    begin
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
    begin
        if FolderName = '' then
            exit(BaseFolderId);

        // Split path by '/'
        //PathParts := FolderPath.Split('/');
        //CurrentFolderId := BaseFolderId;
        NewFolderId := FindOrCreateSubfolder(BaseFolderId, FolderName, true);
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

    procedure DeleteFile(GetDocumentID: Text): Boolean
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        ResponseMessage: HttpResponseMessage;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
    begin
        Ticket := Format(Token());
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
        Ticket := Format(Token());

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
            Error('No se pudo autenticar con OneDrive. Por favor, verifique sus credenciales.');

        Ticket := Token();
        CompanyInfo.Get();
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

    procedure CreateOneDriveFolder(ParentFolderId: Text; FolderName: Text; RootFolder: Boolean): Text
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
                Error('Failed to create folder in OneDrive: %1', Respuesta);
        end;
        exit(NewFolderId);
    end;
}