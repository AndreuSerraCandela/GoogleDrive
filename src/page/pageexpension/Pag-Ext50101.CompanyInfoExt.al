pageextension 95101 "Company Info Ext" extends "Company Information"
{
    layout
    {
        addafter(General)
        {
            group("Google Drive Configuration")
            {
                Caption = 'Configuración Google Drive';

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
            }

            group("Google Drive Tokens")
            {
                Caption = 'Tokens Google Drive';

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
        }
    }

    actions
    {
        addlast(Processing)
        {
            group("Google Drive")
            {
                Caption = 'Google Drive';

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
                        TokenFieldsEditable := not TokenFieldsEditable;
                        if TokenFieldsEditable then
                            Message('Campos de tokens habilitados para edición manual.')
                        else
                            Message('Campos de tokens bloqueados.');
                        CurrPage.Update();
                    end;
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
            }
        }
    }

    var
        TokenFieldsEditable: Boolean;

    trigger OnOpenPage()
    begin
        TokenFieldsEditable := false;
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