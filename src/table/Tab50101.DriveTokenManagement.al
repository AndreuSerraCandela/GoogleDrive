table 95101 "Drive Token Management"
{
    Caption = 'Drive Token Management';
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Storage Provider"; Enum "Data Storage Provider")
        {
            Caption = 'Storage Provider';
            DataClassification = CustomerContent;
        }

        field(3; "Access Token"; Blob)
        {
            Caption = 'Access Token';
            DataClassification = CustomerContent;
        }

        field(4; "Refresh Token"; Blob)
        {
            Caption = 'Refresh Token';
            DataClassification = CustomerContent;
        }

        field(5; "Token Expiration"; DateTime)
        {
            Caption = 'Token Expiration';
            DataClassification = CustomerContent;
        }



        field(16; "Last Token Refresh"; DateTime)
        {
            Caption = 'Last Token Refresh';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(17; "Token Status"; Enum "Token Status")
        {
            Caption = 'Token Status';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Storage Provider")
        {
            Clustered = true;
        }


    }

    trigger OnInsert()
    begin
        "Token Status" := "Token Status"::Unknown;
    end;

    trigger OnModify()
    begin
        "Last Token Refresh" := CurrentDateTime;
    end;

    procedure SetAccessToken(TokenText: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Access Token");
        "Access Token".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(TokenText);
        "Last Token Refresh" := CurrentDateTime;
        "Token Status" := "Token Status"::Valid;
        Modify();
    end;

    procedure GetAccessToken(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Access Token");
        "Access Token".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("Access Token")));
    end;

    procedure SetRefreshToken(TokenText: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Refresh Token");
        "Refresh Token".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(TokenText);
        Modify();
    end;

    procedure GetRefreshToken(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Refresh Token");
        "Refresh Token".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("Refresh Token")));
    end;

    procedure IsTokenExpired(): Boolean
    begin
        if "Token Expiration" = 0DT then
            exit(true);
        exit("Token Expiration" < CurrentDateTime);
    end;

    procedure GetTokenExpirationTime(): DateTime
    begin
        exit("Token Expiration");
    end;

    procedure SetTokenExpiration(ExpirationDateTime: DateTime)
    begin
        "Token Expiration" := ExpirationDateTime;
        if "Token Expiration" < CurrentDateTime then
            "Token Status" := "Token Status"::Expired
        else
            "Token Status" := "Token Status"::Valid;
        Modify();
    end;
}