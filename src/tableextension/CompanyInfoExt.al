tableextension 95101 "Company Info Ext" extends "Company Information"
{
    fields
    {
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
}