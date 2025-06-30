codeunit 95100 "Google Drive Manager"
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
        Upload: Label 'upload/drive/v3/files?uploadType=multipart';
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
        OrigenEstorage: Enum "Data Storage Provider";

    procedure Initialize()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.GET();
        ClientId := CompanyInfo."Google Client ID";
        SecretKey := CompanyInfo."Google Client Secret";
        // Use OOB (out-of-band) redirect URI for desktop applications
        RedirectURL := 'https://businesscentral.dynamics.com/OAuthLanding.htm';
        RedirectURL := 'https://developers.google.com/oauthplayground';
    end;

    procedure Authenticate(): Boolean
    var
        CompanyInfo: Record "Company Information";
        CurrentToken: Text;
    begin
        CompanyInfo.GET();

        // Check if we have a valid token
        if CompanyInfo."Token GoogleDrive" <> '' then begin
            // Check if token is still valid
            if CompanyInfo."Expiracion Token GoogleDrive" > CurrentDateTime then begin
                AccessToken := CompanyInfo."Token GoogleDrive";
                exit(true);
            end else begin
                // Token expired, try to refresh
                if RefreshAccessToken() then begin
                    CompanyInfo.GET();
                    AccessToken := CompanyInfo."Token GoogleDrive";
                    exit(true);
                end;
            end;
        end;

        // No valid token, need to start OAuth flow
        exit(StartOAuthFlow());
    end;

    procedure StartOAuthFlow(): Boolean
    var
        CompanyInfo: Record "Company Information";
        AuthUrl: Text;
        Scopes: Text;
        State: Text;
        EncodedScopes: Text;
        EncodedRedirectUri: Text;
    begin
        CompanyInfo.GET();

        // Validate required configuration
        if (CompanyInfo."Google Client ID" = '') or (CompanyInfo."Google Client Secret" = '') then begin
            Error('La configuración de Google Drive no está completa. Por favor, configure Client ID y Client Secret en la información de la empresa.');
        end;

        // Set default Auth URI if not configured
        if CompanyInfo."Google Auth URI" = '' then begin
            CompanyInfo."Google Auth URI" := 'https://accounts.google.com/o/oauth2/auth';
            CompanyInfo.Modify();
        end;

        // Build scopes and encode them
        Scopes := 'https://www.googleapis.com/auth/drive.file';// https://www.googleapis.com/auth/drive';
        EncodedScopes := UrlEncode(Scopes);

        // Encode redirect URI
        EncodedRedirectUri := UrlEncode(RedirectURL);

        // Generate state parameter for security
        State := CreateGuid();

        // Build authorization URL with proper parameter separation
        AuthUrl := CompanyInfo."Google Auth URI" +
                   '?client_id=' + CompanyInfo."Google Client ID" +
                   '&redirect_uri=https://developers.google.com/oauthplayground' +// EncodedRedirectUri +
                   '&scope=' + Scopes +
                   '&response_type=code' +
                   '&access_type=offline' +
                   '&state=' + State +
                   '&prompt=consent';

        // Store state for validation
        CompanyInfo."Google Project ID" := State; // Temporarily store state here
        CompanyInfo.Modify();

        // Try to open browser automatically, fallback to showing URL
        if not TryOpenBrowser(AuthUrl) then begin
            Message('Por favor, copie la siguiente URL en su navegador para autorizar el acceso a Google Drive:\%1', AuthUrl);
        end else begin
            Message('Se ha abierto el navegador para la autorización. Si no se abre automáticamente, copie esta URL:\%1', AuthUrl);
        end;

        exit(false); // User needs to complete OAuth flow manually
    end;

    local procedure TryOpenBrowser(Url: Text): Boolean
    begin
        // Try to open the URL in the default browser
        Hyperlink(Url);
        exit(true); // Assume success since Hyperlink doesn't return a value
    end;

    local procedure UrlEncode(InputText: Text): Text
    var
        Result: Text;
        i: Integer;
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

    procedure CompleteOAuthFlow(AuthorizationCode: Text; State: Text): Boolean
    var
        CompanyInfo: Record "Company Information";
        Client: HttpClient;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        JObject: JsonObject;
        JToken: JsonToken;
        RequestHeaders: HttpHeaders;
        TokenUrl: Text;
        PostData: Text;
    begin
        CompanyInfo.GET();

        // Validate state parameter
        if CompanyInfo."Google Project ID" <> State then begin
            Error('Estado de seguridad inválido. Por favor, reinicie el proceso de autenticación.');
        end;

        // Prepare token exchange request
        TokenUrl := CompanyInfo."Google Token URI";
        if TokenUrl = '' then
            TokenUrl := 'https://oauth2.googleapis.com/token';

        PostData := StrSubstNo('client_id=%1&client_secret=%2&code=%3&grant_type=authorization_code&redirect_uri=%4',
            CompanyInfo."Google Client ID",
            CompanyInfo."Google Client Secret",
            AuthorizationCode,
            RedirectURL);

        RequestContent.WriteFrom(PostData);
        RequestContent.GetHeaders(RequestHeaders);
        RequestHeaders.Clear();
        RequestHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');

        // Exchange authorization code for tokens
        if Client.Post(TokenUrl, RequestContent, ResponseMessage) then begin
            if ResponseMessage.IsSuccessStatusCode() then begin
                ResponseMessage.Content().ReadAs(ResponseText);

                if JObject.ReadFrom(ResponseText) then begin
                    // Extract access token
                    if JObject.Get('access_token', JToken) then begin
                        CompanyInfo."Token GoogleDrive" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(CompanyInfo."Token GoogleDrive"));

                        // Extract refresh token
                        if JObject.Get('refresh_token', JToken) then begin
                            CompanyInfo."Refresh Token GoogleDrive" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(CompanyInfo."Refresh Token GoogleDrive"));
                        end;

                        // Set expiration time
                        if JObject.Get('expires_in', JToken) then begin
                            CompanyInfo."Expiracion Token GoogleDrive" := CurrentDateTime + (JToken.AsValue().AsInteger() * 1000); // Convert seconds to milliseconds
                        end else begin
                            CompanyInfo."Expiracion Token GoogleDrive" := CurrentDateTime + 3600000; // Default 1 hour
                        end;

                        // Clear temporary state
                        CompanyInfo."Google Project ID" := '';
                        CompanyInfo.Modify();

                        AccessToken := CompanyInfo."Token GoogleDrive";
                        Message('Autenticación completada exitosamente.');
                        exit(true);
                    end;
                end;
            end else begin
                ResponseMessage.Content().ReadAs(ResponseText);
                Error('Error en la autenticación: %1', ResponseText);
            end;
        end else begin
            Error('No se pudo conectar con el servidor de autenticación de Google.');
        end;

        exit(false);
    end;

    procedure RefreshAccessToken(): Boolean
    var
        CompanyInfo: Record "Company Information";
        Client: HttpClient;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        JObject: JsonObject;
        JToken: JsonToken;
        RequestHeaders: HttpHeaders;
        TokenUrl: Text;
        PostData: Text;
        ErrorJObject: JsonObject;
        ErrorToken: JsonToken;
        ErrorDescription: Text;
        DiagnosticInfo: Text;
    begin
        CompanyInfo.GET();

        if CompanyInfo."Refresh Token GoogleDrive" = '' then begin
            Message('No hay refresh token disponible. Por favor, complete el proceso de autenticación OAuth primero.');
            exit(false);
        end;

        // Validate credentials before attempting refresh
        if not ValidateCredentialsForRefresh(DiagnosticInfo) then begin
            Message('❌ Error en las credenciales:\%1\' +
                   '\' +
                   'Por favor, verifique la configuración en Company Information.', DiagnosticInfo);
            exit(false);
        end;

        TokenUrl := CompanyInfo."Google Token URI";
        if TokenUrl = '' then
            TokenUrl := 'https://oauth2.googleapis.com/token';

        PostData := StrSubstNo('client_id=%1&client_secret=%2&refresh_token=%3&grant_type=refresh_token',
            CompanyInfo."Google Client ID",
            CompanyInfo."Google Client Secret",
            CompanyInfo."Refresh Token GoogleDrive");

        RequestContent.WriteFrom(PostData);
        RequestContent.GetHeaders(RequestHeaders);
        RequestHeaders.Clear();
        RequestHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');

        if Client.Post(TokenUrl, RequestContent, ResponseMessage) then begin
            ResponseMessage.Content().ReadAs(ResponseText);

            if ResponseMessage.IsSuccessStatusCode() then begin
                if JObject.ReadFrom(ResponseText) then begin
                    // Extract new access token
                    if JObject.Get('access_token', JToken) then begin
                        CompanyInfo."Token GoogleDrive" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(CompanyInfo."Token GoogleDrive"));

                        // Update expiration time
                        if JObject.Get('expires_in', JToken) then begin
                            CompanyInfo."Expiracion Token GoogleDrive" := CurrentDateTime + (JToken.AsValue().AsInteger() * 1000);
                        end else begin
                            CompanyInfo."Expiracion Token GoogleDrive" := CurrentDateTime + 3600000; // Default 1 hour
                        end;

                        // Check for new refresh token (Google may provide a new one)
                        if JObject.Get('refresh_token', JToken) then begin
                            CompanyInfo."Refresh Token GoogleDrive" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(CompanyInfo."Refresh Token GoogleDrive"));
                        end;

                        CompanyInfo.Modify();
                        Message('✅ Token actualizado exitosamente. Nuevo token expira: %1', CompanyInfo."Expiracion Token GoogleDrive");
                        exit(true);
                    end else begin
                        Message('Error: No se encontró access_token en la respuesta: %1', ResponseText);
                        exit(false);
                    end;
                end else begin
                    Message('Error: No se pudo parsear la respuesta JSON: %1', ResponseText);
                    exit(false);
                end;
            end else begin
                // Enhanced error handling for credential issues
                if ErrorJObject.ReadFrom(ResponseText) then begin
                    if ErrorJObject.Get('error_description', ErrorToken) then
                        ErrorDescription := ErrorToken.AsValue().AsText()
                    else if ErrorJObject.Get('error', ErrorToken) then
                        ErrorDescription := ErrorToken.AsValue().AsText()
                    else
                        ErrorDescription := 'Error desconocido';

                    // Provide specific guidance based on error type
                    if StrPos(ErrorDescription, 'invalid_client') > 0 then begin
                        Message('❌ ERROR DE CREDENCIALES INVÁLIDAS\' +
                               '\' +
                               'Error: %1\' +
                               '\' +
                               '🔧 SOLUCIONES POSIBLES:\' +
                               '\' +
                               '1. VERIFICAR CREDENCIALES EN OAUTH PLAYGROUND:\' +
                               '   - Asegúrese de haber marcado "Use your own OAuth credentials"\' +
                               '   - Verifique que Client ID y Secret sean exactamente los mismos\' +
                               '\' +
                               '2. VERIFICAR CONFIGURACIÓN EN GOOGLE CLOUD CONSOLE:\' +
                               '   - El Client ID debe estar habilitado\' +
                               '   - El proyecto debe estar en estado "En producción" o "Testing"\' +
                               '\' +
                               '3. REGENERAR TOKENS:\' +
                               '   - Use "OAuth Playground" para obtener nuevos tokens\' +
                               '   - Asegúrese de usar SUS credenciales, no las del playground\' +
                               '\' +
                               'Client ID actual: %2', ErrorDescription, CompanyInfo."Google Client ID");
                    end else begin
                        Message('❌ Error al actualizar token (Código: %1): %2\' +
                               '\' +
                               'Respuesta completa: %3', ResponseMessage.HttpStatusCode(), ErrorDescription, ResponseText);
                    end;
                end else begin
                    Message('❌ Error al actualizar token (Código: %1): %2', ResponseMessage.HttpStatusCode(), ResponseText);
                end;
                exit(false);
            end;
        end else begin
            Message('❌ Error de conexión: No se pudo conectar con el servidor de Google.');
            exit(false);
        end;

        exit(false);
    end;

    procedure ValidateCredentialsForRefresh(var DiagnosticInfo: Text): Boolean
    var
        CompanyInfo: Record "Company Information";
        IsValid: Boolean;
    begin
        CompanyInfo.GET();
        IsValid := true;
        DiagnosticInfo := '';

        if CompanyInfo."Google Client ID" = '' then begin
            DiagnosticInfo += '- Client ID está vacío\';
            IsValid := false;
        end else begin
            if StrLen(CompanyInfo."Google Client ID") < 50 then begin
                DiagnosticInfo += '- Client ID parece demasiado corto (debe ser ~72 caracteres)\';
                IsValid := false;
            end;
        end;

        if CompanyInfo."Google Client Secret" = '' then begin
            DiagnosticInfo += '- Client Secret está vacío\';
            IsValid := false;
        end else begin
            if StrLen(CompanyInfo."Google Client Secret") < 20 then begin
                DiagnosticInfo += '- Client Secret parece demasiado corto (debe ser ~24 caracteres)\';
                IsValid := false;
            end;
        end;

        if CompanyInfo."Refresh Token GoogleDrive" = '' then begin
            DiagnosticInfo += '- Refresh Token está vacío\';
            IsValid := false;
        end;

        if IsValid then
            DiagnosticInfo := '✅ Todas las credenciales están presentes y tienen longitud apropiada';

        exit(IsValid);
    end;

    procedure DiagnoseOAuthConfiguration(): Text
    var
        CompanyInfo: Record "Company Information";
        DiagnosticText: Text;
        ClientIdLength: Integer;
        ClientSecretLength: Integer;
        RefreshTokenLength: Integer;
    begin
        CompanyInfo.GET();

        DiagnosticText := '🔍 DIAGNÓSTICO DE CONFIGURACIÓN OAUTH\' +
                         '\' +
                         '📋 CREDENCIALES:\';

        // Client ID Analysis
        ClientIdLength := StrLen(CompanyInfo."Google Client ID");
        DiagnosticText += StrSubstNo('Client ID: %1 caracteres', ClientIdLength);
        if ClientIdLength = 0 then
            DiagnosticText += ' ❌ VACÍO'
        else if ClientIdLength < 50 then
            DiagnosticText += ' ⚠️ DEMASIADO CORTO'
        else if ClientIdLength > 80 then
            DiagnosticText += ' ⚠️ DEMASIADO LARGO'
        else
            DiagnosticText += ' ✅ LONGITUD OK';
        DiagnosticText += '\';

        // Client Secret Analysis
        ClientSecretLength := StrLen(CompanyInfo."Google Client Secret");
        DiagnosticText += StrSubstNo('Client Secret: %1 caracteres', ClientSecretLength);
        if ClientSecretLength = 0 then
            DiagnosticText += ' ❌ VACÍO'
        else if ClientSecretLength < 20 then
            DiagnosticText += ' ⚠️ DEMASIADO CORTO'
        else if ClientSecretLength > 50 then
            DiagnosticText += ' ⚠️ DEMASIADO LARGO'
        else
            DiagnosticText += ' ✅ LONGITUD OK';
        DiagnosticText += '\';

        // Refresh Token Analysis
        RefreshTokenLength := StrLen(CompanyInfo."Refresh Token GoogleDrive");
        DiagnosticText += StrSubstNo('Refresh Token: %1 caracteres', RefreshTokenLength);
        if RefreshTokenLength = 0 then
            DiagnosticText += ' ❌ VACÍO'
        else if RefreshTokenLength < 50 then
            DiagnosticText += ' ⚠️ DEMASIADO CORTO'
        else
            DiagnosticText += ' ✅ LONGITUD OK';
        DiagnosticText += '\';

        // URLs
        DiagnosticText += '\📡 URLs:\';
        DiagnosticText += 'Auth URI: ' + CompanyInfo."Google Auth URI" + '\';
        DiagnosticText += 'Token URI: ' + CompanyInfo."Google Token URI" + '\';

        // Token Status
        DiagnosticText += '\⏰ ESTADO DEL TOKEN:\';
        if CompanyInfo."Expiracion Token GoogleDrive" = 0DT then
            DiagnosticText += 'Sin fecha de expiración ❌\'
        else if CompanyInfo."Expiracion Token GoogleDrive" < CurrentDateTime then
            DiagnosticText += StrSubstNo('Expirado desde: %1 ❌\', CompanyInfo."Expiracion Token GoogleDrive")
        else
            DiagnosticText += StrSubstNo('Válido hasta: %1 ✅\', CompanyInfo."Expiracion Token GoogleDrive");

        exit(DiagnosticText);
    end;

    procedure RevokeAccess(): Boolean
    var
        CompanyInfo: Record "Company Information";
        Client: HttpClient;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        RevokeUrl: Text;
    begin
        CompanyInfo.GET();

        if CompanyInfo."Token GoogleDrive" = '' then
            exit(true); // Nothing to revoke

        RevokeUrl := StrSubstNo('https://oauth2.googleapis.com/revoke?token=%1', CompanyInfo."Token GoogleDrive");

        // Create empty content for the POST request
        RequestContent.WriteFrom('');

        if Client.Post(RevokeUrl, RequestContent, ResponseMessage) then begin
            // Clear stored tokens regardless of response
            CompanyInfo."Token GoogleDrive" := '';
            CompanyInfo."Refresh Token GoogleDrive" := '';
            CompanyInfo."Expiracion Token GoogleDrive" := 0DT;
            CompanyInfo.Modify();

            Message('Acceso a Google Drive revocado exitosamente.');
            exit(true);
        end;

        exit(false);
    end;

    procedure ValidateConfiguration(): Boolean
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.GET();

        exit((CompanyInfo."Google Client ID" <> '') and
             (CompanyInfo."Google Client Secret" <> '') and
             (CompanyInfo."Google Auth URI" <> '') and
             (CompanyInfo."Google Token URI" <> ''));
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

        //In a real implementation, send the request and handle the response
        Client.Send(Request, Response);
        Response.Content.ReadAs(ResponseText);

        //Parse the response to get the file ID and URL
        JResponse.ReadFrom(ResponseText);
        JResponse.Get('id', JToken);
        FileId := JToken.AsValue().AsText();

        // For demo purposes:
        //FileId := 'demo-file-id-123456';

        // Update the Document Attachment record with the Google Drive URL
        DocumentAttachment."Google Drive ID" := FileId;
        DocumentAttachment."Store in Google Drive" := true;
        DocumentAttachment.Modify();

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

    local procedure GetMimeType(FileExtension: Text): Text
    begin
        case FileExtension of
            'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'ico', 'webp':
                exit('image/jpeg');
            'pdf':
                exit('application/pdf');
            'doc', 'docx':
                exit('application/vnd.openxmlformats-officedocument.wordprocessingml.document');
            'xls', 'xlsx':
                exit('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
            'ppt', 'pptx':
                exit('application/vnd.openxmlformats-officedocument.presentationml.presentation');
            'txt':
                exit('text/plain');
            'csv':
                exit('text/csv');
            'zip', 'rar', '7z':
                exit('application/zip');
            'mp3', 'wav', 'ogg', 'm4a', 'aac':
                exit('audio/mpeg');
            'mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv':
                exit('video/mp4');
            'mpg', 'mpeg', 'm4v', '3gp', '3g2':
                exit('video/mp4');
            else
                exit('application/octet-stream');
        end;
    end;

    local procedure FileExtension(Name: Text[250]): Text[30]
    var
        FileMgt: Codeunit "File Management";
        Extension: Text;
    begin
        Extension := FileMgt.GetExtension(Name);
        case Extension of
            'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'ico', 'webp':
                exit('jpeg');
            'pdf':
                exit('pdf');
            'doc', 'docx':
                exit('word');
            'xls', 'xlsx':
                exit('excel');
            'ppt', 'pptx':
                exit('powerpoint');
            'txt':
                exit('text');
            'csv':
                exit('csv');
            'zip', 'rar', '7z':
                exit('zip');
            'mp3', 'wav', 'ogg', 'm4a', 'aac':
                exit('audio');
            'mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv':
                exit('video');
            else
                exit(Extension);
        end;
        exit(Extension);
    end;

    local procedure RecuperarCarpeta(FileId: Text; OldParent: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Json: Text;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokO: JsonToken;
        JTok: JsonToken;
        JEntries: JsonArray;
        JEntry: JsonObject;
        JEntryToken: JsonToken;
        JEntryTokens: JsonToken;
        Inf: Record "Company Information";
    begin
        Inf.Get;
        if not Authenticate() then
            Error('No se pudo autenticar con Google Drive. Por favor, verifique sus credenciales.');
        Ticket := AccessToken;
        Url := Inf."Url Api GoogleDrive" + list_folder + '/' + FileId + '?fields=parents';
        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);
        if StatusInfo.Get('parents', JTok) then begin
            JEntries := JTok.AsArray();
            foreach JEntryTokens in JEntries do begin
                OldParent := JEntryTokens.AsValue().AsText()

            end;
        end;
        exit(OldParent);
    end;

    procedure Token(): Text
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.GET();
        if CompanyInfo."Expiracion Token GoogleDrive" < CurrentDateTime then begin
            if not RefreshAccessToken() then begin
                Message('No se pudo actualizar el token automáticamente. Por favor, configure un nuevo token.');
                exit('');
            end;
        end;
        Commit();
        CompanyInfo.GET();
        exit(CompanyInfo.GetTokenGoogleDrive());
    end;

    procedure RecuperaIdFolder(IdCarpeta: Text; Carpeta: Text; Var Files: Record "Name/Value Buffer" temporary; Crear: Boolean; RootFolder: Boolean) Id: Text;
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
        Borrado: Boolean;
        RootFolderId: Text;
        C: Label '''';
    begin
        Files.DeleteAll();
        if not Authenticate() then
            Error('No se pudo autenticar con Google Drive. Por favor, verifique sus credenciales.');

        Ticket := AccessToken;
        Inf.Get;
        RootFolderId := Inf."Root Folder ID";
        Url := Inf."Url Api GoogleDrive" + list_folder;
        if RootFolder = false then
            //Url := Url + '?q=' + C + RootFolderId + C + 'in+parents&trashed=false&fields=files(id%2Cname%2CmimeType%2Ctrashed)'
             Url := Url + '?q=' + C + RootFolderId + C + '+in+parents&fields=files(id%2Cname%2CmimeType%2Ctrashed)'
        else
            Url := Url + '?q=trashed=false&fields=files(id%2Cname%2CmimeType%2Ctrashed)';
        //https://www.googleapis.com/drive/v3/files?q='1YCipBu7tEY2n2enB5RGxy1XXYtjID4oe'+in+parents&fields=files(id%2Cname%2CmimeType)

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        If StatusInfo.Get('files', JTok) Then begin
            JEntries := JTok.AsArray();
            foreach JEntryTokens in JEntries do begin
                JEntry := JEntryTokens.AsObject();
                If JEntry.Get('mimeType', JEntryToken) Then begin
                    tag := JEntryToken.AsValue().AsText();
                end;
                Borrado := false;
                if JEntry.Get('trashed', JEntryToken) Then begin
                    if JEntryToken.AsValue().AsBoolean() then
                        Borrado := JEntryToken.AsValue().AsBoolean();
                end;
                if JEntry.Get('name', JEntryToken) then begin
                    if (JEntryToken.AsValue().AsText() = Carpeta) and (Not Borrado) then begin
                        if JEntry.Get('id', JEntryToken) then begin
                            Id := JEntryToken.AsValue().AsText();
                            exit(Id);
                        end;
                    end;
                    if tag = 'application/vnd.google-apps.folder' then begin
                        Files.Init();
                        a += 1;
                        Files.ID := a;
                        Files.Name := JEntryToken.AsValue().AsText();
                        Files.Value := 'Carpeta';
                        if not Borrado then
                            Files.Insert();
                    end else begin
                        Files.Init();
                        a += 1;
                        Files.ID := a;
                        Files.Name := JEntryToken.AsValue().AsText();
                        Files.Value := '';
                        Files."File Extension" := FileExtension(Files.Name);
                        if not Borrado then
                            Files.Insert();
                    end;
                end;
            end;
        end;
        if Crear then begin
            Id := CreateFolder(Carpeta, IdCarpeta, RootFolder);
        end;
    end;

    procedure Carpetas(IdCarpeta: Text; Var Files: Record "Name/Value Buffer" temporary)
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
        JId: JsonToken;
        JEntryTokens: JsonToken;
        tag: Text;
        Cursor: Text;
        HasMore: Boolean;
        a: Integer;
        FilesTemp: Record "Name/Value Buffer" temporary;
        C: Label '''';
        Borrado: Boolean;
    begin
        Files.DeleteAll();
        if not Authenticate() then
            Error('No se pudo autenticar con Google Drive. Por favor, verifique sus credenciales.');

        Ticket := AccessToken;
        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + list_folder;
        if IdCarpeta = '' then IdCarpeta := Inf."Root Folder ID";
        //https://www.googleapis.com/drive/v3/files?q=%27FOLDER_ID%27+in+parents&fields=files(id%2Cname%2CmimeType)
        Url := Url + '?q=' + C + IdCarpeta + C + '+in+parents&fields=files(id%2Cname%2CmimeType%2Ctrashed)';
        if IdCarpeta = '' then
            Url := Url + '?q=trashed=false&fields=files(id%2Cname%2CmimeType%2Ctrashed)';
        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        If StatusInfo.Get('files', JTok) Then begin
            JEntries := JTok.AsArray();
            foreach JEntryTokens in JEntries do begin
                JEntry := JEntryTokens.AsObject();
                If JEntry.Get('mimeType', JEntryToken) Then begin
                    tag := JEntryToken.AsValue().AsText();
                end;
                Borrado := false;
                if JEntry.Get('trashed', JEntryToken) Then begin
                    if JEntryToken.AsValue().AsBoolean() then
                        Borrado := JEntryToken.AsValue().AsBoolean();
                end;
                if JEntry.Get('name', JEntryToken) then begin
                    if tag = 'application/vnd.google-apps.folder' then begin
                        FilesTemp.Init();
                        a += 1;
                        FilesTemp.ID := a;
                        FilesTemp.Name := JEntryToken.AsValue().AsText();
                        FilesTemp.Value := 'Carpeta';
                        if JEntry.Get('id', JId) then
                            FilesTemp."Google Drive ID" := JId.AsValue().AsText();
                        FilesTemp."Google Drive Parent ID" := IdCarpeta;
                        if not Borrado then
                            FilesTemp.Insert();
                    end else begin
                        FilesTemp.Init();
                        a += 1;
                        FilesTemp.ID := a;
                        FilesTemp.Name := JEntryToken.AsValue().AsText();
                        FilesTemp.Value := '';
                        FilesTemp."File Extension" := FileExtension(FilesTemp.Name);
                        if JEntry.Get('id', JId) then
                            FilesTemp."Google Drive ID" := JId.AsValue().AsText();
                        FilesTemp."Google Drive Parent ID" := IdCarpeta;
                        if not Borrado then
                            FilesTemp.Insert();
                    end;
                end;
            end;
        end;
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

    procedure CreateFolder(Carpeta: Text; ParentId: Text; RootFolder: Boolean): Text
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
        ParentsArray: JsonArray;
    begin
        if not Authenticate() then
            Error('No se pudo autenticar con Google Drive. Por favor, verifique sus credenciales.');

        Ticket := AccessToken;
        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + create_folder;

        If CopyStr(ParentId, 1, 1) = '/' then
            ParentId := CopyStr(ParentId, 2);
        if (ParentId = '') and (not RootFolder) then
            ParentId := Inf."Root Folder ID";

        Body.Add('name', Carpeta);
        Body.add('mimeType', 'application/vnd.google-apps.folder');

        if ParentId <> '' then begin
            ParentsArray.Add(ParentId);
            Body.Add('parents', ParentsArray);
        end;

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

    procedure UploadFileB64(Carpeta: Text; Base64Data: InStream; Filename: Text; FileExtension: Text): Text
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
        ContentText: Text;
        Boundary: Text;
        CrLf: CHAR;
        CrLf2: cHAR;
        FileContent: Text;
        Content: HttpContent;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        ResponseText: Text;
        JResponse: JsonObject;
        ContentHeaders: HttpHeaders;
        Base64Txt: Text;
        Convert: Codeunit "Base64 Convert";
        JCarpetas: JsonArray;
    begin

        //https://api-drive.app.elingenierojefe.es/upload
        If Not Authenticate() Then
            Error('No se pudo obtener el token');
        Url := 'https://api-drive.app.elingenierojefe.es/upload';
        Body.Add('fileName', Filename);
        Body.Add('fileType', GetMimeType(FileExtension));
        Body.Add('token', Token());
        if Carpeta <> '' then begin
            JCarpetas.Add(Carpeta);
            Body.Add('parents', JCarpetas);
        end;

        Base64Txt := Convert.ToBase64(Base64Data);
        Body.Add('base64Data', Base64Txt);
        Body.WriteTo(Json);
        Respuesta := RestApiToken(Url, AccessToken, RequestType::post, Json);
        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);
        if StatusInfo.Get('fileId', JTokenLink) Then begin
            Id := JTokenLink.AsValue().AsText();
        end;

        if Id = '' then begin
            Error('Error al subir el archivo');
        end;
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

        Respuesta := RestApiToken(Url, Ticket, RequestType::delete, '');

        exit('');
    end;

    procedure MoveFolder(FolderId: Text; NewParentId: Text): Text
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
        Url := Inf."Url Api GoogleDrive" + move_folder + FolderId;

        Body.Add('addParents', NewParentId);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::patch, Json);
        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        If StatusInfo.Get('id', JTokO) Then begin
            Id := JTokO.AsValue().AsText();
        end;

        if Id = '' then begin
            if StatusInfo.Get('error', JTok) then begin
                Error(JTok.AsValue().AsText());
            end;
            Error('Error al mover la carpeta');
        end;

        exit(Id);
    end;

    procedure MoveFile(FileId: Text; NewParentId: Text; OldParent: Text): Text
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
        if OldParent = '' then begin
            OldParent := RecuperarCarpeta(FileId, OldParent);
        end;
        // Construir la URL con los parámetros addParents y removeParents
        Url := Inf."Url Api GoogleDrive" + move_folder + FileId +
               '?addParents=' + NewParentId +
               '&removeParents=' + OldParent;

        // La API de Google Drive espera un cuerpo vacío para esta operación
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::patch, '');
        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        If StatusInfo.Get('id', JTokO) Then begin
            Id := JTokO.AsValue().AsText();
        end;

        if Id = '' then begin
            if StatusInfo.Get('error', JTok) then begin
                Error(JTok.AsValue().AsText());
            end;
            Error('Error al mover el archivo');
        end;

        exit(Id);
    end;

    procedure CopyFile(FileId: Text; NewParentId: Text): Text
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
        ParentsArray: JsonArray;
    begin
        Ticket := GoogleDrive.Token();
        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + move_folder + FileId + '/copy';
        //NewParentId es un array
        ParentsArray.Add(NewParentId);
        Body.Add('parents', ParentsArray);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);
        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        If StatusInfo.Get('id', JTokO) Then begin
            Id := JTokO.AsValue().AsText();
        end;

        if Id = '' then begin
            if StatusInfo.Get('error', JTok) then begin
                Error(JTok.AsValue().AsText());
            end;
            Error('Error al copiar el archivo');
        end;

        exit(Id);
    end;

    procedure ListFolder(FolderId: Text; var Files: Record "Name/Value Buffer" temporary; SoloSubfolder: Boolean)
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
        JEntries: JsonArray;
        JEntry: JsonObject;
        JEntryToken: JsonToken;
        JEntryTokens: JsonToken;
        tag: Text;
        a: Integer;
        C: Label '''';
        FilesTemp: Record "Name/Value Buffer" temporary;
        Borrado: Boolean;

    begin
        Files.DeleteAll();
        Ticket := GoogleDrive.Token();
        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + list_folder;

        if SoloSubfolder then begin
            If FolderId <> '' Then
                Url := Url + '?q=' + C + FolderId + C + '+in+parents&fields=files(id%2Cname%2CmimeType%2Ctrashed)'
            else
                Url := Url + '?q=' + C + Inf."Root Folder ID" + C + '+in+parents&trashed=false&fields=files(id%2Cname%2CmimeType%2Ctrashed)';

        end else
            Url := Url + '?q=' + C + Inf."Root Folder ID" + C + '+in+parents&trashed=false&fields=files(id%2Cname%2CmimeType%2Ctrashed)';
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
                Borrado := false;
                if JEntry.Get('trashed', JEntryToken) Then begin
                    if JEntryToken.AsValue().AsBoolean() then
                        Borrado := JEntryToken.AsValue().AsBoolean();
                end;

                if JEntry.Get('name', JEntryToken) then begin
                    FilesTemp.Init();
                    a += 1;
                    FilesTemp.ID := a;
                    FilesTemp.Name := JEntryToken.AsValue().AsText();
                    FilesTemp."Google Drive Parent ID" := FolderId;

                    if JEntry.Get('id', JEntryToken) then
                        FilesTemp."Google Drive ID" := JEntryToken.AsValue().AsText();

                    if tag = 'application/vnd.google-apps.folder' then
                        FilesTemp.Value := 'Carpeta'
                    else begin
                        FilesTemp.Value := '';
                        FilesTemp."File Extension" := FileExtension(FilesTemp.Name);
                    end;
                    if not Borrado then
                        FilesTemp.Insert();
                end;
            end;
        end;
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

    procedure DownloadFileB64(FileId: Text; FileName: Text; BajarFichero: Boolean; var Base64Data: Text): Boolean
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
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        Convert: Codeunit "Base64 Convert";
    begin
        Ticket := GoogleDrive.Token();
        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + get_metadata + FileId + '?alt=media';

        RequestHeaders := Client.DefaultRequestHeaders();
        RequestHeaders.Add('Authorization', StrSubstNo('Bearer %1', Ticket));

        Client.Get(Url, ResponseMessage);

        if not ResponseMessage.IsSuccessStatusCode() then
            exit(false);

        TempBlob.CreateInStream(InStream);
        ResponseMessage.Content().ReadAs(InStream);
        Base64Data := Convert.ToBase64(InStream);
        TempBlob.CreateOutStream(OutStream);
        Convert.FromBase64(Base64Data, OutStream);
        Clear(InStream);
        TempBlob.CreateInStream(InStream);
        If BajarFichero Then
            DownloadFromStream(InStream, 'Guardar', 'C:\Temp', 'ALL Files (*.*)|*.*', FileName);

        exit(true);
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
            RequestType::patch:
                begin
                    RequestContent.WriteFrom(payload);
                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/json');
                    Client.Patch(URL, RequestContent, ResponseMessage);
                end;
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
            RequestType::patch:
                begin
                    RequestContent.WriteFrom(payload);
                    RequestContent.GetHeaders(contentHeaders);
                    contentHeaders.Clear();
                    contentHeaders.Add('Content-Type', 'application/json');
                    Client.Patch(URL, RequestContent, ResponseMessage);
                end;
        end;

        exit(ResponseMessage);
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

    procedure StartOAuthFlowPlayground(): Boolean
    var
        CompanyInfo: Record "Company Information";
        PlaygroundUrl: Text;
        InstructionText: Text;
    begin
        CompanyInfo.GET();

        // Validate required configuration
        if (CompanyInfo."Google Client ID" = '') or (CompanyInfo."Google Client Secret" = '') then begin
            Error('La configuración de Google Drive no está completa. Por favor, configure Client ID y Client Secret en la información de la empresa.');
        end;

        PlaygroundUrl := 'https://developers.google.com/oauthplayground/';

        InstructionText := 'CONFIGURAR OAUTH PLAYGROUND CON SUS CREDENCIALES:\' +
                          '\' +
                          '⚠️ IMPORTANTE: Debe configurar SUS credenciales, no las del playground\' +
                          '\' +
                          '1. Abra esta URL: ' + PlaygroundUrl + '\' +
                          '\' +
                          '2. 🔧 CONFIGURAR CREDENCIALES (PASO CRÍTICO):\' +
                          '   - En la esquina SUPERIOR DERECHA, haga clic en el ícono ⚙️ (Settings)\' +
                          '   - ✅ Marque la casilla "Use your own OAuth credentials"\' +
                          '   - OAuth Client ID: ' + CompanyInfo."Google Client ID" + '\' +
                          '   - OAuth Client Secret: ' + CompanyInfo."Google Client Secret" + '\' +
                          '   - Haga clic en "Close" para guardar\' +
                          '\' +
                          '3. 📋 SELECCIONAR APIS:\' +
                          '   - En el panel izquierdo, busque "Drive API v3"\' +
                          '   - Expanda la sección y seleccione:\' +
                          '     ✅ https://www.googleapis.com/auth/drive\' +
                          '     ✅ https://www.googleapis.com/auth/drive.file\' +
                          '\' +
                          '4. 🔐 AUTORIZAR:\' +
                          '   - Haga clic en "Authorize APIs"\' +
                          '   - Inicie sesión con su cuenta Google\' +
                          '   - Autorice el acceso\' +
                          '\' +
                          '5. 🎫 OBTENER TOKENS:\' +
                          '   - Haga clic en "Exchange authorization code for tokens"\' +
                          '   - Copie el "access_token" y "refresh_token"\' +
                          '\' +
                          '6. 📝 CONFIGURAR EN BUSINESS CENTRAL:\' +
                          '   - Pegue los tokens en los campos correspondientes\' +
                          '   - Use "Probar Validez del Token" para verificar';

        // Try to open playground
        if not TryOpenBrowser(PlaygroundUrl) then begin
            Message(InstructionText);
        end else begin
            Message('Se ha abierto Google OAuth Playground.\' +
                   '\' +
                   '⚠️ RECUERDE: Debe configurar SUS credenciales en Settings (⚙️)\' +
                   '\' +
                   'Instrucciones completas:\' + InstructionText);
        end;

        exit(false);
    end;

    procedure SetTokensManually(AccessToken: Text; RefreshToken: Text; ExpiresIn: Integer)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.GET();

        CompanyInfo."Token GoogleDrive" := CopyStr(AccessToken, 1, MaxStrLen(CompanyInfo."Token GoogleDrive"));
        CompanyInfo."Refresh Token GoogleDrive" := CopyStr(RefreshToken, 1, MaxStrLen(CompanyInfo."Refresh Token GoogleDrive"));

        if ExpiresIn > 0 then
            CompanyInfo."Expiracion Token GoogleDrive" := CurrentDateTime + (ExpiresIn * 1000)
        else
            CompanyInfo."Expiracion Token GoogleDrive" := CurrentDateTime + 3600000; // Default 1 hour

        CompanyInfo.Modify();

        Message('Tokens configurados manualmente exitosamente.');
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

    procedure CreateFolderStructure(BaseFolderId: Text; FolderPath: Text): Text
    var
        PathParts: List of [Text];
        CurrentFolderId: Text;
        FolderName: Text;
        NewFolderId: Text;
        i: Integer;
    begin
        if FolderPath = '' then
            exit(BaseFolderId);

        // Split path by '/'
        PathParts := FolderPath.Split('/');
        CurrentFolderId := BaseFolderId;

        for i := 1 to PathParts.Count do begin
            FolderName := PathParts.Get(i);
            if FolderName <> '' then begin
                // Check if folder already exists
                NewFolderId := FindOrCreateSubfolder(CurrentFolderId, FolderName, true);
                if NewFolderId <> '' then
                    CurrentFolderId := NewFolderId
                else
                    exit(CurrentFolderId); // Return last successful folder if creation fails
            end;
        end;

        exit(CurrentFolderId);
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

    procedure UploadFileToConfiguredFolder(var DocumentAttachment: Record "Document Attachment"; TempBlob: Codeunit "Temp Blob"; TableID: Integer; DocumentNo: Text; DocumentDate: Date): Boolean
    var
        TargetFolderId: Text;
        FileName: Text;
        FileId: Text;
    begin
        if not Authenticate() then
            exit(false);

        // Get target folder based on configuration

        TargetFolderId := GetTargetFolderForDocument(TableID, DocumentNo, DocumentDate, OrigenEstorage::"Google Drive");

        FileName := DocumentAttachment."File Name";
        if FileName = '' then
            FileName := 'Document_' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2>_<Hours24><Minutes,2><Seconds,2>');

        // Upload file to the configured folder
        FileId := UploadFileToFolder(TempBlob, FileName, TargetFolderId);

        if FileId <> '' then begin
            // Update Document Attachment record
            DocumentAttachment."Google Drive ID" := FileId;
            DocumentAttachment."Store in Google Drive" := true;
            DocumentAttachment.Modify();
            exit(true);
        end;

        exit(false);
    end;

    procedure UploadFileToFolder(TempBlob: Codeunit "Temp Blob"; FileName: Text; FolderId: Text): Text
    var
        Client: HttpClient;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        JResponse: JsonObject;
        JToken: JsonToken;
        RequestHeaders: HttpHeaders;
        URL: Text;
        Boundary: Text;
        ContentText: Text;
        CrLf: Text;
        InStream: InStream;
        FileContent: Text;
        Convert: Codeunit "Base64 Convert";
    begin
        Boundary := 'foo_bar_baz';
        CrLf := FORMAT(13) + FORMAT(10);

        // Get file content as Base64
        TempBlob.CreateInStream(InStream);
        FileContent := Convert.ToBase64(InStream);

        // Prepare multipart upload
        URL := GoogleDriveUploadURL + '?uploadType=multipart';

        // Build multipart content
        ContentText := '--' + Boundary + CrLf;
        ContentText += 'Content-Type: application/json; charset=UTF-8' + CrLf + CrLf;
        ContentText += '{"name": "' + FileName + '"';
        if FolderId <> '' then
            ContentText += ', "parents": ["' + FolderId + '"]';
        ContentText += '}' + CrLf;
        ContentText += '--' + Boundary + CrLf;
        ContentText += 'Content-Type: application/octet-stream' + CrLf;
        ContentText += 'Content-Transfer-Encoding: base64' + CrLf + CrLf;
        ContentText += FileContent + CrLf;
        ContentText += '--' + Boundary + '--';

        RequestContent.WriteFrom(ContentText);
        RequestContent.GetHeaders(RequestHeaders);
        RequestHeaders.Clear();
        RequestHeaders.Add('Content-Type', 'multipart/related; boundary=' + Boundary);

        Client.DefaultRequestHeaders().Add('Authorization', StrSubstNo('Bearer %1', AccessToken));

        if Client.Post(URL, RequestContent, ResponseMessage) then begin
            if ResponseMessage.IsSuccessStatusCode() then begin
                ResponseMessage.Content().ReadAs(ResponseText);
                if JResponse.ReadFrom(ResponseText) then begin
                    if JResponse.Get('id', JToken) then
                        exit(JToken.AsValue().AsText());
                end;
            end else begin
                ResponseMessage.Content().ReadAs(ResponseText);
                Message('Error uploading file: %1', ResponseText);
            end;
        end;

        exit('');
    end;

    procedure GetTableIDFromDocumentAttachment(var DocumentAttachment: Record "Document Attachment"): Integer
    begin
        // Return the table ID that the document attachment is related to
        exit(DocumentAttachment."Table ID");
    end;

    procedure GetDocumentInfoFromAttachment(var DocumentAttachment: Record "Document Attachment"; var DocumentNo: Text; var DocumentDate: Date): Boolean
    begin
        DocumentNo := '';
        DocumentDate := Today; // Default to today

        // For now, use simple approach - get info from Document Attachment record itself
        // The table ID is available in DocumentAttachment."Table ID"
        // We can enhance this later with specific logic for each table type

        // Try to extract document number from the attachment's own fields if available
        if DocumentAttachment."No." <> '' then
            DocumentNo := DocumentAttachment."No.";

        // Use current date as default
        DocumentDate := Today;

        exit(true); // Always return true for now
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

    internal procedure OpenFileInBrowser(GoogleDriveID: Text[250]): Text
    var
        Inf: Record "Company Information";
        Url: Text[250];
        RequestHeaders: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
        GoogleDrive: Codeunit "Google Drive Manager";
        Respuesta: Text;
        StatusInfo: JsonObject;
        Json: Text;
        RequestType: Option get,patch,put,post,delete;
        JToken: JsonToken;
        Link: Text;
        ErrorMessage: Text;
    begin
        if not Authenticate() then
            Error('No se pudo autenticar con Google Drive. Por favor, verifique sus credenciales.');


        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + get_metadata + GoogleDriveID + '?fields=webViewLink,webContentLink';

        Respuesta := RestApiToken(Url, AccessToken, RequestType::get, '');

        if Respuesta = '' then
            Error('No se recibió respuesta del servidor de Google Drive.');

        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            Error('Error al acceder al archivo: %1', ErrorMessage);
        end;

        if StatusInfo.Get('webViewLink', JToken) then begin
            Link := JToken.AsValue().AsText();
            Hyperlink(Link);
        end else if StatusInfo.Get('webContentLink', JToken) then begin
            Link := JToken.AsValue().AsText();
            Hyperlink(Link);
        end else begin
            Error('No se pudo obtener el enlace del archivo. Verifique que el ID del archivo sea correcto y que tenga permisos para acceder a él.');
        end;

        exit('');
    end;

    internal procedure GetUrl(GoogleDriveID: Text[250]): Text
    var
        Inf: Record "Company Information";
        Url: Text[250];
        RequestHeaders: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
        GoogleDrive: Codeunit "Google Drive Manager";
        Respuesta: Text;
        StatusInfo: JsonObject;
        Json: Text;
        RequestType: Option get,patch,put,post,delete;
        JToken: JsonToken;
        Link: Text;
        ErrorMessage: Text;
    begin
        if not Authenticate() then
            Error('No se pudo autenticar con Google Drive. Por favor, verifique sus credenciales.');


        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + get_metadata + GoogleDriveID + '?fields=webViewLink,webContentLink';

        Respuesta := RestApiToken(Url, AccessToken, RequestType::get, '');

        if Respuesta = '' then
            Error('No se recibió respuesta del servidor de Google Drive.');

        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            exit('');
        end;

        if StatusInfo.Get('webViewLink', JToken) then begin
            Link := JToken.AsValue().AsText();
            exit(Link);
        end else if StatusInfo.Get('webContentLink', JToken) then begin
            Link := JToken.AsValue().AsText();
            exit(Link);
        end else begin
            exit('');
        end;

        exit('');
    end;

    internal procedure DeleteFile(GoogleDriveID: Text[250]): Boolean
    var
        Client: HttpClient;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        JResponse: JsonObject;
        JToken: JsonToken;
        RequestHeaders: HttpHeaders;
        Inf: Record "Company Information";
        Url: Text[250];
        RequestType: Option get,patch,put,post,delete;
        Respuesta: Text;
    begin
        if not Authenticate() then
            Error('No se pudo autenticar con Google Drive. Por favor, verifique sus credenciales.');

        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + get_metadata + GoogleDriveID;

        ResponseMessage := RestApiTokenResponse(Url, AccessToken, RequestType::delete, '');
        if ResponseMessage.IsSuccessStatusCode() then
            exit(true)
        else
            exit(false);
    end;

    internal procedure EditFile(GoogleDriveID: Text[250])
    var
        Inf: Record "Company Information";
        Url: Text[250];
        RequestHeaders: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
        GoogleDrive: Codeunit "Google Drive Manager";
        Respuesta: Text;
        StatusInfo: JsonObject;
        Json: Text;
        RequestType: Option get,patch,put,post,delete;
        JToken: JsonToken;
        Link: Text;
        ErrorMessage: Text;
    begin
        if not Authenticate() then
            Error('No se pudo autenticar con Google Drive. Por favor, verifique sus credenciales.');


        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + get_metadata + GoogleDriveID + '/permissions';
        Json := '{"type": "anyone","role": "writer","allowFileDiscovery": false}';

        Respuesta := RestApiToken(Url, AccessToken, RequestType::post, Json);

        if Respuesta = '' then
            Error('No se recibió respuesta del servidor de Google Drive.');

        Url := Inf."Url Api GoogleDrive" + get_metadata + GoogleDriveID + '?fields=webViewLink';
        Respuesta := RestApiToken(Url, AccessToken, RequestType::get, '');

        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            Error('Error al acceder al archivo: %1', ErrorMessage);
        end;

        if StatusInfo.Get('webViewLink', JToken) then begin
            Link := JToken.AsValue().AsText();
            Hyperlink(Link);
        end else if StatusInfo.Get('webContentLink', JToken) then begin
            Link := JToken.AsValue().AsText();
            Hyperlink(Link);
        end else begin
            Error('No se pudo obtener el enlace del archivo. Verifique que el ID del archivo sea correcto y que tenga permisos para acceder a él.');
        end;
    end;

    procedure RestApi(url: Text; RequestType: Option Get,patch,put,post,delete; payload: Text): Text
    var
        Ok: Boolean;
        Respuesta: Text;
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        RequestMessage: HttpRequestMessage;
        ResponseText: Text;
        contentHeaders: HttpHeaders;
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