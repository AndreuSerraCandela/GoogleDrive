page 95112 "Drive Configuration"
{
    Caption = 'Storage Configuration';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Company Information";
    Permissions = tabledata "Company Information" = RIMD,
                  tabledata "Document Attachment" = RIMD,
                  tabledata "Name/Value Buffer" = RIMD,
                  tabledata "Google Drive Folder Mapping" = RIMD;

    layout
    {
        area(Content)
        {
            group(General)
            {
                group("Storage Provider")
                {
                    Caption = 'Storage Provider';

                    field("Data Storage Provider"; Rec."Data Storage Provider")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Select the data storage provider to use.';
                        trigger OnValidate()
                        begin
                            IsGoogleDrive := Rec."Data Storage Provider" = Rec."Data Storage Provider"::"Google Drive";
                            IsOneDrive := Rec."Data Storage Provider" = Rec."Data Storage Provider"::OneDrive;
                            IsDropBox := Rec."Data Storage Provider" = Rec."Data Storage Provider"::DropBox;
                            IsStrapi := Rec."Data Storage Provider" = Rec."Data Storage Provider"::Strapi;
                            Rec."Root Folder ID" := '';
                            Rec."Root Folder" := '';
                            CurrPage.Update(false);
                        end;
                    }
                    field("Funcionalidad extendida"; Rec."Funcionalidad extendida")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies if extended functionality is enabled.';
                    }
                }

                group("Google Drive Configuration")
                {
                    Caption = 'Google Drive Configuration';
                    Visible = IsGoogleDrive;

                    field("Google Client ID"; Rec."Google Client ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Client ID of the Google OAuth application.';
                    }

                    field("Google Client Secret"; Rec."Google Client Secret")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Client Secret of the Google OAuth application.';
                        ExtendedDatatype = Masked;
                    }

                    field("Google Project ID"; Rec."Google Project ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Project ID from Google Cloud Console.';
                    }

                    field("Google Auth URI"; Rec."Google Auth URI")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the authorization URI of Google OAuth.';
                    }

                    field("Google Token URI"; Rec."Google Token URI")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the token URI of Google OAuth.';
                    }

                    field("Google Auth Provider Cert URL"; Rec."Google Auth Provider Cert URL")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the URL of the Google authentication provider certificate.';
                    }

                    field("Url Api GoogleDrive"; Rec."Url Api GoogleDrive")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the base URL of the Google Drive API.';
                    }
                    field("Google Drive Root Folder"; Rec."Root Folder")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the root folder of Google Drive.';
                    }
                    field("Google Shared Drive Name"; Rec."Google Shared Drive Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the name of the shared Google Drive folder.';
                        Editable = false;
                    }
                    field("Google Shared Drive ID"; Rec."Google Shared Drive ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the ID of the shared Google Drive folder.';
                    }

                }

                group("Google Drive Tokens")
                {
                    Caption = 'Google Drive Tokens';
                    Visible = IsGoogleDrive;

                    field("Token GoogleDrive"; Rec."Token GoogleDrive")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Current access token for Google Drive.';
                        ExtendedDatatype = Masked;
                        Editable = TokenFieldsEditable;

                        trigger OnValidate()
                        begin
                            if Rec."Token GoogleDrive" <> '' then
                                Rec."Expiracion Token GoogleDrive" := CurrentDateTime + 3600000; // 1 hour default
                        end;
                    }

                    field("Refresh Token GoogleDrive"; Rec."Refresh Token GoogleDrive")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Refresh token for Google Drive.';
                        ExtendedDatatype = Masked;
                        Editable = TokenFieldsEditable;
                    }
                    field("Code GoogleDrive"; Rec."Code GoogleDrive")
                    {
                        ApplicationArea = All;
                    }

                    field("Fecha Expiracion Token GoogleDrive"; Rec."Expiracion Token GoogleDrive")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Date and time when the access token expires.';
                        Editable = false;
                    }
                }

                group("OneDrive Configuration")
                {
                    Caption = 'OneDrive Configuration';
                    Visible = IsOneDrive;

                    field("OneDrive Client ID"; Rec."OneDrive Client ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Client ID of the OneDrive OAuth application.';
                    }

                    field("OneDrive Client Secret"; Rec."OneDrive Client Secret")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Client Secret of the OneDrive OAuth application.';
                        ExtendedDatatype = Masked;
                    }

                    field("OneDrive Tenant ID"; Rec."OneDrive Tenant ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Tenant ID from Microsoft Azure.';
                    }
                    field("Url Api OneDrive"; Rec."Url Api OneDrive")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the base URL of the OneDrive API.';
                    }

                    field("OneDrive Root Folder"; Rec."Root Folder")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the root folder of OneDrive.';
                    }
                    field("OneDrive Site Url"; Rec."OneDrive Site Url")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the URL of the OneDrive site.';
                    }
                    field("OneDrive Site ID"; Rec."OneDrive Site ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the ID of the OneDrive site.';
                    }
                    field("Code Ondrive"; Rec."Code Ondrive")
                    {
                        ApplicationArea = All;
                    }
                }

                group("OneDrive Tokens")
                {
                    Caption = 'OneDrive Tokens';
                    Visible = IsOneDrive;

                    field("OneDrive Access Token"; Rec."OneDrive Access Token")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Current access token for OneDrive.';
                        Editable = TokenFieldsEditable;
                    }

                    field("OneDrive Refresh Token"; Rec."OneDrive Refresh Token")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Refresh token for OneDrive.';
                        Editable = TokenFieldsEditable;
                    }

                    field("OneDrive Token Expiration"; Rec."OneDrive Token Expiration")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Date and time when the access token expires.';
                        Editable = false;
                    }
                }

                group("DropBox Configuration")
                {
                    Caption = 'DropBox Configuration';
                    Visible = IsDropBox;

                    field("DropBox App Key"; Rec."DropBox App Key")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the App Key of the DropBox application.';
                    }

                    field("DropBox App Secret"; Rec."DropBox App Secret")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the App Secret of the DropBox application.';
                        ExtendedDatatype = Masked;
                    }

                    field("Url Api DropBox"; Rec."Url Api DropBox")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the base URL of the DropBox API.';
                    }

                    field("DropBox Root Folder"; Rec."Root Folder")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the root folder of DropBox.';
                    }
                    field("Code DropBox"; Rec."Code DropBox")
                    {
                        ApplicationArea = All;
                    }
                }

                group("DropBox Tokens")
                {
                    Caption = 'DropBox Tokens';
                    Visible = IsDropBox;

                    field("DropBox Access Token"; TokenDropBox)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Current access token for DropBox.';
                        ExtendedDatatype = Masked;
                        Editable = TokenFieldsEditable;
                        trigger OnValidate()
                        begin
                            Rec.SetTokenDropbox(TokenDropBox);
                        end;
                    }

                    field("DropBox Refresh Token"; Rec."DropBox Refresh Token")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Refresh token for DropBox.';
                        ExtendedDatatype = Masked;
                        Editable = TokenFieldsEditable;
                    }

                    field("DropBox Token Expiration"; Rec."DropBox Token Expiration")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Date and time when the access token expires.';
                        Editable = false;
                    }
                }

                group("Strapi Configuration")
                {
                    Caption = 'Strapi Configuration';
                    Visible = IsStrapi;

                    field("Strapi Base URL"; Rec."Strapi Base URL")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the base URL of the Strapi API.';
                    }

                    field("Strapi API Token"; Rec."Strapi API Token")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the API token of Strapi.';
                        ExtendedDatatype = Masked;
                    }

                    field("Strapi Username"; Rec."Strapi Username")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Strapi username.';
                    }

                    field("Strapi Password"; Rec."Strapi Password")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Strapi password.';
                        ExtendedDatatype = Masked;
                    }

                    field("Strapi Collection Name"; Rec."Strapi Collection Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the collection name in Strapi.';
                    }
                }
                group("SharePoint Configuration")
                {
                    Caption = 'SharePoint Configuration';
                    Visible = IsSharePoint;

                    field("SharePoint Client ID"; Rec."SharePoint Client ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Client ID of the SharePoint OAuth application.';
                    }

                    field("SharePoint Client Secret"; Rec."SharePoint Client Secret")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Client Secret of the SharePoint OAuth application.';
                        ExtendedDatatype = Masked;
                    }
                    field("SharePoint Tenant ID"; Rec."SharePoint Tenant ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Tenant ID from Microsoft Azure.';
                    }
                    field("SharePoint Site ID"; Rec."SharePoint Site ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Site ID of SharePoint.';
                    }
                    field("Url Api SharePoint"; Rec."Url Api SharePoint")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the base URL of the SharePoint API.';
                    }
                }
                group("SharePoint Tokens")
                {
                    Caption = 'SharePoint Tokens';
                    Visible = IsSharePoint;
                    field("SharePoint Access Token"; Rec."SharePoint Access Token")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Current access token for SharePoint.';
                        Editable = TokenFieldsEditable;
                    }
                    field("SharePoint Refresh Token"; Rec."SharePoint Refresh Token")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Refresh token for SharePoint.';
                        Editable = TokenFieldsEditable;
                    }
                    field("SharePoint Token Expiration"; Rec."SharePoint Token Expiration")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Date and time when the access token expires.';
                        Editable = false;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group("Google Drive")
            {
                Caption = 'Google Drive';
                Visible = IsGoogleDrive;


                action("Configure Default Settings")
                {
                    ApplicationArea = All;
                    Caption = 'Configure Default Settings';
                    ToolTip = 'Configures default values for the connection with Google Drive.';
                    Image = Setup;

                    trigger OnAction()
                    begin
                        SetDefaultGoogleDriveSettings();
                    end;
                }

                action("Start OAuth Flow")
                {
                    ApplicationArea = All;
                    Caption = 'Start OAuth Flow';
                    ToolTip = 'Starts the OAuth authentication process with Google Drive.';
                    Image = Web;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                    begin
                        GoogleDriveManager.Initialize();
                        GoogleDriveManager.StartOAuthFlow();
                    end;
                }

                action("Start OAuth Playground")
                {
                    ApplicationArea = All;
                    Caption = 'Use OAuth Playground (Recommended)';
                    ToolTip = 'Opens Google OAuth Playground to obtain tokens manually.';
                    Image = Web;
                    //Promoted = true;
                    //PromotedCategory = Process;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                    begin
                        GoogleDriveManager.Initialize();
                        GoogleDriveManager.StartOAuthFlowPlayground();
                    end;
                }

                action("Get Token")
                {
                    ApplicationArea = All;
                    Caption = 'Get Token';
                    ToolTip = 'Completes the OAuth authentication process with the authorization code.';
                    Image = Approve;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                    begin
                        GoogleDriveManager.Initialize();
                        GoogleDriveManager.CompleteOAuthFlow(Rec."Code GoogleDrive", Rec."Google Project ID");
                    end;
                }

                action("Test Connection")
                {
                    ApplicationArea = All;
                    Caption = 'Test Connection';
                    ToolTip = 'Tests the connection with Google Drive using the current configuration.';
                    Image = TestReport;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                    begin
                        GoogleDriveManager.Initialize();
                        if GoogleDriveManager.Authenticate() then
                            Message(GoogleDriveConnectionSuccessLbl)
                        else
                            Message(GoogleDriveConnectionErrorLbl);
                    end;
                }

                action("Refresh Token")
                {
                    ApplicationArea = All;
                    Caption = 'Refresh Token';
                    ToolTip = 'Refreshes the access token using the refresh token.';
                    Image = Refresh;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                        AccessToken: Text;
                    begin
                        GoogleDriveManager.Initialize();
                        GoogleDriveManager.RefreshAccessToken(AccessToken);
                    end;
                }

                action("Test Token Validity")
                {
                    ApplicationArea = All;
                    Caption = 'Test Token Validity';
                    ToolTip = 'Verifies if the current token is valid and not expired.';
                    Image = TestReport;

                    trigger OnAction()
                    begin
                        TestTokenValidity();
                    end;
                }

                action("Revoke Access")
                {
                    ApplicationArea = All;
                    Caption = 'Revoke Access';
                    ToolTip = 'Revokes access to Google Drive and clears stored tokens.';
                    Image = Delete;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                    begin
                        if Confirm(RevokeAccessConfirmLbl, false) then begin
                            GoogleDriveManager.Initialize();
                            GoogleDriveManager.RevokeAccess();
                        end;
                    end;
                }

                action("Validate Configuration")
                {
                    ApplicationArea = All;
                    Caption = 'Validate Configuration';
                    ToolTip = 'Validates that all configuration fields are complete.';
                    Image = ValidateEmailLoggingSetup;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                    begin
                        GoogleDriveManager.Initialize();
                        if GoogleDriveManager.ValidateConfiguration() then
                            Message(ConfigurationValidLbl)
                        else
                            Message(ConfigurationIncompleteLbl);
                    end;
                }

                action("Enable Manual Token Entry")
                {
                    ApplicationArea = All;
                    Caption = 'Enable Manual Token Entry';
                    ToolTip = 'Allows manual editing of token fields.';
                    Image = Edit;

                    trigger OnAction()
                    begin
                        TokenFieldsEditable := true;
                        CurrPage.Update();
                    end;
                }



                action("Diagnose OAuth Configuration")
                {
                    ApplicationArea = All;
                    Caption = 'Diagnose OAuth Configuration';
                    ToolTip = 'Performs a complete diagnosis of the OAuth configuration to identify issues.';
                    Image = Troubleshoot;
                    //Promoted = true;
                    //PromotedCategory = Process;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                        DiagnosticResult: Text;
                    begin
                        GoogleDriveManager.Initialize();
                        DiagnosticResult := GoogleDriveManager.DiagnoseOAuthConfiguration();
                        Message(DiagnosticResult);
                    end;
                }
                action("Google Drive Id Drive")
                {
                    ApplicationArea = All;
                    Caption = 'Id Drive';
                    ToolTip = 'Gets the ID of the Google Drive site.';
                    Image = Web;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                    begin
                        GoogleDriveManager.Initialize();
                        Rec."Google Shared Drive ID" := GoogleDriveManager.GetSharedDriveId(Rec."Google Shared Drive Name");
                        if Rec.WritePermission() then
                            Rec.Modify();
                    end;
                }
                action("Liberar Google Drive Id")
                {
                    ApplicationArea = All;
                    Caption = 'Release Google Drive Id';
                    ToolTip = 'Release the Google Drive Id.';
                    Image = Web;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                    begin
                        Rec."Google Shared Drive ID" := '';
                        if Rec.WritePermission() then
                            Rec.Modify();
                    end;
                }

            }

            group("OneDrive")
            {
                Caption = 'OneDrive';
                Visible = IsOneDrive;

                action("OneDrive Test Connection")
                {
                    ApplicationArea = All;
                    Caption = 'Test Connection';
                    ToolTip = 'Tests the connection with OneDrive using the current configuration.';
                    Image = TestReport;

                    trigger OnAction()
                    var
                        OneDriveManager: Codeunit "OneDrive Manager";
                    begin
                        OneDriveManager.Initialize();
                        if OneDriveManager.Authenticate() then
                            Message(OneDriveConnectionSuccessLbl)
                        else
                            Message(OneDriveConnectionErrorLbl);
                    end;
                }

                action("OneDrive Start OAuth")
                {
                    ApplicationArea = All;
                    Caption = 'Start OAuth';
                    ToolTip = 'Starts the OAuth authentication process with OneDrive.';
                    Image = Web;

                    trigger OnAction()
                    var
                        OneDriveManager: Codeunit "OneDrive Manager";
                    begin
                        OneDriveManager.Initialize();
                        OneDriveManager.StartOAuthFlow();
                    end;
                }

                action("Actualizar OneDrive Token")
                {
                    ApplicationArea = All;
                    Caption = 'Update Token';
                    ToolTip = 'Update the access token using the refresh token.';
                    Image = Refresh;

                    trigger OnAction()
                    var
                        OneDriveManager: Codeunit "OneDrive Manager";
                        DriveTokenManagement: Record "Drive Token Management";
                    begin
                        OneDriveManager.Initialize();
                        If not DriveTokenManagement.Get(DriveTokenManagement."Storage Provider"::"OneDrive") then begin
                            DriveTokenManagement.Init();
                            DriveTokenManagement."Storage Provider" := DriveTokenManagement."Storage Provider"::"OneDrive";
                            DriveTokenManagement.Insert();
                        end;
                        Rec.CalcFields("OneDrive Access Token");
                        if Rec."OneDrive Access Token".HasValue = false Then begin
                            OneDriveManager.ObtenerToken(Rec."Code Ondrive", DriveTokenManagement);
                            Commit();
                        end;
                        OneDriveManager.RefreshAccessToken();
                    end;
                }

                action("OneDrive Validate Configuration")
                {
                    ApplicationArea = All;
                    Caption = 'Validate Configuration';
                    ToolTip = 'Validates that all configuration fields are complete.';
                    Image = ValidateEmailLoggingSetup;

                    trigger OnAction()
                    var
                        OneDriveManager: Codeunit "OneDrive Manager";
                    begin
                        OneDriveManager.Initialize();
                        if OneDriveManager.ValidateConfiguration() then
                            Message(ConfigurationValidLbl)
                        else
                            Message(ConfigurationIncompleteLbl);
                    end;
                }

                action("OneDrive Id Site")
                {
                    ApplicationArea = All;
                    Caption = 'Id Site';
                    ToolTip = 'Gets the ID of the OneDrive site.';
                    Image = Web;

                    trigger OnAction()
                    var
                        OneDriveManager: Codeunit "OneDrive Manager";
                    begin
                        Rec."OneDrive Site ID" := OneDriveManager.GetSharedSiteId(Rec."OneDrive Site Url");
                        if Rec.WritePermission() then
                            Rec.Modify();
                    end;
                }

            }

            group("DropBox")
            {
                Caption = 'DropBox';
                Visible = IsDropBox;

                action("DropBox Test Connection")
                {
                    ApplicationArea = All;
                    Caption = 'Test Connection';
                    ToolTip = 'Tests the connection with DropBox using the current configuration.';
                    Image = TestReport;

                    trigger OnAction()
                    var
                        DropBoxManager: Codeunit "DropBox Manager";
                    begin
                        DropBoxManager.Initialize();
                        if DropBoxManager.Authenticate() then
                            Message(DropBoxConnectionSuccessLbl)
                        else
                            Message(DropBoxConnectionErrorLbl);
                    end;
                }

                action("DropBox Start OAuth")
                {
                    ApplicationArea = All;
                    Caption = 'Start OAuth';
                    ToolTip = 'Starts the OAuth authentication process with DropBox.';
                    Image = Web;

                    trigger OnAction()
                    var
                        DropBoxManager: Codeunit "DropBox Manager";
                    begin
                        DropBoxManager.Initialize();
                        DropBoxManager.StartOAuthFlow();
                    end;
                }


                action("Actualizar DropBox Token")
                {
                    ApplicationArea = All;
                    Caption = 'Update Token';
                    ToolTip = 'Update the access token using the refresh token.';
                    Image = Refresh;

                    trigger OnAction()
                    var
                        DropBoxManager: Codeunit "DropBox Manager";
                    begin
                        DropBoxManager.Initialize();
                        DropBoxManager.RefreshAccessToken();
                    end;
                }

                action("DropBox Validate Configuration")
                {
                    ApplicationArea = All;
                    Caption = 'Validate Configuration';
                    ToolTip = 'Validates that all configuration fields are complete.';
                    Image = ValidateEmailLoggingSetup;

                    trigger OnAction()
                    var
                        DropBoxManager: Codeunit "DropBox Manager";
                    begin
                        DropBoxManager.Initialize();
                        if DropBoxManager.ValidateConfiguration() then
                            Message(ConfigurationValidLbl)
                        else
                            Message(ConfigurationIncompleteLbl);
                    end;
                }

            }

            group("Strapi")
            {
                Caption = 'Strapi';
                Visible = IsStrapi;

                action("Strapi Test Connection")
                {
                    ApplicationArea = All;
                    Caption = 'Test Connection';
                    ToolTip = 'Tests the connection with Strapi using the current configuration.';
                    Image = TestReport;

                    trigger OnAction()
                    var
                        StrapiManager: Codeunit "Strapi Manager";
                    begin
                        StrapiManager.Initialize();
                        if StrapiManager.Authenticate() then
                            Message(StrapiConnectionSuccessLbl)
                        else
                            Message(StrapiConnectionErrorLbl);
                    end;
                }

                action("Strapi Validate Configuration")
                {
                    ApplicationArea = All;
                    Caption = 'Validate Configuration';
                    ToolTip = 'Validates that all configuration fields are complete.';
                    Image = ValidateEmailLoggingSetup;

                    trigger OnAction()
                    var
                        StrapiManager: Codeunit "Strapi Manager";
                    begin
                        StrapiManager.Initialize();
                        if StrapiManager.ValidateConfiguration() then
                            Message(ConfigurationValidLbl)
                        else
                            Message(ConfigurationIncompleteLbl);
                    end;
                }

                action("Strapi Test API")
                {
                    ApplicationArea = All;
                    Caption = 'Test API';
                    ToolTip = 'Tests the Strapi API with the current configuration.';
                    Image = TestReport;

                    trigger OnAction()
                    var
                        StrapiManager: Codeunit "Strapi Manager";
                    begin
                        StrapiManager.Initialize();
                        StrapiManager.TestAPI();
                    end;
                }

            }
            group("SharePoint")
            {
                Caption = 'SharePoint';
                Visible = IsSharePoint;
                action("SharePoint Test Connection")
                {
                    ApplicationArea = All;
                    Caption = 'Test Connection';
                    ToolTip = 'Tests the connection with SharePoint using the current configuration.';
                    Image = TestReport;
                }
                action("SharePoint Start OAuth")
                {
                    ApplicationArea = All;
                    Caption = 'Start OAuth';
                    ToolTip = 'Starts the OAuth authentication process with SharePoint.';
                    Image = Web;
                }
                action("Actualizar SharePoint Token")
                {
                    ApplicationArea = All;
                    Caption = 'Update Token';
                    ToolTip = 'Update the access token using the refresh token.';
                    Image = Refresh;
                }
                action("SharePoint Validate Configuration")
                {
                    ApplicationArea = All;
                    Caption = 'Validate Configuration';
                    ToolTip = 'Validates that all configuration fields are complete.';
                    Image = ValidateEmailLoggingSetup;
                }
                action("SharePoint Test API")
                {
                    ApplicationArea = All;
                    Caption = 'Test API';
                    ToolTip = 'Tests the SharePoint API with the current configuration.';
                    Image = TestReport;
                }

            }
            action("Folder Mapping Setup")
            {
                ApplicationArea = All;
                Caption = 'Configure Folder Mapping';
                ToolTip = 'Configures which Google Drive folders to use for each document type.';
                Image = Setup;
                //Promoted = true;
                //PromotedCategory = Process;

                trigger OnAction()
                var
                    FolderMappingPage: Page "Google Drive Folder Mapping";
                begin
                    FolderMappingPage.Run();
                end;
            }
            action("Crea Root")
            {
                ApplicationArea = All;
                Image = FiledPosted;
                trigger OnAction()
                var
                    GoogleMapping: Record "Google Drive Folder Mapping";
                begin
                    if Rec."Root Folder" <> '' then
                        Rec."Root Folder ID" := GoogleMapping.RecuperarIdFolder(Rec."Root Folder", false, true);

                end;
            }
            action("Show Manual")
            {
                ApplicationArea = All;
                Caption = 'Show Manual';
                ToolTip = 'Shows the user manual for the Drive.';
                Image = Help;
                //Promoted = true;
                //PromotedCategory = Process;

                trigger OnAction()
                var
                    GoogleDriveManualViewer: Page "Google Drive Manual Viewer";
                begin
                    GoogleDriveManualViewer.Run();
                end;
            }

        }
        area(Promoted)
        {
            actionref(FolderMappingSetupAction; "Folder Mapping Setup") { }
            actionref(TokenGoogleDriveAction; "Get Token") { }
            actionref(TokenOneDriveAction; "Actualizar OneDrive Token") { }
            actionref(TokenDropBoxAction; "Actualizar DropBox Token") { }
            actionref(CreaRootDriveAction; "Crea Root") { }
            //actionref(CreaRootOneDriveAction; "Crea Root One Drive") { }
            //actionref(CreaRootDropBoxAction; "Crea Root DropBox") { }
            //actionref(CreaRootStrapiAction; "Crea Root Strapi") { }
        }
    }

    var
        TokenFieldsEditable: Boolean;
        IsGoogleDrive: Boolean;
        IsOneDrive: Boolean;
        IsDropBox: Boolean;
        IsStrapi: Boolean;
        IsSharePoint: Boolean;
        TokenDropBox: Text;
        // Labels for messages
        GoogleDriveConnectionSuccessLbl: Label '✅ Google Drive connection successful.';
        GoogleDriveConnectionErrorLbl: Label '❌ Connection error. Check configuration.';
        ConfigurationValidLbl: Label '✅ Configuration valid.';
        ConfigurationIncompleteLbl: Label '❌ Incomplete configuration. Please ensure all fields are filled.';
        OneDriveConnectionSuccessLbl: Label '✅ OneDrive connection successful.';
        OneDriveConnectionErrorLbl: Label '❌ Connection error. Check configuration.';
        DropBoxConnectionSuccessLbl: Label '✅ DropBox connection successful.';
        DropBoxConnectionErrorLbl: Label '❌ Connection error. Check configuration.';
        StrapiConnectionSuccessLbl: Label '✅ Strapi connection successful.';
        StrapiConnectionErrorLbl: Label '❌ Connection error. Check configuration.';
        DefaultValuesConfiguredLbl: Label 'Default values configured successfully.';
        NoTokenConfiguredLbl: Label '❌ No token configured.';
        TokenValidUntilLbl: Label '✅ Token valid until: %1';
        TokenExpiredSinceLbl: Label '❌ Token expired since: %1. Use "Refresh Token" to renew it.';
        RevokeAccessConfirmLbl: Label 'Are you sure you want to revoke Google Drive access?';
        ChooseStorageTypeCaptionLbl: Label 'Choose storage type';


    trigger OnOpenPage()
    begin
        TokenFieldsEditable := false;
        IsGoogleDrive := Rec."Data Storage Provider" = Rec."Data Storage Provider"::"Google Drive";
        IsOneDrive := Rec."Data Storage Provider" = Rec."Data Storage Provider"::OneDrive;
        IsDropBox := Rec."Data Storage Provider" = Rec."Data Storage Provider"::DropBox;
        IsStrapi := Rec."Data Storage Provider" = Rec."Data Storage Provider"::Strapi;
        IsSharePoint := Rec."Data Storage Provider" = Rec."Data Storage Provider"::SharePoint;
    end;

    trigger OnAfterGetRecord()
    begin
        IsGoogleDrive := Rec."Data Storage Provider" = Rec."Data Storage Provider"::"Google Drive";
        IsOneDrive := Rec."Data Storage Provider" = Rec."Data Storage Provider"::OneDrive;
        IsDropBox := Rec."Data Storage Provider" = Rec."Data Storage Provider"::DropBox;
        IsStrapi := Rec."Data Storage Provider" = Rec."Data Storage Provider"::Strapi;
        TokenDropBox := Rec.GetTokenDropbox();
        IsSharePoint := Rec."Data Storage Provider" = Rec."Data Storage Provider"::SharePoint;
    end;

    local procedure SetDefaultGoogleDriveSettings()
    begin
        if Rec."Google Auth URI" = '' then
            Rec."Google Auth URI" := 'https://accounts.google.com/o/oauth2/auth';

        if Rec."Google Token URI" = '' then
            Rec."Google Token URI" := 'https://oauth2.googleapis.com/token';

        if Rec."Google Auth Provider Cert URL" = '' then
            Rec."Google Auth Provider Cert URL" := 'https://www.googleapis.com/oauth2/v1/certs';

        if Rec."Url Api GoogleDrive" = '' then
            Rec."Url Api GoogleDrive" := 'https://www.googleapis.com/drive/v3/';

        if Rec."Url Api SharePoint" = '' then
            Rec."Url Api SharePoint" := 'https://graph.microsoft.com/v1.0/';

        Rec.Modify();
        Message(DefaultValuesConfiguredLbl);
    end;

    local procedure TestTokenValidity()
    var
        IsValid: Boolean;
        ExpirationText: Text;
    begin
        if Rec."Token GoogleDrive" = '' then begin
            Message(NoTokenConfiguredLbl);
            exit;
        end;

        IsValid := Rec."Expiracion Token GoogleDrive" > CurrentDateTime;

        if IsValid then begin
            ExpirationText := Format(Rec."Expiracion Token GoogleDrive");
            Message(TokenValidUntilLbl, ExpirationText);
        end else begin
            ExpirationText := Format(Rec."Expiracion Token GoogleDrive");
            Message(TokenExpiredSinceLbl, ExpirationText);
        end;
    end;

    local procedure GetOneDriveSiteId()
    var
        OneDriveManager: Codeunit "OneDrive Manager";
    begin
        Rec."OneDrive Site ID" := OneDriveManager.GetSharedSiteId(Rec."OneDrive Site Url");
    end;

    procedure CargaTipoDive(Info: Record "Company Information")
    begin
        IsGoogleDrive := Info."Data Storage Provider" = Info."Data Storage Provider"::"Google Drive";
        IsOneDrive := Info."Data Storage Provider" = Info."Data Storage Provider"::OneDrive;
        IsDropBox := Info."Data Storage Provider" = Info."Data Storage Provider"::DropBox;
        IsStrapi := Info."Data Storage Provider" = Info."Data Storage Provider"::Strapi;
        IsSharePoint := Info."Data Storage Provider" = Info."Data Storage Provider"::SharePoint;

    end;
}
pageextension 95101 CompanyInfoExt extends "Company Information"
{
    actions
    {
        addlast(Processing)
        {
            action("Drive Configuration")
            {
                ApplicationArea = All;
                Caption = 'Storage Configuration';
                trigger OnAction()
                var
                    TiopoConfiguracion: Label 'Local,Google Drive, OneDrive, DropBox, Strapi, SharePoint';
                    OpcionElegida: Integer;

                begin
                    if Rec."Data Storage Provider" = Rec."Data Storage Provider"::Local Then begin
                        OpcionElegida := StrMenu(TiopoConfiguracion, 1, 'Choose storage type');
                        case OpcionElegida of
                            1:
                                Rec."Data Storage Provider" := Rec."Data Storage Provider"::Local;
                            2:
                                Rec."Data Storage Provider" := Rec."Data Storage Provider"::"Google Drive";
                            3:
                                Rec."Data Storage Provider" := Rec."Data Storage Provider"::OneDrive;
                            4:
                                Rec."Data Storage Provider" := Rec."Data Storage Provider"::DropBox;
                            5:
                                Rec."Data Storage Provider" := Rec."Data Storage Provider"::Strapi;
                            6:
                                Rec."Data Storage Provider" := Rec."Data Storage Provider"::SharePoint;
                        end;
                        Rec.Modify();
                        Commit();
                    end;
                    Page.Run(Page::"Drive Configuration", Rec);
                end;
            }
        }
        addlast(Promoted)
        {
            actionref(DriveConfigurationAction; "Drive Configuration") { }
        }
    }
}