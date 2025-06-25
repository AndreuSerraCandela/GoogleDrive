pageextension 95101 "Company Info Ext" extends "Company Information"
{
    layout
    {
        addafter(General)
        {
            group("Proveedor de Almacenamiento")
            {
                Caption = 'Proveedor de Almacenamiento';

                field("Data Storage Provider"; Rec."Data Storage Provider")
                {
                    ApplicationArea = All;
                    ToolTip = 'Selecciona el proveedor de almacenamiento de datos a utilizar.';
                }
                field("Funcionalidad extendida"; Rec."Funcionalidad extendida")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica si la funcionalidad extendida está habilitada.';
                }
            }

            group("Google Drive Configuration")
            {
                Caption = 'Configuración Google Drive';
                Visible = IsGoogleDrive;

                field("Google Client ID"; Rec."Google Client ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el Client ID de la aplicación Google OAuth.';
                }

                field("Google Client Secret"; Rec."Google Client Secret")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el Client Secret de la aplicación Google OAuth.';
                    ExtendedDatatype = Masked;
                }

                field("Google Project ID"; Rec."Google Project ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el Project ID de Google Cloud Console.';
                }

                field("Google Auth URI"; Rec."Google Auth URI")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la URI de autorización de Google OAuth.';
                }

                field("Google Token URI"; Rec."Google Token URI")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la URI del token de Google OAuth.';
                }

                field("Google Auth Provider Cert URL"; Rec."Google Auth Provider Cert URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la URL del certificado del proveedor de autenticación de Google.';
                }

                field("Url Api GoogleDrive"; Rec."Url Api GoogleDrive")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la URL base de la API de Google Drive.';
                }
                field("Google Drive Root Folder"; Rec."Root Folder")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la carpeta raíz de Google Drive.';
                }

            }

            group("Google Drive Tokens")
            {
                Caption = 'Tokens Google Drive';
                Visible = IsGoogleDrive;

                field("Token GoogleDrive"; Rec."Token GoogleDrive")
                {
                    ApplicationArea = All;
                    ToolTip = 'Token de acceso actual de Google Drive.';
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
                    ToolTip = 'Token de actualización de Google Drive.';
                    ExtendedDatatype = Masked;
                    Editable = TokenFieldsEditable;
                }

                field("Fecha Expiracion Token GoogleDrive"; Rec."Expiracion Token GoogleDrive")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha y hora de expiración del token de acceso.';
                    Editable = false;
                }
            }

            group("OneDrive Configuration")
            {
                Caption = 'Configuración OneDrive';
                Visible = IsOneDrive;

                field("OneDrive Client ID"; Rec."OneDrive Client ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el Client ID de la aplicación OneDrive OAuth.';
                }

                field("OneDrive Client Secret"; Rec."OneDrive Client Secret")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el Client Secret de la aplicación OneDrive OAuth.';
                    ExtendedDatatype = Masked;
                }

                field("OneDrive Tenant ID"; Rec."OneDrive Tenant ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el Tenant ID de Microsoft Azure.';
                }
                field("Url Api OneDrive"; Rec."Url Api OneDrive")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la URL base de la API de OneDrive.';
                }

                field("OneDrive Root Folder"; Rec."Root Folder")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la carpeta raíz de OneDrive.';
                }
                field("Code Ondrive"; Rec."Code Ondrive")
                {
                    ApplicationArea = All;
                }
            }

            group("OneDrive Tokens")
            {
                Caption = 'Tokens OneDrive';
                Visible = IsOneDrive;

                field("OneDrive Access Token"; Rec."OneDrive Access Token")
                {
                    ApplicationArea = All;
                    ToolTip = 'Token de acceso actual de OneDrive.';
                    Editable = TokenFieldsEditable;
                }

                field("OneDrive Refresh Token"; Rec."OneDrive Refresh Token")
                {
                    ApplicationArea = All;
                    ToolTip = 'Token de actualización de OneDrive.';
                    Editable = TokenFieldsEditable;
                }

                field("OneDrive Token Expiration"; Rec."OneDrive Token Expiration")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha y hora de expiración del token de acceso.';
                    Editable = false;
                }
            }

            group("DropBox Configuration")
            {
                Caption = 'Configuración DropBox';
                Visible = IsDropBox;

                field("DropBox App Key"; Rec."DropBox App Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la App Key de la aplicación DropBox.';
                }

                field("DropBox App Secret"; Rec."DropBox App Secret")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la App Secret de la aplicación DropBox.';
                    ExtendedDatatype = Masked;
                }

                field("Url Api DropBox"; Rec."Url Api DropBox")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la URL base de la API de DropBox.';
                }

                field("DropBox Root Folder"; Rec."Root Folder")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la carpeta raíz de DropBox.';
                }
            }

            group("DropBox Tokens")
            {
                Caption = 'Tokens DropBox';
                Visible = IsDropBox;

                field("DropBox Access Token"; Rec."DropBox Access Token")
                {
                    ApplicationArea = All;
                    ToolTip = 'Token de acceso actual de DropBox.';
                    ExtendedDatatype = Masked;
                    Editable = TokenFieldsEditable;
                }

                field("DropBox Refresh Token"; Rec."DropBox Refresh Token")
                {
                    ApplicationArea = All;
                    ToolTip = 'Token de actualización de DropBox.';
                    ExtendedDatatype = Masked;
                    Editable = TokenFieldsEditable;
                }

                field("DropBox Token Expiration"; Rec."DropBox Token Expiration")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha y hora de expiración del token de acceso.';
                    Editable = false;
                }
            }

            group("Strapi Configuration")
            {
                Caption = 'Configuración Strapi';
                Visible = IsStrapi;

                field("Strapi Base URL"; Rec."Strapi Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la URL base de la API de Strapi.';
                }

                field("Strapi API Token"; Rec."Strapi API Token")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el token de API de Strapi.';
                    ExtendedDatatype = Masked;
                }

                field("Strapi Username"; Rec."Strapi Username")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el nombre de usuario de Strapi.';
                }

                field("Strapi Password"; Rec."Strapi Password")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la contraseña de Strapi.';
                    ExtendedDatatype = Masked;
                }

                field("Strapi Collection Name"; Rec."Strapi Collection Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el nombre de la colección en Strapi.';
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            group("Google Drive")
            {
                Caption = 'Google Drive';
                Visible = IsGoogleDrive;


                action("Configure Default Settings")
                {
                    ApplicationArea = All;
                    Caption = 'Configurar Valores por Defecto';
                    ToolTip = 'Configura los valores por defecto para la conexión con Google Drive.';
                    Image = Setup;

                    trigger OnAction()
                    begin
                        SetDefaultGoogleDriveSettings();
                    end;
                }

                action("Start OAuth Flow")
                {
                    ApplicationArea = All;
                    Caption = 'Iniciar Autenticación OAuth';
                    ToolTip = 'Inicia el proceso de autenticación OAuth con Google Drive.';
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
                    Caption = 'Usar OAuth Playground (Recomendado)';
                    ToolTip = 'Abre Google OAuth Playground para obtener tokens de forma manual.';
                    Image = Web;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                    begin
                        GoogleDriveManager.Initialize();
                        GoogleDriveManager.StartOAuthFlowPlayground();
                    end;
                }

                action("Complete OAuth")
                {
                    ApplicationArea = All;
                    Caption = 'Completar OAuth';
                    ToolTip = 'Completa el proceso de autenticación OAuth con el código de autorización.';
                    Image = Approve;

                    trigger OnAction()
                    var
                        OAuthDialog: Page "OAuth Completion Dialog";
                    begin
                        OAuthDialog.RunModal();
                    end;
                }

                action("Test Connection")
                {
                    ApplicationArea = All;
                    Caption = 'Probar Conexión';
                    ToolTip = 'Prueba la conexión con Google Drive usando la configuración actual.';
                    Image = TestReport;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                    begin
                        GoogleDriveManager.Initialize();
                        if GoogleDriveManager.Authenticate() then
                            Message('✅ Conexión exitosa con Google Drive.')
                        else
                            Message('❌ Error en la conexión. Verifique la configuración.');
                    end;
                }

                action("Refresh Token")
                {
                    ApplicationArea = All;
                    Caption = 'Actualizar Token';
                    ToolTip = 'Actualiza el token de acceso usando el refresh token.';
                    Image = Refresh;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                    begin
                        GoogleDriveManager.Initialize();
                        GoogleDriveManager.RefreshAccessToken();
                    end;
                }

                action("Test Token Validity")
                {
                    ApplicationArea = All;
                    Caption = 'Probar Validez del Token';
                    ToolTip = 'Verifica si el token actual es válido y no ha expirado.';
                    Image = TestReport;

                    trigger OnAction()
                    begin
                        TestTokenValidity();
                    end;
                }

                action("Revoke Access")
                {
                    ApplicationArea = All;
                    Caption = 'Revocar Acceso';
                    ToolTip = 'Revoca el acceso a Google Drive y limpia los tokens almacenados.';
                    Image = Delete;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                    begin
                        if Confirm('¿Está seguro de que desea revocar el acceso a Google Drive?', false) then begin
                            GoogleDriveManager.Initialize();
                            GoogleDriveManager.RevokeAccess();
                        end;
                    end;
                }

                action("Validate Configuration")
                {
                    ApplicationArea = All;
                    Caption = 'Validar Configuración';
                    ToolTip = 'Valida que todos los campos de configuración estén completos.';
                    Image = ValidateEmailLoggingSetup;

                    trigger OnAction()
                    var
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                    begin
                        GoogleDriveManager.Initialize();
                        if GoogleDriveManager.ValidateConfiguration() then
                            Message('✅ Configuración válida.')
                        else
                            Message('❌ Configuración incompleta. Verifique que todos los campos estén llenos.');
                    end;
                }

                action("Enable Manual Token Entry")
                {
                    ApplicationArea = All;
                    Caption = 'Habilitar Entrada Manual de Tokens';
                    ToolTip = 'Permite editar manualmente los campos de tokens.';
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
                    Caption = 'Diagnosticar Configuración OAuth';
                    ToolTip = 'Ejecuta un diagnóstico completo de la configuración OAuth para identificar problemas.';
                    Image = Troubleshoot;
                    Promoted = true;
                    PromotedCategory = Process;

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
                action("Crea Root Google Drive")
                {
                    ApplicationArea = All;
                    Image = FiledPosted;
                    trigger OnAction()
                    var
                        GoogleMapping: Record "Google Drive Folder Mapping";
                    begin
                        if Rec."Root Folder" <> '' then
                            Rec."Root Folder ID" := GoogleMapping.RecuperarIdFolder(Rec."Root Folder", true, true);
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
                    Caption = 'Probar Conexión';
                    ToolTip = 'Prueba la conexión con OneDrive usando la configuración actual.';
                    Image = TestReport;

                    trigger OnAction()
                    var
                        OneDriveManager: Codeunit "OneDrive Manager";
                    begin
                        OneDriveManager.Initialize();
                        if OneDriveManager.Authenticate() then
                            Message('✅ Conexión exitosa con OneDrive.')
                        else
                            Message('❌ Error en la conexión. Verifique la configuración.');
                    end;
                }

                action("OneDrive Start OAuth")
                {
                    ApplicationArea = All;
                    Caption = 'Iniciar OAuth';
                    ToolTip = 'Inicia el proceso de autenticación OAuth con OneDrive.';
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
                    Caption = 'Actualizar Token';
                    ToolTip = 'Actualiza el token de acceso usando el refresh token.';
                    Image = Refresh;

                    trigger OnAction()
                    var
                        OneDriveManager: Codeunit "OneDrive Manager";
                    begin
                        OneDriveManager.Initialize();
                        Rec.CalcFields("OneDrive Access Token");
                        if Rec."OneDrive Access Token".HasValue = false Then begin
                            OneDriveManager.ObtenerToken(Rec."Code Ondrive");
                            Commit();
                        end;
                        OneDriveManager.RefreshAccessToken();
                    end;
                }

                action("OneDrive Validate Configuration")
                {
                    ApplicationArea = All;
                    Caption = 'Validar Configuración';
                    ToolTip = 'Valida que todos los campos de configuración estén completos.';
                    Image = ValidateEmailLoggingSetup;

                    trigger OnAction()
                    var
                        OneDriveManager: Codeunit "OneDrive Manager";
                    begin
                        OneDriveManager.Initialize();
                        if OneDriveManager.ValidateConfiguration() then
                            Message('✅ Configuración válida.')
                        else
                            Message('❌ Configuración incompleta. Verifique que todos los campos estén llenos.');
                    end;
                }
                action("Crea Root One Drive")
                {
                    ApplicationArea = All;
                    Image = FiledPosted;
                    trigger OnAction()
                    var
                        GoogleMapping: Record "Google Drive Folder Mapping";
                    begin
                        if Rec."Root Folder" <> '' then
                            Rec."Root Folder ID" := GoogleMapping.RecuperarIdFolder(Rec."Root Folder", true, true);
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
                    Caption = 'Probar Conexión';
                    ToolTip = 'Prueba la conexión con DropBox usando la configuración actual.';
                    Image = TestReport;

                    trigger OnAction()
                    var
                        DropBoxManager: Codeunit "DropBox Manager";
                    begin
                        DropBoxManager.Initialize();
                        if DropBoxManager.Authenticate() then
                            Message('✅ Conexión exitosa con DropBox.')
                        else
                            Message('❌ Error en la conexión. Verifique la configuración.');
                    end;
                }

                action("DropBox Start OAuth")
                {
                    ApplicationArea = All;
                    Caption = 'Iniciar OAuth';
                    ToolTip = 'Inicia el proceso de autenticación OAuth con DropBox.';
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
                    Caption = 'Actualizar Token';
                    ToolTip = 'Actualiza el token de acceso usando el refresh token.';
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
                    Caption = 'Validar Configuración';
                    ToolTip = 'Valida que todos los campos de configuración estén completos.';
                    Image = ValidateEmailLoggingSetup;

                    trigger OnAction()
                    var
                        DropBoxManager: Codeunit "DropBox Manager";
                    begin
                        DropBoxManager.Initialize();
                        if DropBoxManager.ValidateConfiguration() then
                            Message('✅ Configuración válida.')
                        else
                            Message('❌ Configuración incompleta. Verifique que todos los campos estén llenos.');
                    end;
                }
                action("Crea Root DropBox")
                {
                    ApplicationArea = All;
                    Image = FiledPosted;
                    trigger OnAction()
                    var
                        GoogleMapping: Record "Google Drive Folder Mapping";
                    begin
                        if Rec."Root Folder" <> '' then
                            Rec."Root Folder ID" := GoogleMapping.RecuperarIdFolder(Rec."Root Folder", true, true);
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
                    Caption = 'Probar Conexión';
                    ToolTip = 'Prueba la conexión con Strapi usando la configuración actual.';
                    Image = TestReport;

                    trigger OnAction()
                    var
                        StrapiManager: Codeunit "Strapi Manager";
                    begin
                        StrapiManager.Initialize();
                        if StrapiManager.Authenticate() then
                            Message('✅ Conexión exitosa con Strapi.')
                        else
                            Message('❌ Error en la conexión. Verifique la configuración.');
                    end;
                }

                action("Strapi Validate Configuration")
                {
                    ApplicationArea = All;
                    Caption = 'Validar Configuración';
                    ToolTip = 'Valida que todos los campos de configuración estén completos.';
                    Image = ValidateEmailLoggingSetup;

                    trigger OnAction()
                    var
                        StrapiManager: Codeunit "Strapi Manager";
                    begin
                        StrapiManager.Initialize();
                        if StrapiManager.ValidateConfiguration() then
                            Message('✅ Configuración válida.')
                        else
                            Message('❌ Configuración incompleta. Verifique que todos los campos estén llenos.');
                    end;
                }

                action("Strapi Test API")
                {
                    ApplicationArea = All;
                    Caption = 'Probar API';
                    ToolTip = 'Prueba la API de Strapi con la configuración actual.';
                    Image = TestReport;

                    trigger OnAction()
                    var
                        StrapiManager: Codeunit "Strapi Manager";
                    begin
                        StrapiManager.Initialize();
                        StrapiManager.TestAPI();
                    end;
                }
                action("Crea Root Strapi")
                {
                    ApplicationArea = All;
                    Image = FiledPosted;
                    trigger OnAction()
                    var
                        GoogleMapping: Record "Google Drive Folder Mapping";
                    begin
                        if Rec."Root Folder" <> '' then
                            Rec."Root Folder ID" := GoogleMapping.RecuperarIdFolder(Rec."Root Folder", true, true);
                    end;
                }
            }
            action("Folder Mapping Setup")
            {
                ApplicationArea = All;
                Caption = 'Configurar Mapeo de Carpetas';
                ToolTip = 'Configura qué carpetas de Google Drive usar para cada tipo de documento.';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    FolderMappingPage: Page "Google Drive Folder Mapping";
                begin
                    FolderMappingPage.Run();
                end;
            }
            action("Show Manual")
            {
                ApplicationArea = All;
                Caption = 'Mostrar Manual';
                ToolTip = 'Muestra el manual de usuario del Drive.';
                Image = Help;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    GoogleDriveManualViewer: Page "Google Drive Manual Viewer";
                begin
                    GoogleDriveManualViewer.Run();
                end;
            }

        }
    }

    var
        TokenFieldsEditable: Boolean;
        IsGoogleDrive: Boolean;
        IsOneDrive: Boolean;
        IsDropBox: Boolean;
        IsStrapi: Boolean;

    trigger OnOpenPage()
    begin
        TokenFieldsEditable := false;
        IsGoogleDrive := Rec."Data Storage Provider" = Rec."Data Storage Provider"::"Google Drive";
        IsOneDrive := Rec."Data Storage Provider" = Rec."Data Storage Provider"::OneDrive;
        IsDropBox := Rec."Data Storage Provider" = Rec."Data Storage Provider"::DropBox;
        IsStrapi := Rec."Data Storage Provider" = Rec."Data Storage Provider"::Strapi;
    end;

    trigger OnAfterGetRecord()
    begin
        IsGoogleDrive := Rec."Data Storage Provider" = Rec."Data Storage Provider"::"Google Drive";
        IsOneDrive := Rec."Data Storage Provider" = Rec."Data Storage Provider"::OneDrive;
        IsDropBox := Rec."Data Storage Provider" = Rec."Data Storage Provider"::DropBox;
        IsStrapi := Rec."Data Storage Provider" = Rec."Data Storage Provider"::Strapi;
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

        Rec.Modify();
        Message('Valores por defecto configurados exitosamente.');
    end;

    local procedure TestTokenValidity()
    var
        IsValid: Boolean;
        ExpirationText: Text;
    begin
        if Rec."Token GoogleDrive" = '' then begin
            Message('❌ No hay token configurado.');
            exit;
        end;

        IsValid := Rec."Expiracion Token GoogleDrive" > CurrentDateTime;

        if IsValid then begin
            ExpirationText := Format(Rec."Expiracion Token GoogleDrive");
            Message('✅ Token válido hasta: %1', ExpirationText);
        end else begin
            ExpirationText := Format(Rec."Expiracion Token GoogleDrive");
            Message('❌ Token expirado desde: %1\' +
                   'Use "Actualizar Token" para renovarlo.', ExpirationText);
        end;
    end;
}