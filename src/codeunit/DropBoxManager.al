codeunit 95103 "DropBox Manager"
{
    permissions = tabledata "Company Information" = RIMD,
                  tabledata "Document Attachment" = RIMD,
                  tabledata "Name/Value Buffer" = RIMD;

    var
        CompanyInfo: Record "Company Information";
        get_metadata: Label '2/files/get_metadata';
        create_folder: Label '2/files/create_folder_v2';
        move_folder: Label '2/files/move_v2';
        move_file: Label '2/files/move_v2';
        sharefolder: Label '2/sharing/share_folder';
        list_folfer_members: Label '/2/sharing/list_folder_members';
        list_folder: Label '2/files/list_folder';
        list_folder_continue: Label '2/files/list_folder/continue';
        delete: Label '2/files/delete_v2';
        grant_type_authorization_code: Label 'authorization_code';
        grant_type_refresh_token: Label 'refresh_token';
        oauth2_token: Label 'oauth2/token';
        get_temporary_link: Label '2/files/get_temporary_link';
        create_shared_link: Label '2/sharing/create_shared_link_with_settings';
        Upload: Label '2/files/get_temporary_upload_link';

        // Message Labels
        AuthErrorMsg: Label '❌ Could not authenticate with DropBox. Please check your credentials.';
        NoRefreshTokenMsg: Label 'No refresh token configured for DropBox.';
        NoResponseMsg: Label 'No response received from DropBox server.';
        FileAccessErrorMsg: Label 'Error accessing file: %1';
        FileLinkErrorMsg: Label 'Could not get file link. Check that the file ID is correct and you have permission.';
        EditFileErrorMsg: Label 'Error opening file in browser: %1';
        FolderNotFoundMsg: Label 'Folder not found: %1';
        CreateFolderErrorMsg: Label 'Error creating folder';
        UploadErrorMsg: Label 'Error uploading file to Strapi: %1';
        // Confirmation Labels
        DeleteFolderConfirmMsg: Label 'Are you sure you want to delete the folder?';
        DropBoxCode: Label 'DropBox Code';

    procedure Initialize()
    begin
        CompanyInfo.Get();
    end;

    procedure Authenticate(): Boolean
    var
        DriveTokenManagement: Record "Drive Token Management";
    begin
        If not DriveTokenManagement.Get(DriveTokenManagement."Storage Provider"::"DropBox") then begin
            DriveTokenManagement.Init();
            DriveTokenManagement."Storage Provider" := DriveTokenManagement."Storage Provider"::"DropBox";
            DriveTokenManagement.Insert();
        end;
        // Verificar si el token está válido
        if DriveTokenManagement."Token Expiration" < CurrentDateTime then
            RefreshAccessToken();

        exit(DriveTokenManagement."Token Status" = DriveTokenManagement."Token Status"::Valid);
    end;

    procedure StartOAuthFlow()
    var
        OAuthURL: Text;
        Ventana: Page "Dialogo Dropbox";
        CodeDropBox: Text;
    begin
        CompanyInfo.Get();
        Hyperlink('https://www.dropbox.com/oauth2/authorize?client_id=' + CompanyInfo."DropBox App Key" + '&response_type=code&token_access_type=offline');
        Ventana.SetTexto(DropBoxCode);
        Ventana.RunModal();
        Ventana.GetTexto(CodeDropBox);
        ObtenerToken(CodeDropBox);
        // // TODO: Implementar flujo OAuth de DropBox
        // // Construir URL de autorización de DropBox
        // OAuthURL := 'https://www.dropbox.com/oauth2/authorize?' +
        //            'client_id=' + CompanyInfo."DropBox App Key" +
        //            '&response_type=code' +
        //            '&redirect_uri=https://oauth.pstmn.io/v1/callback';

        // // Abrir navegador o mostrar URL
        // Hyperlink(OAuthURL);
    end;

    procedure RefreshAccessToken()
    var
        DriveTokenManagement: Record "Drive Token Management";
    begin
        If not DriveTokenManagement.Get(DriveTokenManagement."Storage Provider"::"DropBox") then begin
            DriveTokenManagement.Init();
            DriveTokenManagement."Storage Provider" := DriveTokenManagement."Storage Provider"::"DropBox";
            DriveTokenManagement.Insert();
        end;
        if DriveTokenManagement."Refresh Token".HasValue then
            Error(NoRefreshTokenMsg);

        RefreshToken();
    end;

    procedure ValidateConfiguration(): Boolean
    begin
        if CompanyInfo."DropBox App Key" = '' then
            exit(false);
        if CompanyInfo."DropBox App Secret" = '' then
            exit(false);
        if not CompanyInfo."DropBox Access Token".HasValue then
            exit(false);

        exit(true);
    end;

    procedure GetUrl(DocumentID: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Json: Text;
        Body: JsonObject;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokenLink: JsonToken;
    begin
        if DocumentID = '' then
            exit('');

        Ticket := Token();
        Url := CompanyInfo."Url Api DropBox" + get_temporary_link;

        Clear(Body);
        Body.Add('path', DocumentID);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('link', JTokenLink) then
            exit(JTokenLink.AsValue().AsText());

        exit('');
    end;

    procedure Token(): Text
    var
        DriveTokenManagement: Record "Drive Token Management";
    begin
        If not DriveTokenManagement.Get(DriveTokenManagement."Storage Provider"::"DropBox") then begin
            DriveTokenManagement.Init();
            DriveTokenManagement."Storage Provider" := DriveTokenManagement."Storage Provider"::"DropBox";
            DriveTokenManagement.Insert();
        end;
        if DriveTokenManagement."Token Expiration" < CurrentDateTime then
            RefreshToken();

        exit(DriveTokenManagement.GetAccessToken());
    end;

    procedure ObtenerToken(CodeDropbox: Text): Text
    var
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Json: Text;
        StatusInfo: JsonObject;
        JnodeEntryToken: JsonToken;
        Id: Text;
        Respuesta: Text;
        DriveTokenManagement: Record "Drive Token Management";
    begin
        If not DriveTokenManagement.Get(DriveTokenManagement."Storage Provider"::"DropBox") then begin
            DriveTokenManagement.Init();
            DriveTokenManagement."Storage Provider" := DriveTokenManagement."Storage Provider"::"DropBox";
            DriveTokenManagement.Insert();
        end;

        Url := CompanyInfo."Url Api DropBox" + oauth2_token + '?code=' + CodeDropbox + '&grant_type=authorization_code';
        Respuesta := RestApi(Url, RequestType::post, Json, CompanyInfo."DropBox App Key", CompanyInfo."DropBox App Secret");
        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);
        // {
        //     "access_token": "sl.u.AbX9y6Fe3AuH5o66-gmJpR032jwAwQPIVVzWXZNkdzcYT02akC2de219dZi6gxYPVnYPrpvISRSf9lxKWJzYLjtMPH-d9fo_0gXex7X37VIvpty4-G8f4-WX45AcEPfRnJJDwzv-",
        //     "expires_in": 14400,
        //     "token_type": "bearer",
        //     "scope": "account_info.read files.content.read files.content.write files.metadata.read",
        //     "refresh_token": "nBiM85CZALsAAAAAAAAAAQXHBoNpNutK4ngsXHsqW4iGz9tisb3JyjGqikMJIYbd",
        //     "account_id": "dbid:AAH4f99T0taONIb-OurWxbNQ6ywGRopQngc",
        //     "uid": "12345"
        // }
        //recuperar AccessToken y refresh_token

        If StatusInfo.Get('refresh_token', JnodeEntryToken) Then begin
            Id := JnodeEntryToken.AsValue().AsText();
            CompanyInfo."DropBox Refresh Token" := Id;
            DriveTokenManagement.SetRefreshToken(Id);
            //Añadir 4 horas a la fecha actual
            CompanyInfo."DropBox Token Expiration" := CurrentDateTime + 14400000;
            if CompanyInfo.WritePermission() then
                CompanyInfo.Modify();
        end;

        If StatusInfo.Get('access_token', JnodeEntryToken) Then begin
            Id := JnodeEntryToken.AsValue().AsText();
            CompanyInfo.SetTokenDropbox(Id);
            DriveTokenManagement.SetAccessToken(Id);
            if CompanyInfo.WritePermission() then
                CompanyInfo.Modify();
        end;
        Commit;
        exit(id);
    end;

    procedure RefreshToken(): Text
    var
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Json: Text;
        StatusInfo: JsonObject;
        JnodeEntryToken: JsonToken;
        Id: Text;
        DriveTokenManagement: Record "Drive Token Management";
    begin
        If not DriveTokenManagement.Get(DriveTokenManagement."Storage Provider"::"DropBox") then begin
            DriveTokenManagement.Init();
            DriveTokenManagement."Storage Provider" := DriveTokenManagement."Storage Provider"::"DropBox";
            DriveTokenManagement.Insert();
        end;
        Url := CompanyInfo."Url Api DropBox" + oauth2_token + '?refresh_token=' + CompanyInfo."DropBox Refresh Token" + '&grant_type=refresh_token';
        Json := RestApi(Url, RequestType::post, '', CompanyInfo."DropBox App Key", CompanyInfo."DropBox App Secret");

        StatusInfo.ReadFrom(Json);

        if StatusInfo.Get('access_token', JnodeEntryToken) then begin
            Id := JnodeEntryToken.AsValue().AsText();
            CompanyInfo.SetTokenDropbox(Id);
            DriveTokenManagement.SetAccessToken(Id);
            CompanyInfo."DropBox Token Expiration" := CurrentDateTime + 14400000; // 4 horas
            if CompanyInfo.WritePermission() then
                CompanyInfo.Modify();
        end;

        exit(Id);
    end;

    procedure UploadFile(Carpeta: Text; var DocumentAttach: Record "Document Attachment"): Text
    var
        DocumentStream: OutStream;
        TempBlob: Codeunit "Temp Blob";
        Int: Instream;
    begin
        TempBlob.CreateOutStream(DocumentStream);
        DocumentAttach."Document Reference ID".ExportStream(DocumentStream);
        TempBlob.CreateInStream(Int);

        exit(UploadFileB64(Carpeta, Int, DocumentAttach."File Name"));
    end;

    procedure UploadFileB64(Carpeta: Text; Base64Data: InStream; Filename: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        comit_info: JsonObject;
        Json: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Respuesta: Text;
        Id: Text;
    begin
        Ticket := Token();
        Url := CompanyInfo."Url Api DropBox" + Upload;

        Clear(comit_info);
        comit_info.Add('autorename', true);
        comit_info.Add('mode', 'add');
        comit_info.Add('mute', false);
        comit_info.Add('path', '/' + Carpeta + '/' + FileName);
        comit_info.Add('strict_conflict', false);

        Clear(Body);
        Body.Add('commit_info', comit_info);
        Body.Add('duration', 14400);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('link', JTokenLink) then begin
            Id := JTokenLink.AsValue().AsText();
        end;

        Clear(Body);
        Respuesta := RestApiOfset(Id, RequestType::post, Base64Data);

        Clear(StatusInfo);
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('content-hash', JTokenLink) then begin
            Id := JTokenLink.AsValue().AsText();
        end else
            Error(UploadErrorMsg, Respuesta);

        exit(Id);
    end;

    procedure DownloadFileB64(Carpeta: Text; Filename: Text; BajarFichero: Boolean; var Base64Data: Text): Boolean
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        Json: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Respuesta: Text;
        Id: Text;
        TempBlob: Codeunit "Temp Blob";
        Int: Instream;
        Bs64: Codeunit "Base64 Convert";
    begin
        Ticket := Token();
        Url := CompanyInfo."Url Api DropBox" + get_temporary_link;

        Clear(Body);
        if Carpeta <> '' then
            Body.Add('path', '/' + Carpeta + '/' + FileName)
        else
            Body.Add('path', '/' + FileName);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('link', JTokenLink) then begin
            Id := JTokenLink.AsValue().AsText();
        end;

        TempBlob.CreateInStream(Int);
        RestApiGetContentStream(Id, RequestType::Get, Int);
        Base64Data := Bs64.ToBase64(Int);

        if BajarFichero then begin
            DownloadFromStream(Int, 'Guardar', 'C:\Temp', 'ALL Files (*.*)|*.*', Filename);
        end;

        exit(true);
    end;


    procedure CreateFolder(Carpeta: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Json: Text;
        Body: JsonObject;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokO: JsonToken;
        JnodeEntryToken: JsonToken;
        Id: Text;
        JsonEntry: JsonObject;
    begin
        Ticket := Token();
        Url := CompanyInfo."Url Api DropBox" + create_folder;

        Clear(Body);
        Body.Add('autorename', false);
        Body.add('path', '/' + Carpeta);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('metadata', JTokO) then begin
            if JTokO.IsObject() then begin
                JsonEntry := JTokO.AsObject();
                if JsonEntry.Get('id', JnodeEntryToken) then begin
                    Id := JnodeEntryToken.AsValue().AsText();
                end;
            end;
        end;

        if StrPos(Id, 'id') = 0 then begin
            if StatusInfo.Get('error_summary', JTokO) then begin
                Error(JTokO.AsValue().AsText());
            end;
            Error(CreateFolderErrorMsg);
        end;

        exit(Id);
    end;

    procedure DeleteFolder(Carpeta: Text; HideDialog: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Json: Text;
        Body: JsonObject;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokO: JsonToken;
        JnodeEntryToken: JsonToken;
        Id: Text;
        JsonEntry: JsonObject;
    begin
        if not HideDialog then
            if not Confirm(DeleteFolderConfirmMsg, true) then
                exit('');

        Ticket := Token();
        if CopyStr(Carpeta, 1, 1) = '/' then
            Carpeta := CopyStr(Carpeta, 2);

        Url := CompanyInfo."Url Api DropBox" + delete;

        Clear(Body);
        Body.add('path', '/' + Carpeta);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('metadata', JTokO) then begin
            if JTokO.IsObject() then begin
                JsonEntry := JTokO.AsObject();
                if JsonEntry.Get('id', JnodeEntryToken) then begin
                    Id := JnodeEntryToken.AsValue().AsText();
                end;
            end;
        end;

        exit(Id);
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
        CreateBasicAuthHeader(User, Pass, Client);

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

    procedure RestApiOfset(url: Text; RequestType: Option Get,patch,put,post,delete; payload: instream): Text
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
                    contentHeaders.Add('Content-Type', 'application/json');
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

    procedure CreateBasicAuthHeader(UserName: Text[50]; Password: Text[50]; var HttpClient: HttpClient)
    var
        AuthString: Text;
        TypeHelper: Codeunit "Base64 Convert";
    begin
        AuthString := STRSUBSTNO('%1:%2', UserName, Password);
        AuthString := TypeHelper.ToBase64(AuthString);
        AuthString := STRSUBSTNO('Basic %1', AuthString);
        HttpClient.DefaultRequestHeaders().Add('Authorization', AuthString);
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
        Body: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JEntries: JsonArray;
        JEntry: JsonObject;
        JEntryToken: JsonToken;
        JEntryTokens: JsonToken;
        a: Integer;
        FilesTemp: Record "Name/Value Buffer" temporary;
        ItemType: Text;
        ItemName: Text;
        ItemId: Text;
        ItemPath: Text;
    begin
        Files.DeleteAll();
        Ticket := Token();
        Url := CompanyInfo."Url Api DropBox" + list_folder;

        // Construir el cuerpo de la petición
        Clear(Body);
        if SoloSubfolder and (FolderId <> '') then begin
            // Listar contenido de una carpeta específica
            Body.Add('path', FolderId);
        end else begin
            // Listar contenido de la carpeta raíz
            Body.Add('path', '');
        end;
        Body.Add('recursive', false);
        Body.Add('include_media_info', false);
        Body.Add('include_deleted', false);
        Body.Add('include_has_explicit_shared_members', false);
        Body.Add('include_mounted_folders', true);
        Body.Add('limit', 20);
        Body.Add('shared_link_policy', 'none');
        Body.Add('include_property_groups', 'none');
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);

            if StatusInfo.Get('entries', JEntryToken) then begin
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

                    // Obtener la ruta del elemento
                    if JEntry.Get('.tag', JEntryToken) then
                        ItemType := JEntryToken.AsValue().AsText()
                    else
                        ItemType := '';

                    // Crear registro temporal
                    FilesTemp.Init();
                    a += 1;
                    FilesTemp.ID := a;
                    FilesTemp.Name := ItemName;
                    FilesTemp."Google Drive ID" := ItemId; // Reutilizamos el campo para DropBox ID
                    FilesTemp."Google Drive Parent ID" := FolderId; // Reutilizamos el campo para Parent ID

                    // Determinar si es carpeta o archivo
                    if ItemType = 'folder' then
                        FilesTemp.Value := 'Carpeta'
                    else
                        FilesTemp.Value := '';

                    // Si es archivo, obtener la extensión
                    if ItemType <> 'folder' then begin
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

    internal procedure CreateFolderStructure(Folder: Text; SubFolder: Text): Text
    var
        PathParts: List of [Text];
        CurrentPath: Text;
        FolderName: Text;
        NewFolderPath: Text;
        i: Integer;
        FullPath: Text;
    begin
        if SubFolder = '' then
            exit(Folder);

        // Construir la ruta completa
        if Folder <> '' then
            FullPath := Folder + '/' + SubFolder
        else
            FullPath := SubFolder;

        // Split path by '/'
        PathParts := FullPath.Split('/');
        CurrentPath := '';

        for i := 1 to PathParts.Count do begin
            FolderName := PathParts.Get(i);
            if FolderName <> '' then begin
                // Construir la ruta actual
                if CurrentPath = '' then
                    NewFolderPath := '/' + FolderName
                else
                    NewFolderPath := CurrentPath + '/' + FolderName;

                // Verificar si la carpeta ya existe
                if not FolderExists(NewFolderPath) then begin
                    // Crear la carpeta si no existe
                    CreateFolder(NewFolderPath);
                end;

                CurrentPath := NewFolderPath;
            end;
        end;

        exit(CurrentPath);
    end;

    internal procedure DeleteFile(GetDocumentID: Text): Boolean
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        ResponseMessage: HttpResponseMessage;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
    begin
        Ticket := Token();
        Url := CompanyInfo."Url Api DropBox" + delete;
        Url := StrSubstNo(Url, GetDocumentID);
        ResponseMessage := RestApiTokenResponse(Url, Ticket, RequestType::delete, '');
        if ResponseMessage.IsSuccessStatusCode() then
            exit(true)
        else
            exit(false);
    end;

    internal procedure OpenFileInBrowser(DropBoxID: Text[250])
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        Link: Text;
        ErrorMessage: Text;
    begin
        if not Authenticate() then
            Error(AuthErrorMsg);

        Ticket := Token();
        CompanyInfo.Get();

        // Obtener enlace temporal del archivo
        Url := CompanyInfo."Url Api DropBox" + get_temporary_link;

        Clear(Body);
        Body.Add('path', DropBoxID);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta = '' then
            Error(NoResponseMsg);

        StatusInfo.ReadFrom(Respuesta);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            Error(FileAccessErrorMsg, ErrorMessage);
        end;

        // Obtener el enlace temporal
        if StatusInfo.Get('link', JToken) then begin
            Link := JToken.AsValue().AsText();
            Hyperlink(Link);
        end else begin
            Error(FileLinkErrorMsg);
        end;
    end;

    internal procedure CreateSubfolderStructure(Id: Text; SubFolder: Text): Text
    begin
        if SubFolder = '' then
            exit(Id);

        exit(FindOrCreateSubfolder(Id, SubFolder, false));
    end;

    internal procedure OptenerPath(DropBoxID: Text[250]): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Body: JsonObject;
        Json: Text;
        Path: Text;
    begin
        //POST https://api.dropboxapi.com/2/files/get_metadata
        Url := CompanyInfo."Url Api DropBox" + get_metadata;
        // {
        // "file": "id:abc123xyz",
        // "include_media_info": false
        // }

        Clear(Body);
        Body.Add('file', DropBoxID);
        Body.Add('include_media_info', false);
        Body.WriteTo(Json);
        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);
        // {
        // "id": "id:abc123xyz",
        // "name": "factura.pdf",
        // "path_lower": "/misfacturas/2025/factura.pdf",
        // "path_display": "/MisFacturas/2025/Factura.pdf",
        // "client_modified": "...",
        // ...
        // }

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('path_display', JTokenLink) then begin
                Path := JTokenLink.AsValue().AsText();
                if Path.EndsWith('/') then
                    Path := CopyStr(Path, 1, StrLen(Path) - 1);
                exit(Path);
            end;
        end;
        exit('');
    end;

    internal procedure EditFile(DropBoxID: Text[250])
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        Settings: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        Link: Text;
        ErrorMessage: Text;
    begin
        if not Authenticate() then
            Error(AuthErrorMsg);

        Ticket := Token();
        CompanyInfo.Get();

        // Obtener enlace temporal del archivo
        Url := CompanyInfo."Url Api DropBox" + create_shared_link;

        Clear(Body);
        Body.Add('path', DropBoxID);
        Settings.Add('requested_visibility', 'public');
        Body.Add('settings', Settings);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta = '' then
            Error(NoResponseMsg);

        StatusInfo.ReadFrom(Respuesta);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            Error(FileAccessErrorMsg, ErrorMessage);
        end;

        // Obtener el enlace temporal
        if StatusInfo.Get('url', JToken) then begin
            Link := JToken.AsValue().AsText();
            Hyperlink(Link);
        end else begin
            Error(FileLinkErrorMsg);
        end;
    end;

    internal procedure RenameFolder(RootFolderID: Text[250]; RootFolder: Text[250]): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        Json: Text;
        Respuesta: Text;
    begin
        Ticket := Token();
        Url := CompanyInfo."Url Api DropBox" + move_folder;
        Clear(Body);
        Body.Add('from_path', RootFolderID);
        Body.Add('to_path', RootFolder);
        Body.WriteTo(Json);
        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);
        exit(Respuesta);
    end;

    internal procedure MoveFile(DropBoxID: Text[250]; destino: Text; Name: Text; Mover: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Id: Text;
    begin
        Ticket := Token();
        Url := CompanyInfo."Url Api DropBox" + move_file;
        Clear(Body);
        Body.Add('from_path', DropBoxID);
        Body.Add('to_path', destino);
        if Mover then
            Body.Add('autorename', true);
        Body.WriteTo(Json);
        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);
        if StatusInfo.Get('link', JTokenLink) then begin
            Id := JTokenLink.AsValue().AsText();
            exit(Id);
        end;
        exit(DropBoxID);
    end;

    procedure GetFolderMapping(TableID: Integer; Var Id: Text): Record "Google Drive Folder Mapping"
    var
        FolderMapping: Record "Google Drive Folder Mapping";
    begin
        FolderMapping.SetRange("Table ID", TableID);
        if FolderMapping.FindFirst() then
            Id := FolderMapping."Default Folder ID";
        exit(FolderMapping);
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
        exit(CreateFolder(FolderName, ParentFolderId, false));
    end;

    procedure CreateFolder(FolderName: Text; ParentFolderId: Text; RootFolder: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
    begin
        Ticket := Token();
        Url := CompanyInfo."Url Api DropBox" + create_folder;
        Clear(Body);
        if RootFolder then
            Body.Add('path', FolderName)
        else
            Body.Add('path', ParentFolderId + '/' + FolderName);
        Body.Add('autorename', false);
        Body.WriteTo(Json);
        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);
        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('id', JToken) then
                exit(JToken.AsValue().AsText());
        end;
        exit('');
    end;

    local procedure FolderExists(FolderPath: Text): Boolean
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
    begin
        Ticket := Token();
        Url := CompanyInfo."Url Api DropBox" + get_metadata;

        Clear(Body);
        Body.Add('path', FolderPath);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            // Si no hay error, la carpeta existe
            if not StatusInfo.Get('error', JToken) then
                exit(true);
        end;

        exit(false);
    end;

    local procedure GetFileExtension(FileName: Text): Text
    var
        DotPosition: Integer;
    begin
        DotPosition := StrPos(FileName, '.');
        if DotPosition > 0 then
            exit(CopyStr(FileName, DotPosition + 1))
        else
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
        JEntries: JsonArray;
        JEntry: JsonObject;
        JEntryToken: JsonToken;
        JEntryTokens: JsonToken;
        ItemType: Text;
        a: Integer;
        FullPath: Text;
        Found: Boolean;
        ResultId: Text;
    begin
        Files.DeleteAll();
        if not Authenticate() then
            Error(AuthErrorMsg);

        Ticket := Token();
        CompanyInfo.Get();
        Url := CompanyInfo."Url Api DropBox" + list_folder;

        if RootFolder then
            IdCarpeta := ''
        else
            if IdCarpeta = CompanyInfo."Root Folder" then
                IdCarpeta := '';


        Clear(Body);
        Body.Add('path', IdCarpeta);
        Body.Add('recursive', false);
        Body.Add('include_media_info', false);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);

            if StatusInfo.Get('entries', JEntryToken) then begin
                JEntries := JEntryToken.AsArray();
                a := 0;

                foreach JEntryTokens in JEntries do begin
                    JEntry := JEntryTokens.AsObject();
                    a += 1;
                    Files.Init();
                    Files.ID := a;

                    if JEntry.Get('name', JEntryToken) then
                        Files.Name := JEntryToken.AsValue().AsText();

                    if JEntry.Get('.tag', JEntryToken) then
                        ItemType := JEntryToken.AsValue().AsText();

                    if JEntry.Get('id', JEntryToken) then
                        Files."Google Drive ID" := JEntryToken.AsValue().AsText();

                    if ItemType = 'folder' then
                        Files.Value := 'Carpeta'
                    else begin
                        Files.Value := '';
                        Files."File Extension" := GetFileExtension(Files.Name);
                    end;

                    Files.Insert();

                    if (ItemType = 'folder') and (Files.Name = Carpeta) then begin
                        Found := true;
                        ResultId := Files."Google Drive ID";
                    end;
                end;
            end;
        end;

        if Found then
            exit(ResultId);

        if Crear then begin
            if IdCarpeta = '' then
                FullPath := '/' + Carpeta
            else
                FullPath := IdCarpeta + '/' + Carpeta;

            ResultId := CreateDropBoxFolder(FullPath);
            exit(ResultId);
        end;

        exit('');
    end;

    local procedure CreateDropBoxFolder(FolderPath: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        JMetadata: JsonObject;
        NewFolderId: Text;
    begin
        Ticket := Token();
        CompanyInfo.Get();
        Url := CompanyInfo."Url Api DropBox" + create_folder;

        Clear(Body);
        Body.Add('path', FolderPath);
        Body.Add('autorename', false);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);
        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('metadata', JToken) then begin
                JMetadata := JToken.AsObject();
                if JMetadata.Get('id', JToken) then
                    NewFolderId := JToken.AsValue().AsText();
            end else begin
                if StatusInfo.Get('error_summary', JToken) then
                    if StrPos(JToken.AsValue().AsText(), 'path/conflict/folder') > 0 then begin
                        exit(GetFolderId(FolderPath));
                    end;
                Error(CreateFolderErrorMsg, Respuesta);
            end;
        end;
        exit(NewFolderId);
    end;

    local procedure GetFolderId(FolderPath: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        FolderId: Text;
    begin
        Ticket := Token();
        Url := CompanyInfo."Url Api DropBox" + get_metadata;

        Clear(Body);
        Body.Add('path', FolderPath);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('id', JToken) then
                FolderId := JToken.AsValue().AsText();
        end;

        exit(FolderId);
    end;
}