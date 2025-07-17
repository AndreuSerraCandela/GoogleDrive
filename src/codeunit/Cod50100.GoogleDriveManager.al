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
        // Message Labels
        CopyUrlToBrowserMsg: Label 'Please copy the following URL to your browser to authorize Google Drive access:\%1';
        BrowserOpenedMsg: Label 'Browser has been opened for authorization. If it doesn''t open automatically, copy this URL:\%1';
        AuthenticationCompletedMsg: Label 'Authentication completed successfully.';
        NoRefreshTokenMsg: Label 'No refresh token available. Please complete the OAuth authentication process first.';
        CredentialsErrorMsg: Label '❌ Credential error: %1\Please verify configuration in Company Information.';
        TokenUpdatedMsg: Label '✅ Token updated successfully. New token expires: %1';
        NoAccessTokenMsg: Label 'Error: access_token not found in response: %1';
        JsonParseErrorMsg: Label 'Error: Could not parse JSON response: %1';
        InvalidCredentialsErrorMsg: Label '❌ INVALID CREDENTIALS ERROR\Error: %1\🔧 POSSIBLE SOLUTIONS:\1. VERIFY CREDENTIALS IN OAUTH PLAYGROUND:\   - Make sure you have checked "Use your own OAuth credentials"\   - Verify that Client ID and Secret are exactly the same\2. VERIFY CONFIGURATION IN GOOGLE CLOUD CONSOLE:\   - Client ID must be enabled\   - Project must be in "In production" or "Testing" status\3. REGENERATE TOKENS:\   - Use "OAuth Playground" to get new tokens\   - Make sure to use YOUR credentials, not playground ones\Current Client ID: %2';
        TokenUpdateErrorMsg: Label '❌ Error updating token (Code: %1): %2\Complete response: %3';
        TokenUpdateErrorSimpleMsg: Label '❌ Error updating token (Code: %1): %2';
        ConnectionErrorMsg: Label '❌ Connection error: Could not connect to Google server.';
        AccessRevokedMsg: Label 'Google Drive access revoked successfully.';
        TokenUpdateFailedMsg: Label 'Could not update token automatically. Please configure a new token.';
        PlaygroundInstructionsMsg: Label 'CONFIGURE OAUTH PLAYGROUND WITH YOUR CREDENTIALS:\⚠️ IMPORTANT: You must configure YOUR credentials, not playground ones\1. Open this URL: %1\2. 🔧 CONFIGURE CREDENTIALS (CRITICAL STEP):\   - In the UPPER RIGHT corner, click the ⚙️ icon (Settings)\   - ✅ Check the "Use your own OAuth credentials" box\   - OAuth Client ID: %2\   - OAuth Client Secret: %3\   - Click "Close" to save\3. 📋 SELECT APIS:\   - In the left panel, search for "Drive API v3"\   - Expand the section and select:\     ✅ https://www.googleapis.com/auth/drive\     ✅ https://www.googleapis.com/auth/drive.file\4. 🔐 AUTHORIZE:\   - Click "Authorize APIs"\   - Sign in with your Google account\   - Authorize access\5. 🎫 GET TOKENS:\   - Click "Exchange authorization code for tokens"\   - Copy the "access_token" and "refresh_token"\6. 📝 CONFIGURE IN BUSINESS CENTRAL:\   - Paste the tokens in the corresponding fields\   - Use "Test Token Validity" to verify';
        PlaygroundOpenedMsg: Label 'Google OAuth Playground has been opened.\⚠️ REMEMBER: You must configure YOUR credentials in Settings (⚙️)\Complete instructions: %1';
        TokensConfiguredMsg: Label 'Tokens configured manually successfully.';
        TokensConfiguredManuallyMsg: Label 'Tokens configured manually successfully.';
        FileUploadErrorMsg: Label 'Error uploading file: %1';
        SharedDriveErrorMsg: Label 'Error accessing shared drive: %1';
        SharedDriveAccessErrorMsg: Label 'Error accessing shared drive: %1';
        FileAccessErrorMsg: Label 'Error accessing file: %1';
        // Confirmation Labels
        DeleteFolderMsg: Label 'Are you sure you want to delete forder?';
        NotAuthenticatedErr: Label 'Error authenticating with Google Drive. Please check your credentials.';
        DeleteFolderConfirmMsg: Label 'Are you sure you want to delete the folder?';

        // Error Labels
        ConfigurationIncompleteErr: Label 'Google Drive configuration is incomplete. Please configure Client ID and Client Secret in company information.';
        InvalidSecurityStateErr: Label 'Invalid security state. Please restart the authentication process.';
        AuthenticationErrorErr: Label 'Authentication error: %1';
        ServerConnectionErrorErr: Label 'Could not connect to Google authentication server.';
        SharedDriveNotConfiguredErr: Label 'Shared drive ID is not configured. Please configure the shared drive ID in the company.';
        TokenNotFoundErr: Label 'Could not get token';
        CreateFolderErrorErr: Label 'Error creating folder';
        UploadFileErrorErr: Label 'Error uploading file';
        MoveFolderErrorErr: Label 'Error moving folder';
        MoveFileErrorErr: Label 'Error moving file';
        CopyFileErrorErr: Label 'Error copying file';
        NoServerResponseErr: Label 'No response received from Google Drive server.';
        FileAccessErrorErr: Label 'Error accessing file: %1';
        FileLinkErrorErr: Label 'Could not get file link. Verify that the file ID is correct and you have permission to access it.';
        SharedDriveAccessErrorErr: Label 'Error accessing shared drive: %1';
        UploadSharedDriveErrorErr: Label 'Error uploading file to shared drive: %1';
        CreateSharedFolderErrorErr: Label 'Error creating folder in shared drive: %1 with this URL: %2 and this JSON: %3';
        GetFileLinkErrorErr: Label 'Could not get file link.';
        GetSharedDrivesErrorErr: Label 'Error getting shared drives: %1';
        UploadSharedFileErrorErr: Label 'Error uploading file to shared drive: %1';

        // Diagnostic Labels
        ClientIdEmptyErr: Label 'Client ID is empty';
        ClientIdTooShortErr: Label 'Client ID seems too short (should be ~72 characters)';
        ClientSecretEmptyErr: Label 'Client Secret is empty';
        ClientSecretTooShortErr: Label 'Client Secret seems too short (should be ~24 characters)';
        RefreshTokenEmptyErr: Label 'Refresh Token is empty';
        AllCredentialsValidMsg: Label '✅ All credentials are present and have appropriate length';

        // OAuth Configuration Diagnostic Labels
        DiagnosticTitleMsg: Label '🔍 OAUTH CONFIGURATION DIAGNOSTIC';
        CredentialsSectionMsg: Label '📋 CREDENTIALS:';
        ClientIdLengthMsg: Label 'Client ID: %1 characters';
        ClientIdEmptyStatusMsg: Label ' ❌ EMPTY';
        ClientIdTooShortStatusMsg: Label ' ⚠️ TOO SHORT';
        ClientIdTooLongStatusMsg: Label ' ⚠️ TOO LONG';
        ClientIdOkStatusMsg: Label ' ✅ LENGTH OK';
        ClientSecretLengthMsg: Label 'Client Secret: %1 characters';
        ClientSecretEmptyStatusMsg: Label ' ❌ EMPTY';
        ClientSecretTooShortStatusMsg: Label ' ⚠️ TOO SHORT';
        ClientSecretTooLongStatusMsg: Label ' ⚠️ TOO LONG';
        ClientSecretOkStatusMsg: Label ' ✅ LENGTH OK';
        RefreshTokenLengthMsg: Label 'Refresh Token: %1 characters';
        RefreshTokenEmptyStatusMsg: Label ' ❌ EMPTY';
        RefreshTokenTooShortStatusMsg: Label ' ⚠️ TOO SHORT';
        RefreshTokenOkStatusMsg: Label ' ✅ LENGTH OK';
        UrlsSectionMsg: Label '📡 URLs:';
        AuthUriMsg: Label 'Auth URI: %1';
        TokenUriMsg: Label 'Token URI: %1';
        TokenStatusSectionMsg: Label '⏰ TOKEN STATUS:';
        NoExpirationDateMsg: Label 'No expiration date ❌';
        TokenExpiredMsg: Label 'Expired since: %1 ❌';
        TokenValidMsg: Label 'Valid until: %1 ✅';
        UnknowErrorMsg: Label 'Unknown error';

        // OAuth Playground Instructions Labels
        PlaygroundInstructionsTitleMsg: Label 'CONFIGURE OAUTH PLAYGROUND WITH YOUR CREDENTIALS:';
        PlaygroundImportantNoteMsg: Label '⚠️ IMPORTANT: You must configure YOUR credentials, not playground ones';
        PlaygroundStep1Msg: Label '1. Open this URL: %1';
        PlaygroundStep2TitleMsg: Label '2. 🔧 CONFIGURE CREDENTIALS (CRITICAL STEP):';
        PlaygroundStep2aMsg: Label '   - In the UPPER RIGHT corner, click the ⚙️ icon (Settings)';
        PlaygroundStep2bMsg: Label '   - ✅ Check the "Use your own OAuth credentials" box';
        PlaygroundStep2cMsg: Label '   - OAuth Client ID: %1';
        PlaygroundStep2dMsg: Label '   - OAuth Client Secret: %2';
        PlaygroundStep2eMsg: Label '   - Click "Close" to save';
        PlaygroundStep3TitleMsg: Label '3. 📋 SELECT APIS:';
        PlaygroundStep3aMsg: Label '   - In the left panel, search for "Drive API v3"';
        PlaygroundStep3bMsg: Label '   - Expand the section and select:';
        PlaygroundStep3cMsg: Label '     ✅ https://www.googleapis.com/auth/drive';
        PlaygroundStep3dMsg: Label '     ✅ https://www.googleapis.com/auth/drive.file';
        PlaygroundStep4TitleMsg: Label '4. 🔐 AUTHORIZE:';
        PlaygroundStep4aMsg: Label '   - Click "Authorize APIs"';
        PlaygroundStep4bMsg: Label '   - Sign in with your Google account';
        PlaygroundStep4cMsg: Label '   - Authorize access';
        PlaygroundStep5TitleMsg: Label '5. 🎫 GET TOKENS:';
        PlaygroundStep5aMsg: Label '   - Click "Exchange authorization code for tokens"';
        PlaygroundStep5bMsg: Label '   - Copy the "access_token" and "refresh_token"';
        PlaygroundStep6TitleMsg: Label '6. 📝 CONFIGURE IN BUSINESS CENTRAL:';
        PlaygroundStep6aMsg: Label '   - Paste the tokens in the corresponding fields';
        PlaygroundStep6bMsg: Label '   - Use "Test Token Validity" to verify';


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
            Error(ConfigurationIncompleteErr);
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
            Message(CopyUrlToBrowserMsg, AuthUrl);
        end else begin
            Message(BrowserOpenedMsg, AuthUrl);
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
            Error(InvalidSecurityStateErr);
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
                        Message(AuthenticationCompletedMsg);
                        exit(true);
                    end;
                end;
            end else begin
                ResponseMessage.Content().ReadAs(ResponseText);
                Error(AuthenticationErrorErr, ResponseText);
            end;
        end else begin
            Error(ServerConnectionErrorErr);
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
            Message(NoRefreshTokenMsg);
            exit(false);
        end;

        // Validate credentials before attempting refresh
        if not ValidateCredentialsForRefresh(DiagnosticInfo) then begin
            Message(CredentialsErrorMsg, DiagnosticInfo);
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
                        Message(TokenUpdatedMsg, CompanyInfo."Expiracion Token GoogleDrive");
                        exit(true);
                    end else begin
                        Message(NoAccessTokenMsg, ResponseText);
                        exit(false);
                    end;
                end else begin
                    Message(JsonParseErrorMsg, ResponseText);
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
                        ErrorDescription := UnknowerrorMsg;

                    // Provide specific guidance based on error type
                    if StrPos(ErrorDescription, 'invalid_client') > 0 then begin
                        Message(InvalidCredentialsErrorMsg, ErrorDescription, CompanyInfo."Google Client ID");
                    end else begin
                        Message(TokenUpdateErrorMsg, ResponseMessage.HttpStatusCode(), ErrorDescription, ResponseText);
                    end;
                end else begin
                    Message(TokenUpdateErrorSimpleMsg, ResponseMessage.HttpStatusCode(), ResponseText);
                end;
                exit(false);
            end;
        end else begin
            Message(ConnectionErrorMsg);
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
            DiagnosticInfo += '- ' + ClientIdEmptyErr + '\';
            IsValid := false;
        end else begin
            if StrLen(CompanyInfo."Google Client ID") < 50 then begin
                DiagnosticInfo += '- ' + ClientIdTooShortErr + '\';
                IsValid := false;
            end;
        end;

        if CompanyInfo."Google Client Secret" = '' then begin
            DiagnosticInfo += '- ' + ClientSecretEmptyErr + '\';
            IsValid := false;
        end else begin
            if StrLen(CompanyInfo."Google Client Secret") < 20 then begin
                DiagnosticInfo += '- ' + ClientSecretTooShortErr + '\';
                IsValid := false;
            end;
        end;

        if CompanyInfo."Refresh Token GoogleDrive" = '' then begin
            DiagnosticInfo += '- ' + RefreshTokenEmptyErr + '\';
            IsValid := false;
        end;

        if IsValid then
            DiagnosticInfo := AllCredentialsValidMsg;

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

        DiagnosticText := DiagnosticTitleMsg + '\' +
                         '\' +
                         CredentialsSectionMsg + '\';

        // Client ID Analysis
        ClientIdLength := StrLen(CompanyInfo."Google Client ID");
        DiagnosticText += StrSubstNo(ClientIdLengthMsg, ClientIdLength);
        if ClientIdLength = 0 then
            DiagnosticText += ClientIdEmptyStatusMsg
        else if ClientIdLength < 50 then
            DiagnosticText += ClientIdTooShortStatusMsg
        else if ClientIdLength > 80 then
            DiagnosticText += ClientIdTooLongStatusMsg
        else
            DiagnosticText += ClientIdOkStatusMsg;
        DiagnosticText += '\';

        // Client Secret Analysis
        ClientSecretLength := StrLen(CompanyInfo."Google Client Secret");
        DiagnosticText += StrSubstNo(ClientSecretLengthMsg, ClientSecretLength);
        if ClientSecretLength = 0 then
            DiagnosticText += ClientSecretEmptyStatusMsg
        else if ClientSecretLength < 20 then
            DiagnosticText += ClientSecretTooShortStatusMsg
        else if ClientSecretLength > 50 then
            DiagnosticText += ClientSecretTooLongStatusMsg
        else
            DiagnosticText += ClientSecretOkStatusMsg;
        DiagnosticText += '\';

        // Refresh Token Analysis
        RefreshTokenLength := StrLen(CompanyInfo."Refresh Token GoogleDrive");
        DiagnosticText += StrSubstNo(RefreshTokenLengthMsg, RefreshTokenLength);
        if RefreshTokenLength = 0 then
            DiagnosticText += RefreshTokenEmptyStatusMsg
        else if RefreshTokenLength < 50 then
            DiagnosticText += RefreshTokenTooShortStatusMsg
        else
            DiagnosticText += RefreshTokenOkStatusMsg;
        DiagnosticText += '\';

        // URLs
        DiagnosticText += '\' + UrlsSectionMsg + '\';
        DiagnosticText += StrSubstNo(AuthUriMsg, CompanyInfo."Google Auth URI") + '\';
        DiagnosticText += StrSubstNo(TokenUriMsg, CompanyInfo."Google Token URI") + '\';

        // Token Status
        DiagnosticText += '\' + TokenStatusSectionMsg + '\';
        if CompanyInfo."Expiracion Token GoogleDrive" = 0DT then
            DiagnosticText += NoExpirationDateMsg + '\'
        else if CompanyInfo."Expiracion Token GoogleDrive" < CurrentDateTime then
            DiagnosticText += StrSubstNo(TokenExpiredMsg, CompanyInfo."Expiracion Token GoogleDrive") + '\'
        else
            DiagnosticText += StrSubstNo(TokenValidMsg, CompanyInfo."Expiracion Token GoogleDrive") + '\';

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

            Message(AccessRevokedMsg);
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
        CompanyInfo: Record "Company Information";
        SharedDriveId: Text;
    begin
        CompanyInfo.GET();
        SharedDriveId := CompanyInfo."Google Shared Drive ID";
        if SharedDriveId <> '' then begin
            FileId := UploadFileToSharedDrive(SharedDriveId, DocumentAttachment);
            if FileId <> '' then begin
                DocumentAttachment."Google Drive ID" := FileId;
                DocumentAttachment."Store in Google Drive" := true;
                DocumentAttachment.Modify();
                exit(true);
            end;
            exit(false);
        end;
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
        if Inf."Google Shared Drive ID" <> '' then
            exit(RecuperarCarpetaSharedDrive(Inf."Google Shared Drive ID", FileId, OldParent));
        if not Authenticate() then
            Error(NotAuthenticatedErr);
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
                Message(TokenUpdateFailedMsg);
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
        SharedDriveId: Text;
    begin
        CompanyInfo.GET();
        SharedDriveId := CompanyInfo."Google Shared Drive ID";
        if (SharedDriveId = '') and (CompanyInfo."Google Shared Drive Name" <> '') then
            Error(SharedDriveNotConfiguredErr);
        if SharedDriveId <> '' then
            exit(RecuperaIdFolderSharedDrive(SharedDriveId, IdCarpeta, Carpeta, Files, Crear, RootFolder));
        Files.DeleteAll();
        if not Authenticate() then
            Error(NotAuthenticatedErr);

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
        SharedDriveId: Text;
    begin
        CompanyInfo.GET();
        SharedDriveId := CompanyInfo."Google Shared Drive ID";
        if SharedDriveId <> '' then begin
            CarpetasSharedDrive(SharedDriveId, IdCarpeta, Files);
            exit;
        end;
        Files.DeleteAll();
        if not Authenticate() then
            Error(NotAuthenticatedErr);

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
        SharedDriveId: Text;
    begin
        Inf.Get();
        SharedDriveId := Inf."Google Shared Drive ID";
        if SharedDriveId <> '' then
            exit(CreateFolderSharedDrive(SharedDriveId, Carpeta, ParentId, RootFolder));
        if not Authenticate() then
            Error(NotAuthenticatedErr);

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
            Error(CreateFolderErrorErr);
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
        SharedDriveId: Text;
    begin
        Inf.Get();
        SharedDriveId := Inf."Google Shared Drive ID";
        //if SharedDriveId <> '' then
        //  exit(UploadFileB64ToSharedDrive(SharedDriveId, Base64Data, Filename, FileExtension));
        //https://api-drive.app.elingenierojefe.es/upload
        If Not Authenticate() Then
            Error(TokenNotFoundErr);
        Url := 'https://api-drive.app.elingenierojefe.es/upload';
        Body.Add('fileName', Filename);
        Body.Add('fileType', GetMimeType(FileExtension));
        if SharedDriveId <> '' then
            Body.Add('driveId', SharedDriveId);
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
            Error(UploadFileErrorErr);
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
        SharedDriveId: Text;
    begin
        Inf.Get();
        SharedDriveId := Inf."Google Shared Drive ID";
        if SharedDriveId <> '' then
            exit(DeleteFolderSharedDrive(SharedDriveId, Carpeta, HideDialog));
        If Not HideDialog Then
            If Not Confirm(DeleteFolderMsg, true) Then
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
        SharedDriveId: Text;
    begin
        Inf.Get();
        SharedDriveId := Inf."Google Shared Drive ID";
        if SharedDriveId <> '' then
            exit(MoveFolderSharedDrive(SharedDriveId, FolderId, NewParentId));
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
            Error(MoveFolderErrorErr);
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
        SharedDriveId: Text;
    begin
        Inf.Get();
        SharedDriveId := Inf."Google Shared Drive ID";
        if SharedDriveId <> '' then
            exit(MoveFileSharedDrive(SharedDriveId, FileId, NewParentId, OldParent));
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
            Error(MoveFileErrorErr);
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
        SharedDriveId: Text;
    begin
        Inf.Get();
        SharedDriveId := Inf."Google Shared Drive ID";
        if SharedDriveId <> '' then
            exit(CopyFileSharedDrive(SharedDriveId, FileId, NewParentId));
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
            Error(CopyFileErrorErr);
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
        SharedDriveId: Text;
    begin
        Inf.Get();
        SharedDriveId := Inf."Google Shared Drive ID";
        if SharedDriveId <> '' then begin
            ListFolderSharedDrive(SharedDriveId, FolderId, Files, SoloSubfolder);
            exit;
        end;
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
        SharedDriveId: Text;
    begin
        Ticket := GoogleDrive.Token();
        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + get_metadata + FileId + '?alt=media';
        SharedDriveId := Inf."Google Shared Drive ID";
        if SharedDriveId <> '' then
            exit(DownloadFileB64SharedDrive(SharedDriveId, FileId, FileName, BajarFichero, Base64Data));
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
            Error(ConfigurationIncompleteErr);
        end;

        PlaygroundUrl := 'https://developers.google.com/oauthplayground/';

        InstructionText := PlaygroundInstructionsTitleMsg + '\' +
                          '\' +
                          PlaygroundImportantNoteMsg + '\' +
                          '\' +
                          StrSubstNo(PlaygroundStep1Msg, PlaygroundUrl) + '\' +
                          '\' +
                          PlaygroundStep2TitleMsg + '\' +
                          PlaygroundStep2aMsg + '\' +
                          PlaygroundStep2bMsg + '\' +
                          StrSubstNo(PlaygroundStep2cMsg, CompanyInfo."Google Client ID") + '\' +
                          StrSubstNo(PlaygroundStep2dMsg, CompanyInfo."Google Client Secret") + '\' +
                          PlaygroundStep2eMsg + '\' +
                          '\' +
                          PlaygroundStep3TitleMsg + '\' +
                          PlaygroundStep3aMsg + '\' +
                          PlaygroundStep3bMsg + '\' +
                          PlaygroundStep3cMsg + '\' +
                          PlaygroundStep3dMsg + '\' +
                          '\' +
                          PlaygroundStep4TitleMsg + '\' +
                          PlaygroundStep4aMsg + '\' +
                          PlaygroundStep4bMsg + '\' +
                          PlaygroundStep4cMsg + '\' +
                          '\' +
                          PlaygroundStep5TitleMsg + '\' +
                          PlaygroundStep5aMsg + '\' +
                          PlaygroundStep5bMsg + '\' +
                          '\' +
                          PlaygroundStep6TitleMsg + '\' +
                          PlaygroundStep6aMsg + '\' +
                          PlaygroundStep6bMsg;

        // Try to open playground
        if not TryOpenBrowser(PlaygroundUrl) then begin
            Message(InstructionText);
        end else begin
            Message(PlaygroundOpenedMsg, InstructionText);
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

        Message(TokensConfiguredManuallyMsg);
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
        SharedDriveId: Text;
        Inf: Record "Company Information";
    begin
        Inf.Get();
        SharedDriveId := Inf."Google Shared Drive ID";
        if SharedDriveId <> '' then
            exit(UploadFileB64ToFolderSharedDrive(SharedDriveId, TempBlob, FileName, FolderId));
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
                Message(FileUploadErrorMsg, ResponseText);
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
        SharedDriveId: Text;
    begin
        Inf.Get();
        SharedDriveId := Inf."Google Shared Drive ID";
        if SharedDriveId <> '' then begin
            OpenFileInBrowserSharedDrive(SharedDriveId, GoogleDriveID);
            exit('');
        end;
        if not Authenticate() then
            Error(NotAuthenticatedErr);


        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + get_metadata + GoogleDriveID + '?fields=webViewLink,webContentLink';

        Respuesta := RestApiToken(Url, AccessToken, RequestType::get, '');

        if Respuesta = '' then
            Error(NoServerResponseErr);

        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            Error(FileAccessErrorErr, ErrorMessage);
        end;

        if StatusInfo.Get('webViewLink', JToken) then begin
            Link := JToken.AsValue().AsText();
            Hyperlink(Link);
        end else if StatusInfo.Get('webContentLink', JToken) then begin
            Link := JToken.AsValue().AsText();
            Hyperlink(Link);
        end else begin
            Error(GetFileLinkErrorErr);
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
        SharedDriveId: Text;
    begin
        Inf.Get();
        SharedDriveId := Inf."Google Shared Drive ID";
        if SharedDriveId <> '' then
            exit(GetUrlSharedDrive(SharedDriveId, GoogleDriveID));
        if not Authenticate() then
            Error(NotAuthenticatedErr);


        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + get_metadata + GoogleDriveID + '?fields=webViewLink,webContentLink';

        Respuesta := RestApiToken(Url, AccessToken, RequestType::get, '');

        if Respuesta = '' then
            Error(NoServerResponseErr);

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
        SharedDriveId: Text;
    begin
        Inf.Get();
        SharedDriveId := Inf."Google Shared Drive ID";
        if SharedDriveId <> '' then
            exit(DeleteFileSharedDrive(SharedDriveId, GoogleDriveID));
        if not Authenticate() then
            Error(NotAuthenticatedErr);

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
        SharedDriveId: Text;
    begin
        Inf.Get();
        SharedDriveId := Inf."Google Shared Drive ID";
        if SharedDriveId <> '' then begin
            EditFileSharedDrive(SharedDriveId, GoogleDriveID);
            exit;
        end;
        if not Authenticate() then
            Error(NotAuthenticatedErr);


        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + get_metadata + GoogleDriveID + '/permissions';
        Json := '{"type": "anyone","role": "writer","allowFileDiscovery": false}';

        Respuesta := RestApiToken(Url, AccessToken, RequestType::post, Json);

        if Respuesta = '' then
            Error(NoServerResponseErr);

        Url := Inf."Url Api GoogleDrive" + get_metadata + GoogleDriveID + '?fields=webViewLink';
        Respuesta := RestApiToken(Url, AccessToken, RequestType::get, '');

        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            ErrorMessage := JToken.AsValue().AsText();
            Error(FileAccessErrorErr, ErrorMessage);
        end;

        if StatusInfo.Get('webViewLink', JToken) then begin
            Link := JToken.AsValue().AsText();
            Hyperlink(Link);
        end else if StatusInfo.Get('webContentLink', JToken) then begin
            Link := JToken.AsValue().AsText();
            Hyperlink(Link);
        end else begin
            Error(GetFileLinkErrorErr);
        end;
    end;

    internal procedure RenameDriveName(GoogleSharedDriveName: Text[250]; GoogleSharedDriveID: Text[250]): Text[250]
    var
        Client: HttpClient;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        JResponse: JsonObject;
        JToken: JsonToken;
        Url: Text;
        Json: Text;
        Respuesta: Text;
        RequestType: Option Get,patch,put,post,delete;
        StatusInfo: JsonObject;
        ErrorMessage: Text;

    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);
        Url := GoogleDriveBaseURL + '/drives/' + GoogleSharedDriveID + '?supportsAllDrives=true';
        Json := '{"name": "' + GoogleSharedDriveName + '"}';
        Respuesta := RestApiToken(Url, AccessToken, RequestType::patch, Json);
        if Respuesta = '' then
            Error(NoServerResponseErr);
        StatusInfo.ReadFrom(Respuesta);
        if StatusInfo.Get('error', JToken) then begin
            if JToken.AsObject().Get('message', JToken) then begin
                ErrorMessage := JToken.AsValue().AsText();
                Message(SharedDriveAccessErrorMsg, ErrorMessage);
                exit('');
            end;
        end;
        exit(GoogleSharedDriveID);
    end;

    internal procedure RecuperarDriveName(GoogleSharedDriveID: Text[250]): Text[250]
    var
        Url: Text;
        Respuesta: Text;
        RequestType: Option Get,patch,put,post,delete;
        StatusInfo: JsonObject;
        Json: Text;
        JToken: JsonToken;
        ErrorMessage: Text;

    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Url := GoogleDriveBaseURL + '/drives/' + GoogleSharedDriveID;
        Respuesta := RestApiToken(Url, AccessToken, RequestType::get, '');
        if Respuesta = '' then
            Error(NoServerResponseErr);
        StatusInfo.ReadFrom(Respuesta);
        StatusInfo.WriteTo(Json);
        if StatusInfo.Get('error', JToken) then begin
            if JToken.AsObject().Get('message', JToken) then begin
                ErrorMessage := JToken.AsValue().AsText();
                Message(SharedDriveAccessErrorMsg, ErrorMessage);
                exit('');
            end;
        end;
        if StatusInfo.Get('name', JToken) then
            exit(JToken.AsValue().AsText());
        exit('');

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

    // Métodos para drives compartidos de Google Drive
    procedure GetSharedDrives(var Drives: Record "Name/Value Buffer" temporary)
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
        DriveId: Text;
        DriveName: Text;
        a: Integer;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Obtener lista de drives compartidos
        Url := GoogleDriveBaseURL + '/drives';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta = '' then
            Error(NoServerResponseErr);

        StatusInfo.ReadFrom(Respuesta);

        // Verificar si hay error en la respuesta
        if StatusInfo.Get('error', JToken) then begin
            Error(GetSharedDrivesErrorErr, JToken.AsValue().AsText());
        end;

        // Procesar los resultados
        if StatusInfo.Get('drives', JToken) then begin
            JEntries := JToken.AsArray();
            a := 0;

            foreach JEntryTokens in JEntries do begin
                JEntry := JEntryTokens.AsObject();
                a += 1;

                Drives.Init();
                Drives.ID := a;

                // Obtener el ID del drive
                if JEntry.Get('id', JToken) then
                    Drives."Google Drive ID" := JToken.AsValue().AsText();

                // Obtener el nombre del drive
                if JEntry.Get('name', JToken) then
                    Drives.Name := JToken.AsValue().AsText();

                // Obtener el tipo (compartido)
                Drives.Value := 'Shared Drive';

                Drives.Insert();
            end;
        end;
    end;

    procedure GetSharedDriveId(DriveName: Text): Text
    var
        Drives: Record "Name/Value Buffer" temporary;
        DriveId: Text;
    begin
        GetSharedDrives(Drives);

        if Drives.FindSet() then begin
            repeat
                if Drives.Name = DriveName then begin
                    DriveId := Drives."Google Drive ID";
                    exit(DriveId);
                end;
            until Drives.Next() = 0;
        end;

        exit('');
    end;

    procedure ListSharedDriveFiles(DriveId: Text; var Files: Record "Name/Value Buffer" temporary)
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
        FileMang: Codeunit "File Management";
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Files.DeleteAll();
        Ticket := Token();

        // Listar archivos del drive compartido
        Url := GoogleDriveBaseURL + '/files?q=' + UrlEncode('''') + DriveId + UrlEncode('''') + '+in+parents&di&fields=files(id,name,mimeType,parents)';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);

            if StatusInfo.Get('files', JEntryToken) then begin
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
                    if JEntry.Get('mimeType', JEntryToken) then begin
                        if JEntryToken.AsValue().AsText() = 'application/vnd.google-apps.folder' then
                            ItemType := 'Carpeta'
                        else
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
                        FilesTemp."File Extension" := FileMang.GetExtension(ItemName);
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

    procedure UploadFileToSharedDrive(SharedDriveId: Text; var DocumentAttach: Record "Document Attachment"): Text
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

        exit(UploadFileB64ToSharedDrive(SharedDriveId, Int, DocumentAttach."File Name", Extension));
    end;

    procedure UploadFileB64ToSharedDrive(SharedDriveId: Text; Base64Data: InStream; Filename: Text; FileExtension: Text[30]): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Id: Text;
        Body: JsonObject;
        Json: Text;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Construir el JSON para subir archivo al drive compartido
        Clear(Body);
        Body.Add('name', Filename + '.' + FileExtension);
        Body.Add('parents', SharedDriveId);
        Body.WriteTo(Json);

        // URL para subir archivo
        Url := GoogleDriveUploadURL;

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Base64Data);

        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('id', JTokenLink) then begin
            Id := JTokenLink.AsValue().AsText();
        end else
            Error(UploadSharedFileErrorErr, Respuesta);

        exit(Id);
    end;

    procedure CreateFolderInSharedDrive(DriveId: Text; ParentFolderId: Text; FolderName: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        NewFolderId: Text;
    begin
        Ticket := Token();

        Url := GoogleDriveBaseURL + '/files';

        Clear(Body);
        Body.Add('name', FolderName);
        Body.Add('mimeType', 'application/vnd.google-apps.folder');
        if ParentFolderId <> '' then
            Body.Add('parents', ParentFolderId);
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('id', JToken) then
                NewFolderId := JToken.AsValue().AsText()
            else
                Error(CreateSharedFolderErrorErr, Respuesta, Url, Json);
        end;
        exit(NewFolderId);
    end;

    procedure GetSharedDriveFileUrl(DriveId: Text; FileId: Text): Text
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

        Url := GoogleDriveBaseURL + '/files/' + FileId + '?fields=webViewLink';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('webViewLink', JTokenLink) then begin
            WebUrl := JTokenLink.AsValue().AsText();
        end;

        exit(WebUrl);
    end;

    procedure DeleteFileFromSharedDrive(DriveId: Text; FileId: Text): Boolean
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        ResponseMessage: HttpResponseMessage;
    begin
        Ticket := Token();
        Url := GoogleDriveBaseURL + '/files/' + FileId;
        ResponseMessage := RestApiTokenResponse(Url, Ticket, RequestType::delete, '');

        if ResponseMessage.IsSuccessStatusCode() then
            exit(true)
        else
            exit(false);
    end;

    // Métodos que faltan para Google Drive Shared Drives
    procedure RecuperarCarpetaSharedDrive(SharedDriveId: Text; FileId: Text; OldParent: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        NewParentId: Text;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Obtener información del archivo para encontrar su carpeta padre
        Url := GoogleDriveBaseURL + '/files/' + FileId + '?fields=parents';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('parents', JToken) then begin
            if JToken.IsArray() then begin
                if JToken.AsArray().Get(0, JToken) then begin
                    NewParentId := JToken.AsValue().AsText();
                end;
            end;
        end;

        exit(NewParentId);
    end;

    procedure RecuperaIdFolderSharedDrive(SharedDriveId: Text; IdCarpeta: Text; Carpeta: Text; var Files: Record "Name/Value Buffer" temporary; Crear: Boolean; RootFolder: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
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
        Query: Text;
        FileMang: Codeunit "File Management";
        CompanyInfo: Record "Company Information";
    begin
        Files.DeleteAll();
        CompanyInfo.GET();
        if not Authenticate() then
            Error(NotAuthenticatedErr);
        if Not RootFolder then
            if IdCarpeta = '' then
                IdCarpeta := CompanyInfo."Root Folder ID";
        Ticket := Token();
        //https://www.googleapis.com/drive/v3/files?q='0AI4bGevdrPtQUk9PVA'+in+parents+and+mimeType='application/vnd.google-apps.folder'&driveId=0AI4bGevdrPtQUk9PVA&corpora=drive&includeItemsFromAllDrives=true&supportsAllDrives=true&fields=files(id,name,mimeType)

        if RootFolder then
            Query := 'q=' + UrlEncode('''') + SharedDriveId + UrlEncode('''') + '+in+parents+and+mimeType=''application/vnd.google-apps.folder''+&driveId=' + SharedDriveId + '&corpora=drive&includeItemsFromAllDrives=true'
        else
            Query := 'q=' + UrlEncode('''') + IdCarpeta + UrlEncode('''') + '+in+parents+and+mimeType=''application/vnd.google-apps.folder''';

        Url := GoogleDriveBaseURL + '/files?' + Query + '&supportsAllDrives=true&fields=files(id,name,mimeType)';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('files', JToken) then begin
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

                    if JEntry.Get('mimeType', JToken) then begin
                        if JToken.AsValue().AsText() = 'application/vnd.google-apps.folder' then begin
                            Files.Value := 'Carpeta';
                            if Files.Name = Carpeta then begin
                                Found := true;
                                ResultId := Files."Google Drive ID";
                            end;
                        end else begin
                            Files.Value := '';
                            Extension := FileMang.GetExtension(Files.Name);
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
            ResultId := CreateFolderSharedDrive(SharedDriveId, Carpeta, IdCarpeta, RootFolder);
            exit(ResultId);
        end;

        exit('');
    end;

    procedure CarpetasSharedDrive(SharedDriveId: Text; IdCarpeta: Text; var Files: Record "Name/Value Buffer" temporary)
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JValue: JsonArray;
        JEntry: JsonObject;
        JToken: JsonToken;
        JEntryTokens: JsonToken;
        a: Integer;
        Extension: Text;
        Query: Text;
        FileMang: Codeunit "File Management";
    begin
        Files.DeleteAll();
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        if IdCarpeta = '' then
            Query := 'q=' + '+in+parents&driveId=' + SharedDriveId + '&corpora=drive'
        else
            Query := 'q=' + UrlEncode('''') + IdCarpeta + UrlEncode('''') + '+in+parents&driveId=' + SharedDriveId + '&corpora=drive';

        Url := GoogleDriveBaseURL + '/files?' + Query + '&fields=files(id,name,mimeType)';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('files', JToken) then begin
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

                    if JEntry.Get('mimeType', JToken) then begin
                        if JToken.AsValue().AsText() = 'application/vnd.google-apps.folder' then begin
                            Files.Value := 'Carpeta';
                        end else begin
                            Files.Value := '';
                            Extension := FileMang.GetExtension(Files.Name);
                            if StrLen(Extension) < 30 then
                                Files."File Extension" := Extension;
                        end;
                    end;
                    Files.Insert();
                end;
            end;
        end;
    end;

    procedure CreateFolderSharedDrive(SharedDriveId: Text; Carpeta: Text; ParentId: Text; RootFolder: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Body: JsonObject;
        Json: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        NewFolderId: Text;
        JsonArray: JsonArray;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        Url := GoogleDriveBaseURL + '/files?supportsAllDrives=true';

        Clear(Body);
        Body.Add('name', Carpeta);
        Body.Add('mimeType', 'application/vnd.google-apps.folder');
        if RootFolder then
            JsonArray.Add(SharedDriveId)
        else
            JsonArray.Add(ParentId);
        Body.Add('parents', JsonArray);

        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('id', JToken) then
                NewFolderId := JToken.AsValue().AsText()
            else
                Error(CreateSharedFolderErrorErr, Respuesta, Url, Json);
        end;
        exit(NewFolderId);
    end;

    procedure UploadFileB64ToFolderSharedDrive(SharedDriveId: Text; TempBlob: Codeunit "Temp Blob"; FileName: Text; FolderId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Id: Text;
        Body: JsonObject;
        Json: Text;
        InStr: InStream;
        Boundary: Text;
        CrLf: Text;
        FileContent: Text;
        ContentText: Text;
        RequestHeaders: HttpHeaders;
        RequestContent: HttpContent;
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        JResponse: JsonObject;
        JToken: JsonToken;
        InStream: InStream;
        Convert: Codeunit "Base64 Convert";
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        TempBlob.CreateInStream(InStr);

        // Construir el JSON para subir archivo a la carpeta específica
        TempBlob.CreateInStream(InStream);
        FileContent := Convert.ToBase64(InStream);

        // Prepare multipart upload
        URL := GoogleDriveUploadURL + '?uploadType=multipart&supportsAllDrives=true';

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
                Message(FileUploadErrorMsg, ResponseText);
            end;
        end;

        exit('');
    end;

    procedure DeleteFolderSharedDrive(SharedDriveId: Text; IdCarpeta: Text; HideDialog: Boolean): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;

    begin
        if not HideDialog then
            if not Confirm(DeleteFolderMsg, true) then
                exit('');

        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Obtener el ID del archivo/carpeta
        // Id := GetFileIdSharedDrive(Carpeta, SharedDriveId);

        // if Id = '' then
        //     Error('Carpeta no encontrada: %1', Carpeta);

        Url := GoogleDriveBaseURL + '/files/' + IdCarpeta + '?supportsAllDrives=true';
        //https://www.googleapis.com/drive/v3/files/{fileId}?supportsAllDrives=true

        Respuesta := RestApiToken(Url, Ticket, RequestType::delete, '');

        exit('');
    end;

    procedure MoveFolderSharedDrive(SharedDriveId: Text; FolderId: Text; NewParentId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Id: Text;
        Body: JsonObject;
        Json: Text;
        JTokO: JsonToken;
        JTok: JsonToken;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Mover carpeta
        Url := GoogleDriveBaseURL + '/files/' + FolderId + '&supportsAllDrives=true';
        //PATCH https://www.googleapis.com/drive/v3/files/{fileId}?addParents={newFolderId}&removeParents={oldFolderId}&supportsAllDrives=true

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
            Error(MoveFolderErrorErr);
        end;

        exit(Id);
    end;

    procedure MoveFileSharedDrive(SharedDriveId: Text; FileId: Text; NewParentId: Text; OldParent: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Id: Text;
        Body: JsonObject;
        Json: Text;
        JTokO: JsonToken;
        JTok: JsonToken;
        Inf: Record "Company Information";
    begin
        Inf.Get();
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Mover archivo
        Url := Inf."Url Api GoogleDrive" + move_folder + FileId +
                '?addParents=' + NewParentId +
                '&removeParents=' + OldParent + '&supportsAllDrives=true';

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
            Error(MoveFileErrorErr);
        end;

        exit(Id);
    end;

    procedure CopyFileSharedDrive(SharedDriveId: Text; FileId: Text; NewParentId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JTokenLink: JsonToken;
        Id: Text;
        Body: JsonObject;
        Json: Text;
        JTokO: JsonToken;
        JTok: JsonToken;
        Inf: Record "Company Information";
        GoogleDrive: Codeunit "Google Drive Manager";
        ParentsArray: JsonArray;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Copiar archivo
        Ticket := GoogleDrive.Token();
        Inf.Get;
        Url := Inf."Url Api GoogleDrive" + move_folder + FileId + '/copy?supportsAllDrives=true';
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
            Error(CopyFileErrorErr);
        end;

        exit(Id);
    end;

    procedure ListFolderSharedDrive(SharedDriveId: Text; FolderId: Text; var Files: Record "Name/Value Buffer" temporary; SoloSubfolder: Boolean)
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
        Query: Text;
        FileMang: Codeunit "File Management";
        Inf: Record "Company Information";
        C: Label '''';
    begin
        Inf.Get();
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Files.DeleteAll();
        Ticket := Token();
        Url := Inf."Url Api GoogleDrive" + list_folder;
        //GET https://www.googleapis.com/drive/v3/files?q='PARENT_ID'+in+parents&driveId=DRIVE_ID&corpora=drive&includeItemsFromAllDrives=true&supportsAllDrives=true&fields=files(id,name,mimeType)

        if SoloSubfolder then begin
            If FolderId <> '' Then
                Url := Url + '?q=' + C + FolderId + C + '+in+parents&driveId=' + SharedDriveId + '&corpora=drive&includeItemsFromAllDrives=true&supportsAllDrives=true&fields=files(id%2Cname%2CmimeType%2Ctrashed)'
            else
                Url := Url + '?q=' + C + Inf."Root Folder ID" + C + '+in+parents&driveId=' + SharedDriveId + '&corpora=drive&trashed=false&includeItemsFromAllDrives=true&supportsAllDrives=true&fields=files(id%2Cname%2CmimeType%2Ctrashed)';

        end else
            Url := Url + '?q=' + C + Inf."Root Folder ID" + C + '+in+parents&driveId=' + SharedDriveId + '&corpora=drive&trashed=false&includeItemsFromAllDrives=true&supportsAllDrives=true&fields=files(id%2Cname%2CmimeType%2Ctrashed)';
        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);

            if StatusInfo.Get('files', JEntryToken) then begin
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
                    if JEntry.Get('mimeType', JEntryToken) then begin
                        if JEntryToken.AsValue().AsText() = 'application/vnd.google-apps.folder' then begin
                            ItemType := 'Carpeta';
                        end else begin
                            ItemType := '';
                        end;
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
                        FilesTemp."File Extension" := FileMang.GetExtension(ItemName);
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

    procedure DownloadFileB64SharedDrive(SharedDriveId: Text; FileId: Text; FileName: Text; BajarFichero: Boolean; var Base64Data: Text): Boolean
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
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
        InStream: InStream;
        OutStream: OutStream;
        Convert: Codeunit "Base64 Convert";
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        Url := GoogleDriveBaseURL + '/files/' + FileId + '?alt=media&supportsAllDrives=true';

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

    procedure OpenFileInBrowserSharedDrive(SharedDriveId: Text; GoogleDriveID: Text)
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        WebUrl: Text;
        ErrorMessage: Text;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        Url := GoogleDriveBaseURL + '/files/' + GoogleDriveID + '?fields=webViewLink&supportsAllDrives=true';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta = '' then
            Error(NoServerResponseErr);

        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('error', JToken) then begin
            if JToken.AsObject().Get('message', JToken) then begin
                ErrorMessage := JToken.AsValue().AsText();
                Message(SharedDriveAccessErrorMsg, ErrorMessage);
                exit;
            end;

        end;

        if StatusInfo.Get('webViewLink', JToken) then begin
            WebUrl := JToken.AsValue().AsText();
            Hyperlink(WebUrl);
        end else begin
            Error(GetFileLinkErrorErr);
        end;
    end;

    procedure GetUrlSharedDrive(SharedDriveId: Text; GoogleDriveID: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        WebUrl: Text;
        ErrorMessage: Text;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        // Para drives compartidos, necesitamos especificar el drive en la URL
        Url := GoogleDriveBaseURL + '/files/' + GoogleDriveID + '?fields=webViewLink&supportsAllDrives=true';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta = '' then
            Error(NoServerResponseErr);

        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('error', JToken) then begin
            //{"code":404,"message":"File not found: 1U-EJcwyNFWeYJuKYaucnETL6AtxM5ZX3.","errors":[{"message":"File not found: 1U-EJcwyNFWeYJuKYaucnETL6AtxM5ZX3.","domain":"global","reason":"notFound","location":"fileId","locationType":"parameter"}]}
            if JToken.AsObject().Get('message', JToken) then begin
                if JToken.AsObject().Get('message', JToken) then begin
                    ErrorMessage := JToken.AsValue().AsText();
                    Message(SharedDriveAccessErrorMsg, ErrorMessage);
                    exit('');
                end;
                exit('');
            end;
        end;

        if StatusInfo.Get('webViewLink', JToken) then begin
            WebUrl := JToken.AsValue().AsText();
            exit(WebUrl);
        end else begin
            Error(GetFileLinkErrorErr);
        end;
    end;

    procedure DeleteFileSharedDrive(SharedDriveId: Text; GoogleDriveID: Text): Boolean
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        ResponseMessage: HttpResponseMessage;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        Url := GoogleDriveBaseURL + '/files/' + GoogleDriveID + '?supportsAllDrives=true';
        ResponseMessage := RestApiTokenResponse(Url, Ticket, RequestType::delete, '');

        if ResponseMessage.IsSuccessStatusCode() then
            exit(true)
        else
            exit(false);
    end;

    procedure EditFileSharedDrive(SharedDriveId: Text; GoogleDriveID: Text)
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        WebUrl: Text;
        ErrorMessage: Text;
        Inf: Record "Company Information";
        Json: Text;
    begin
        Inf.Get();
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();
        Url := Inf."Url Api GoogleDrive" + get_metadata + GoogleDriveID + '/permissions';
        Json := '{"type": "anyone","role": "writer","allowFileDiscovery": false}';

        Respuesta := RestApiToken(Url, AccessToken, RequestType::post, Json);

        if Respuesta = '' then
            Error(NoServerResponseErr);
        Url := GoogleDriveBaseURL + '/files/' + GoogleDriveID + '?fields=webViewLink&supportsAllDrives=true';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');

        if Respuesta = '' then
            Error(NoServerResponseErr);

        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('error', JToken) then begin
            if JToken.AsObject().Get('message', JToken) then begin
                ErrorMessage := JToken.AsValue().AsText();
                Message(FileAccessErrorMsg, ErrorMessage);
                exit;
            end;
            Error(FileAccessErrorErr, ErrorMessage);
        end;

        if StatusInfo.Get('webViewLink', JToken) then begin
            WebUrl := JToken.AsValue().AsText();
            Hyperlink(WebUrl);
        end else begin
            Error(GetFileLinkErrorErr);
        end;
    end;

    procedure GetFileIdSharedDrive(FilePath: Text; SharedDriveId: Text): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JTokenLink: JsonToken;
        Id: Text;
        Query: Text;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);

        Ticket := Token();

        // Obtener información del archivo en drive compartido
        Query := 'q=' + UrlEncode('name=''' + FilePath + ''' in parents&driveId=' + SharedDriveId + '&corpora=drive');
        Url := GoogleDriveBaseURL + '/files?' + Query + '&fields=files(id,name)&supportsAllDrives=true';

        Respuesta := RestApiToken(Url, Ticket, RequestType::get, '');
        StatusInfo.ReadFrom(Respuesta);

        if StatusInfo.Get('files', JTokenLink) then begin
            if JTokenLink.IsArray() then begin
                if JTokenLink.AsArray().Get(0, JTokenLink) then begin
                    if JTokenLink.IsObject() then begin
                        if JTokenLink.AsObject().Get('id', JTokenLink) then begin
                            Id := JTokenLink.AsValue().AsText();
                        end;
                    end;
                end;
            end;
        end;

        exit(Id);
    end;

    procedure RenameFolder(RootFolderID: Text[250]; RootFolder: Text[250]): Text
    var
        Ticket: Text;
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        ErrorMessage: Text;
        CompanyInfo: Record "Company Information";
        Json: Text;
    begin
        if not Authenticate() then
            Error(NotAuthenticatedErr);
        CompanyInfo.Get();
        Ticket := Token();
        if CompanyInfo."Google Shared Drive ID" <> '' then
            Url := GoogleDriveBaseURL + '/files/' + RootFolderID + '?supportsAllDrives=true'
        else
            Url := GoogleDriveBaseURL + '/files/' + RootFolderID;
        Json := '{"name":"' + RootFolder + '"}';
        Respuesta := RestApiToken(Url, Ticket, RequestType::patch, Json);
        StatusInfo.ReadFrom(Respuesta);
        if StatusInfo.Get('error', JToken) then begin
            if JToken.AsObject().Get('message', JToken) then begin
                ErrorMessage := JToken.AsValue().AsText();
                Message(SharedDriveAccessErrorMsg, ErrorMessage);
                exit('');
            end;

        end;
        exit('');
    end;
}