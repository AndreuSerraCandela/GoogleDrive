codeunit 95106 "SharePoint Manager"
{
    var
        CompanyInfo: Record "Company Information";
        // Endpoints de SharePoint API
        auth_endpoint: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/authorize';
        token_endpoint: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token';
        graph_endpoint: Label 'https://graph.microsoft.com/v1.0';
        site_endpoint: Label '/sites/%1'; // %1 = site-id o site-name
        drive_endpoint: Label '/sites/%1/drive';
        files_endpoint: Label '/sites/%1/drive/root:/%2:/children'; // %1 = site-id, %2 = path
        upload_endpoint: Label '/sites/%1/drive/root:/%2:/content'; // %1 = site-id, %2 = path/filename
        download_endpoint: Label '/sites/%1/drive/items/%2/content'; // %1 = site-id, %2 = item-id

    procedure Initialize()
    begin
        CompanyInfo.Get();
    end;

    procedure Authenticate(): Boolean
    begin
        CompanyInfo.Get();
        CompanyInfo.CalcFields("SharePoint Access Token");
        if not CompanyInfo."SharePoint Access Token".HasValue then
            StartOAuthFlow()
        else
            if CompanyInfo."SharePoint Token Expiration" < CurrentDateTime then
                RefreshAccessToken();
        exit(CompanyInfo."SharePoint Access Token".HasValue);
    end;

    procedure StartOAuthFlow()
    var
        OAuthURL: Text;
    begin
        OAuthURL := StrSubstNo(auth_endpoint, CompanyInfo."SharePoint Tenant ID") +
                   '?client_id=' + CompanyInfo."SharePoint Client ID" +
                   '&response_type=code' +
                   '&scope=Sites.ReadWrite.All%20offline_access' +
                   '&redirect_uri=https://login.microsoftonline.com/common/oauth2/nativeclient' +
                   '&state=12345' +
                   '&response_mode=query';
        Hyperlink(OAuthURL);
    end;

    procedure RefreshAccessToken()
    begin
        CompanyInfo.CalcFields("SharePoint Access Token", "SharePoint Refresh Token");
        if not CompanyInfo."SharePoint Access Token".HasValue Then
            ObtenerToken(CompanyInfo."Code SharePoint");
        if not CompanyInfo."SharePoint Refresh Token".HasValue then
            Error('No hay refresh token configurado para SharePoint.');
        RefreshToken();
    end;

    procedure ObtenerToken(CodeSharePoint: Text): Text
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
        Url := StrSubstNo(token_endpoint, CompanyInfo."SharePoint Tenant ID");

        BodyText := 'grant_type=authorization_code' +
                    '&code=' + UrlEncode(CodeSharePoint) +
                    '&redirect_uri=' + UrlEncode(RedirectURI) +
                    '&client_id=' + UrlEncode(CompanyInfo."SharePoint Client ID") +
                    '&client_secret=' + UrlEncode(CompanyInfo."SharePoint Client Secret") +
                    '&scope=' + UrlEncode('Sites.ReadWrite.All offline_access');

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
            CompanyInfo."SharePoint Refresh Token".CreateOutStream(OutStr);
            OutStr.WriteText(RefreshToken);
        end;

        if StatusInfo.Get('access_token', JnodeEntryToken) then begin
            AccessToken := JnodeEntryToken.AsValue().AsText();
            CompanyInfo."SharePoint Access Token".CreateOutStream(OutStr);
            OutStr.WriteText(AccessToken);
            Id := AccessToken;

            if StatusInfo.Get('expires_in', JnodeEntryToken) then begin
                CompanyInfo."SharePoint Token Expiration" := CurrentDateTime + (JnodeEntryToken.AsValue().AsInteger() * 1000);
            end else begin
                CompanyInfo."SharePoint Token Expiration" := CurrentDateTime + 3600000; // 1 hora por defecto
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
        Url := StrSubstNo(token_endpoint, CompanyInfo."SharePoint Tenant ID");

        CompanyInfo.CalcFields("SharePoint Refresh Token");
        if CompanyInfo."SharePoint Refresh Token".HasValue then begin
            CompanyInfo."SharePoint Refresh Token".CreateInStream(InStr);
            InStr.ReadText(OldRefreshToken);
        end;

        BodyText := 'grant_type=refresh_token' +
                    '&refresh_token=' + UrlEncode(OldRefreshToken) +
                    '&client_id=' + UrlEncode(CompanyInfo."SharePoint Client ID") +
                    '&client_secret=' + UrlEncode(CompanyInfo."SharePoint Client Secret") +
                    '&scope=' + UrlEncode('Sites.ReadWrite.All offline_access');

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
            CompanyInfo."SharePoint Access Token".CreateOutStream(OutStr);
            OutStr.WriteText(AccessToken);
            Id := AccessToken;

            if StatusInfo.Get('expires_in', JnodeEntryToken) then begin
                CompanyInfo."SharePoint Token Expiration" := CurrentDateTime + (JnodeEntryToken.AsValue().AsInteger() * 1000);
            end else begin
                CompanyInfo."SharePoint Token Expiration" := CurrentDateTime + 3600000; // 1 hora por defecto
            end;

            if StatusInfo.Get('refresh_token', JnodeEntryToken) then begin
                RefreshToken := JnodeEntryToken.AsValue().AsText();
                CompanyInfo."SharePoint Refresh Token".CreateOutStream(OutStr);
                OutStr.WriteText(RefreshToken);
            end;
        end;
        CompanyInfo.Modify(true);
        exit(Id);
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

    procedure Token(): Text
    var
        AccessToken: Text;
        InStr: InStream;
    begin
        CompanyInfo.Get();
        if CompanyInfo."SharePoint Token Expiration" < CurrentDateTime then
            RefreshAccessToken();

        CompanyInfo.CalcFields("SharePoint Access Token");
        if CompanyInfo."SharePoint Access Token".HasValue then begin
            CompanyInfo."SharePoint Access Token".CreateInStream(InStr);
            InStr.ReadText(AccessToken);
        end;
        exit(AccessToken);
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
        SiteId: Text;
    begin
        Ticket := Format(Token());
        SiteId := CompanyInfo."SharePoint Site ID";

        // Construir la ruta del archivo
        Url := graph_endpoint + upload_endpoint;
        Url := StrSubstNo(Url, SiteId, Carpeta + Filename + '.' + FileExtension);

        Respuesta := RestApiOfset(Url, Ticket, RequestType::put, Base64Data);

        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('id', JTokenLink) then begin
            Id := JTokenLink.AsValue().AsText();
        end else
            Error(Respuesta);

        exit(Id);
    end;

    procedure DownloadFileB64(SharePointID: Text[250]; FileName: Text; BajarFichero: Boolean; var Base64Data: Text): Boolean
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
        SiteId: Text;
    begin
        if not Authenticate() then
            Error('No se pudo autenticar con SharePoint. Por favor, verifique sus credenciales.');

        Ticket := Token();
        SiteId := CompanyInfo."SharePoint Site ID";
        Url := StrSubstNo(graph_endpoint + '/sites/%1/drive/items/%2?select=id,name,webUrl,@microsoft.graph.downloadUrl', SiteId, SharePointID);

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

    procedure DeleteFolder(Carpeta: Text; HideDialog: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        Id: Text;
        SiteId: Text;
    begin
        if not HideDialog then
            if not Confirm('¿Está seguro de que desea eliminar la carpeta?', true) then
                exit('');

        Ticket := Format(Token());
        SiteId := CompanyInfo."SharePoint Site ID";

        // Obtener el ID del archivo/carpeta
        Id := GetFileId(Carpeta);

        if Id = '' then
            Error('Carpeta no encontrada: %1', Carpeta);

        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + Id;

        Respuesta := RestApiToken(Url, Ticket, RequestType::delete, '');

        exit(Id);
    end;

    local procedure GetFileId(FilePath: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokenLink: JsonToken;
        Id: Text;
        SiteId: Text;
    begin
        Ticket := Format(Token());
        SiteId := CompanyInfo."SharePoint Site ID";

        // Obtener información del archivo
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/root:/' + FilePath;

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
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokenLink: JsonToken;
        WebUrl: Text;
        SiteId: Text;
    begin
        Ticket := Format(Token());
        SiteId := CompanyInfo."SharePoint Site ID";

        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + FileId + '?select=webUrl';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('webUrl', JTokenLink) then begin
            WebUrl := JTokenLink.AsValue().AsText();
        end;

        exit(WebUrl);
    end;

    procedure GetUrl(DocumentID: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokenLink: JsonToken;
    begin
        if DocumentID = '' then
            exit('');

        Ticket := Format(Token());
        Url := graph_endpoint + download_endpoint;
        Url := StrSubstNo(Url, CompanyInfo."SharePoint Site ID", DocumentID);

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        // Para SharePoint, necesitamos obtener la URL de descarga web
        exit(GetWebUrl(DocumentID));
    end;

    procedure GetUrlLink(SharePointID: Text[250]): Text
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
        SiteId: Text;
    begin
        if not Authenticate() then
            Error('No se pudo autenticar con SharePoint. Por favor, verifique sus credenciales.');

        Ticket := Token();
        SiteId := CompanyInfo."SharePoint Site ID";
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + SharePointID + '/createLink';
        Json := '{"type": "view","scope": "anonymous"}';

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta = '' then
            Error('No se recibió respuesta del servidor de SharePoint.');

        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            Error('Error al acceder al archivo: %1', ErrorMessage);
        end;

        if StatusInfo.Get('link', JToken) then begin
            Link := JToken.AsObject();
            if Link.Get('webUrl', LinkToken) then begin
                WebUrl := LinkToken.AsValue().AsText();
                exit(WebUrl);
            end;
        end else begin
            Error('No se pudo obtener el enlace del archivo. Verifique que el ID del archivo sea correcto y que tenga permisos para acceder a él.');
        end;
    end;

    procedure OpenFileInBrowser(SharePointID: Text[250]; IsEdit: Boolean)
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
        SiteId: Text;
    begin
        if not Authenticate() then
            Error('No se pudo autenticar con SharePoint. Por favor, verifique sus credenciales.');

        Ticket := Token();
        SiteId := CompanyInfo."SharePoint Site ID";
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + SharePointID + '/createLink';
        Json := '{"type": "view","scope": "anonymous"}';
        if IsEdit then
            Json := '{"type": "edit","scope": "anonymous"}';
        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta = '' then
            Error('No se recibió respuesta del servidor de SharePoint.');

        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            Error('Error al acceder al archivo: %1', ErrorMessage);
        end;

        if StatusInfo.Get('link', JToken) then begin
            Link := JToken.AsObject();
            if Link.Get('webUrl', LinkToken) then begin
                WebUrl := LinkToken.AsValue().AsText();
                Hyperlink(WebUrl);
            end;
        end else begin
            Error('No se pudo obtener el enlace del archivo. Verifique que el ID del archivo sea correcto y que tenga permisos para acceder a él.');
        end;
    end;

    procedure EditFile(SharePointID: Text[250])
    begin
        OpenFileInBrowser(SharePointID, true);
    end;

    procedure DeleteFile(GetDocumentID: Text): Boolean
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        ResponseMessage: HttpResponseMessage;
        SiteId: Text;
    begin
        Ticket := Token();
        SiteId := CompanyInfo."SharePoint Site ID";
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + GetDocumentID;
        ResponseMessage := RestApiTokenResponse(Url, Ticket, RequestType::delete, '');

        if ResponseMessage.IsSuccessStatusCode() then
            exit(true)
        else
            exit(false);
    end;

    procedure Movefile(SharePointID: Text[250]; Destino: Text; arg: Text; Mover: Boolean; Filename: Text): Text
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
        SiteId: Text;
    begin
        if not Authenticate() then
            Error('No se pudo autenticar con SharePoint. Por favor, verifique sus credenciales.');

        Ticket := Token();
        SiteId := CompanyInfo."SharePoint Site ID";

        // Primero copiar el archivo al destino
        Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + SharePointID + '/copy';

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
                Error('Error al copiar el archivo: %1. Respuesta completa: %2', ErrorMessage, Respuesta);
            end;

            if StatusInfo.Get('id', JTokenLink) then begin
                CopiedFileId := JTokenLink.AsValue().AsText();
            end;
        end else begin
            // Buscar por nombre en la carpeta destino
            Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + Destino + '/children';
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
            if not DeleteFile(SharePointID) then begin
                Error('El archivo se copió pero no se pudo eliminar el original. ID del archivo copiado: %1', Filename);
            end;
        end;
        if CopiedFileId = '' then Error('No se pudo copiar el archivo');
        exit(CopiedFileId);
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
        SiteId: Text;
    begin
        Files.DeleteAll();
        Ticket := Token();
        SiteId := CompanyInfo."SharePoint Site ID";

        if SoloSubfolder then begin
            if FolderId <> '' then begin
                Url := graph_endpoint + '/sites/' + SiteId + '/drive/items/' + FolderId + '/children';
            end else begin
                Url := graph_endpoint + '/sites/' + SiteId + '/drive/root/children';
            end;
        end else begin
            Url := graph_endpoint + '/sites/' + SiteId + '/drive/root/children';
        end;

        Url := Url + '?$select=id,name,size,lastModifiedDateTime,folder,file,@microsoft.graph.downloadUrl';

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

                    if JEntry.Get('name', JEntryToken) then
                        ItemName := JEntryToken.AsValue().AsText()
                    else
                        ItemName := '';

                    if JEntry.Get('folder', JEntryToken) then begin
                        ItemType := 'Carpeta';
                    end else if JEntry.Get('file', JEntryToken) then begin
                        ItemType := '';
                    end else begin
                        ItemType := '';
                    end;

                    FilesTemp.Init();
                    a += 1;
                    FilesTemp.ID := a;
                    FilesTemp.Name := ItemName;
                    FilesTemp."Google Drive ID" := ItemId;
                    FilesTemp."Google Drive Parent ID" := FolderId;
                    FilesTemp.Value := ItemType;

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

    procedure FindOrCreateSubfolder(ParentFolderId: Text; FolderName: Text; SoloSubfolder: Boolean): Text
    var
        Files: Record "Name/Value Buffer" temporary;
        FolderId: Text;
        FoundFolder: Boolean;
    begin
        ListFolder(ParentFolderId, Files, SoloSubfolder);

        Files.Reset();
        if Files.FindSet() then begin
            repeat
                if (Files.Name = FolderName) and (Files.Value = 'Carpeta') then begin
                    FolderId := Files."Google Drive ID";
                    FoundFolder := true;
                end;
            until (Files.Next() = 0) or FoundFolder;
        end;

        if FoundFolder then
            exit(FolderId);

        exit(CreateSharePointFolder(ParentFolderId, FolderName, SoloSubfolder));
    end;

    procedure CreateSharePointFolder(ParentFolderId: Text; Foldername: Text; RootFolder: Boolean): Text
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
        SiteId: Text;
    begin
        Ticket := Token();
        SiteId := CompanyInfo."SharePoint Site ID";

        if RootFolder then
            Url := graph_endpoint + '/sites/' + SiteId + '/drive/root/children'
        else
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
                Error('Failed to create folder in SharePoint: %1 con esta url: %2 y este json: %3', Respuesta, Url, Json);
        end;
        exit(NewFolderId);
    end;

    local procedure GetFileExtension(FileName: Text): Text
    var
        FileMgt: Codeunit "File Management";
    begin
        exit(FileMgt.GetExtension(FileName));
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

    internal procedure RecuperaIdFolder(Id: Text; Folder: Text; var Files: Record "Name/Value Buffer" temporary; Crear: Boolean; RootFolder: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JEntryToken: JsonToken;
        CompaiInfo: Record "Company Information";
        Json: Text;
        JTok: JsonToken;
        JEntries: JsonArray;
        JEntryTokens: JsonToken;
        JEntry: JsonObject;

    begin
        CompaiInfo.Get();
        Id := CompaiInfo."SharePoint Site ID";
        Ticket := Token();
        Url := graph_endpoint + '/sites/' + Id + '/drive/root/children';
        Respuesta := RestApiToken(Url, Ticket, RequestType::Get, '');
        StatusInfo.ReadFrom(Respuesta);
        if StatusInfo.Get('value', JTok) Then begin
            JEntries := JTok.AsArray();
            foreach JEntryTokens in JEntries do begin
                JEntry := JEntryTokens.AsObject();
                if JEntry.Get('name', JEntryToken) then begin
                    if (JEntryToken.AsValue().AsText() = Folder) then begin //and (Not Borrado) then begin
                        if JEntry.Get('id', JEntryToken) then begin
                            Id := JEntryToken.AsValue().AsText();

                            exit(Id);
                        end;
                    end;
                end;
            end;
        end;
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

    internal procedure GetFolderMapping(TableID: Integer; Id: Text): Record "Google Drive Folder Mapping"
    var
        FolderMapping: Record "Google Drive Folder Mapping";
    begin
        FolderMapping.SetRange("Table ID", TableID);
        if FolderMapping.FindFirst() then
            Id := FolderMapping."Default Folder ID";
        exit(FolderMapping);
    end;
}