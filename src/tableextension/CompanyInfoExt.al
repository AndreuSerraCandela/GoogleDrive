tableextension 95101 "Company Info Ext" extends "Company Information"
{
    fields
    {
        //añadir campo boolean llamado "Funcionalidad extendida"
        field(95135; "Funcionalidad extendida"; Boolean)
        {
            Caption = 'Funcionalidad extendida';
            DataClassification = CustomerContent;
        }
        field(95100; "Expiracion Token GoogleDrive"; DateTime)
        {
            Caption = 'Google Drive Token Expiration';
            DataClassification = CustomerContent;
        }
        field(95101; "Url Api GoogleDrive"; Text[250])
        {
            Caption = 'Google Drive API URL';
            DataClassification = CustomerContent;
        }
        field(95102; "Token GoogleDrive"; Text[1024])
        {
            Caption = 'Google Drive Token';
            DataClassification = CustomerContent;
        }
        field(95103; "Refresh Token GoogleDrive"; Text[1024])
        {
            Caption = 'Google Drive Refresh Token';
            DataClassification = CustomerContent;
        }
        field(95104; "Google Client ID"; Text[250])
        {
            Caption = 'Google Client ID';
            DataClassification = CustomerContent;
        }
        field(95105; "Google Client Secret"; Text[250])
        {
            Caption = 'Google Client Secret';
            DataClassification = CustomerContent;
        }
        field(95106; "Google Project ID"; Text[250])
        {
            Caption = 'Google Project ID';
            DataClassification = CustomerContent;
        }
        field(95107; "Google Auth URI"; Text[250])
        {
            Caption = 'Google Auth URI';
            DataClassification = CustomerContent;
        }
        field(95108; "Google Token URI"; Text[250])
        {
            Caption = 'Google Token URI';
            DataClassification = CustomerContent;
        }
        field(95109; "Google Auth Provider Cert URL"; Text[250])
        {
            Caption = 'Google Auth Provider Cert URL';
            DataClassification = CustomerContent;
        }
        field(95110; "Google Drive Root Folder"; Text[250])
        {

            Caption = 'Google Drive Root Folder';
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
                GoogleMapping: Record "Google Drive Folder Mapping";
            begin
                if "Google Drive Root Folder" <> '' then
                    "Google Drive Root Folder ID" := GoogleMapping.RecuperarIdFolder("Google Drive Root Folder", true, true);
            end;
        }
        field(95111; "Google Drive Root Folder ID"; Text[250])
        {
            Caption = 'Google Drive Root Folder ID';
            DataClassification = CustomerContent;
        }
        field(95112; "Google Drive Manual"; Blob)
        {
            Caption = 'Google Drive Manual';
            DataClassification = CustomerContent;
        }
        field(95113; "Google Manual Last Update"; DateTime)
        {
            Caption = 'Google Drive Manual Last Update';
            DataClassification = CustomerContent;
        }

        // Campo para seleccionar el proveedor de almacenamiento
        field(95114; "Data Storage Provider"; Enum "Data Storage Provider")
        {
            Caption = 'Data Storage Provider';
            DataClassification = CustomerContent;
        }

        // Campos específicos para OneDrive
        field(95115; "OneDrive Client ID"; Text[250])
        {
            Caption = 'OneDrive Client ID';
            DataClassification = CustomerContent;
        }
        field(95116; "OneDrive Client Secret"; Text[250])
        {
            Caption = 'OneDrive Client Secret';
            DataClassification = CustomerContent;
        }
        field(95117; "OneDrive Tenant ID"; Text[250])
        {
            Caption = 'OneDrive Tenant ID';
            DataClassification = CustomerContent;
        }
        field(95118; "OneDrive Access Token"; Blob)
        {
            Caption = 'OneDrive Access Token';
            DataClassification = CustomerContent;
        }
        field(95119; "OneDrive Refresh Token"; Blob)
        {
            Caption = 'OneDrive Refresh Token';
            DataClassification = CustomerContent;
        }
        field(95120; "OneDrive Token Expiration"; DateTime)
        {
            Caption = 'OneDrive Token Expiration';
            DataClassification = CustomerContent;
        }
        field(95121; "OneDrive Root Folder"; Text[250])
        {
            Caption = 'OneDrive Root Folder';
            DataClassification = CustomerContent;
        }
        field(95134; "Url Api OneDrive"; Text[250])
        {
            Caption = 'OneDrive API URL';
            DataClassification = CustomerContent;
        }

        // Campos específicos para DropBox
        field(95122; "DropBox App Key"; Text[250])
        {
            Caption = 'DropBox App Key';
            DataClassification = CustomerContent;
        }
        field(95123; "DropBox App Secret"; Text[250])
        {
            Caption = 'DropBox App Secret';
            DataClassification = CustomerContent;
        }
        field(95124; "DropBox Access Token"; Text[1024])
        {
            Caption = 'DropBox Access Token';
            DataClassification = CustomerContent;
        }
        field(95125; "DropBox Refresh Token"; Text[1024])
        {
            Caption = 'DropBox Refresh Token';
            DataClassification = CustomerContent;
        }
        field(95126; "DropBox Token Expiration"; DateTime)
        {
            Caption = 'DropBox Token Expiration';
            DataClassification = CustomerContent;
        }
        field(95127; "DropBox Root Folder"; Text[250])
        {
            Caption = 'DropBox Root Folder';
            DataClassification = CustomerContent;
        }
        field(95133; "Url Api DropBox"; Text[250])
        {
            Caption = 'DropBox API URL';
            DataClassification = CustomerContent;
        }

        // Campos específicos para Strapi
        field(95128; "Strapi Base URL"; Text[250])
        {
            Caption = 'Strapi Base URL';
            DataClassification = CustomerContent;
        }
        field(95129; "Strapi API Token"; Text[1024])
        {
            Caption = 'Strapi API Token';
            DataClassification = CustomerContent;
        }
        field(95130; "Strapi Username"; Text[100])
        {
            Caption = 'Strapi Username';
            DataClassification = CustomerContent;
        }
        field(95131; "Strapi Password"; Text[100])
        {
            Caption = 'Strapi Password';
            DataClassification = CustomerContent;
        }
        field(95132; "Strapi Collection Name"; Text[100])
        {
            Caption = 'Strapi Collection Name';
            DataClassification = CustomerContent;
        }
        field(95136; "Code Ondrive"; Text[1024])
        {

        }
    }

    procedure GetTokenGoogleDrive(): Text
    begin
        exit("Token GoogleDrive");
    end;

    procedure SetTokenGoogleDrive(NewToken: Text)
    begin
        "Token GoogleDrive" := NewToken;
    end;

    procedure GetRefreshTokenGoogleDrive(): Text
    begin
        exit("Refresh Token GoogleDrive");
    end;

    procedure GetTokenOndrive(): Text
    begin

    end;

}