codeunit 95104 "Strapi Manager"
{
    var
        CompanyInfo: Record "Company Information";

    procedure Initialize()
    begin
        CompanyInfo.Get();
    end;

    procedure Authenticate(): Boolean
    var
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Json: Text;
        Body: JsonObject;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JToken: JsonToken;
        Token: Text;
    begin
        // Para Strapi, la autenticación se hace con el API Token
        if CompanyInfo."Strapi API Token" = '' then
            exit(false);

        // Verificar que el token es válido haciendo una llamada de prueba
        Url := CompanyInfo."Strapi Base URL" + '/api/users/me';

        Respuesta := RestApiToken(Url, CompanyInfo."Strapi API Token", RequestType::get, '');

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('id', JToken) then
                exit(true);
        end;

        exit(false);
    end;

    procedure ValidateConfiguration(): Boolean
    begin
        if CompanyInfo."Strapi Base URL" = '' then
            exit(false);
        if CompanyInfo."Strapi API Token" = '' then
            exit(false);
        if CompanyInfo."Strapi Collection Name" = '' then
            exit(false);

        exit(true);
    end;

    procedure TestAPI()
    var
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
    begin
        if not ValidateConfiguration() then
            Error('Configuración incompleta. Verifique que todos los campos estén llenos.');

        Url := CompanyInfo."Strapi Base URL" + '/api/users/me';
        Respuesta := RestApiToken(Url, CompanyInfo."Strapi API Token", RequestType::get, '');

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            Message('✅ Conexión exitosa con Strapi API.\Respuesta: %1', Respuesta);
        end else begin
            Message('❌ Error en la conexión con Strapi API.');
        end;
    end;

    procedure GetUrl(DocumentID: Text): Text
    var
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        FileUrl: Text;
    begin
        if DocumentID = '' then
            exit('');

        // Obtener la URL del archivo desde Strapi
        Url := CompanyInfo."Strapi Base URL" + '/api/' + CompanyInfo."Strapi Collection Name" + '/' + DocumentID;

        Respuesta := RestApiToken(Url, CompanyInfo."Strapi API Token", RequestType::get, '');

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('data', JToken) then begin
                StatusInfo := JToken.AsObject();
                if StatusInfo.Get('attributes', JToken) then begin
                    StatusInfo := JToken.AsObject();
                    if StatusInfo.Get('url', JToken) then begin
                        FileUrl := JToken.AsValue().AsText();
                        if CopyStr(FileUrl, 1, 1) = '/' then
                            FileUrl := CompanyInfo."Strapi Base URL" + FileUrl;
                        exit(FileUrl);
                    end;
                end;
            end;
        end;

        exit('');
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
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        Id: Text;
        FormData: Text;
        Boundary: Text;
    begin
        // Para Strapi, necesitamos usar form-data para subir archivos
        Boundary := '----WebKitFormBoundary' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hour24,2><Minute,2><Second,2>');

        Url := CompanyInfo."Strapi Base URL" + '/api/upload';

        // Crear form-data con el archivo
        FormData := '--' + Boundary + '\' +
                   'Content-Disposition: form-data; name="files"; filename="' + Filename + '"\' +
                   'Content-Type: application/octet-stream\' +
                   '\' +
                   '--' + Boundary + '--';

        Respuesta := RestApiFormData(Url, CompanyInfo."Strapi API Token", FormData, Base64Data, Boundary);

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('0', JToken) then begin
                StatusInfo := JToken.AsObject();
                if StatusInfo.Get('id', JToken) then begin
                    Id := JToken.AsValue().AsText();
                end;
            end;
        end;

        if Id = '' then
            Error('Error al subir archivo a Strapi: %1', Respuesta);

        exit(Id);
    end;

    procedure DownloadFileB64(Carpeta: Text; var Base64Data: Text; Filename: Text; BajarFichero: Boolean): Text
    var
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        Id: Text;
        TempBlob: Codeunit "Temp Blob";
        Int: Instream;
        Bs64: Codeunit "Base64 Convert";
    begin
        // Obtener el ID del archivo desde Strapi
        Id := GetFileId(Filename);

        if Id = '' then
            Error('Archivo no encontrado: %1', Filename);

        // Obtener la URL del archivo
        Url := GetUrl(Id);

        if Url = '' then
            Error('No se pudo obtener la URL del archivo');

        TempBlob.CreateInStream(Int);
        RestApiGetContentStream(Url, RequestType::Get, Int);
        Base64Data := Bs64.ToBase64(Int);

        if BajarFichero then begin
            DownloadFromStream(Int, 'Guardar', 'C:\Temp', 'ALL Files (*.*)|*.*', Filename);
        end;

        exit(Base64Data);
    end;

    procedure CreateFolder(Carpeta: Text): Text
    var
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Json: Text;
        Body: JsonObject;
        StatusInfo: JsonObject;
        Respuesta: Text;
        JToken: JsonToken;
        Id: Text;
    begin
        // Para Strapi, crear una entrada en la colección que represente una carpeta
        Url := CompanyInfo."Strapi Base URL" + '/api/' + CompanyInfo."Strapi Collection Name";

        Clear(Body);
        Body.Add('data', '{}');
        Body.WriteTo(Json);

        Respuesta := RestApiToken(Url, CompanyInfo."Strapi API Token", RequestType::post, Json);

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('data', JToken) then begin
                StatusInfo := JToken.AsObject();
                if StatusInfo.Get('id', JToken) then begin
                    Id := JToken.AsValue().AsText();
                end;
            end;
        end;

        exit(Id);
    end;

    procedure DeleteFolder(Carpeta: Text; HideDialog: Boolean): Text
    var
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        Id: Text;
    begin
        if not HideDialog then
            if not Confirm('¿Está seguro de que desea eliminar la carpeta?', true) then
                exit('');

        // Obtener el ID del archivo/carpeta
        Id := GetFileId(Carpeta);

        if Id = '' then
            Error('Carpeta no encontrada: %1', Carpeta);

        Url := CompanyInfo."Strapi Base URL" + '/api/' + CompanyInfo."Strapi Collection Name" + '/' + Id;

        Respuesta := RestApiToken(Url, CompanyInfo."Strapi API Token", RequestType::delete, '');

        exit(Id);
    end;

    procedure RecuperaIdFolder(IdCarpeta: Text; Carpeta: Text; var Files: Record "Name/Value Buffer" temporary; Crear: Boolean; RootFolder: Boolean): Text
    begin
        exit('');
    end;

    local procedure GetFileId(Filename: Text): Text
    var
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        Respuesta: Text;
        StatusInfo: JsonObject;
        JToken: JsonToken;
        JArray: JsonArray;
        Id: Text;
        Filters: Text;
    begin
        // Buscar el archivo por nombre en Strapi
        Filters := '?filters[name][$eq]=' + Filename;
        Url := CompanyInfo."Strapi Base URL" + '/api/' + CompanyInfo."Strapi Collection Name" + Filters;

        Respuesta := RestApiToken(Url, CompanyInfo."Strapi API Token", RequestType::get, '');

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('data', JToken) then begin
                // Verificar si el token es un array antes de convertirlo
                if JToken.IsArray() then begin
                    JArray := JToken.AsArray();
                    if JArray.Count() > 0 then begin
                        JArray.Get(0, JToken);
                        if JToken.IsObject() then begin
                            StatusInfo := JToken.AsObject();
                            if StatusInfo.Get('id', JToken) then begin
                                Id := JToken.AsValue().AsText();
                            end;
                        end;
                    end;
                end else if JToken.IsObject() then begin
                    // Si es un objeto único (no array)
                    StatusInfo := JToken.AsObject();
                    if StatusInfo.Get('id', JToken) then begin
                        Id := JToken.AsValue().AsText();
                    end;
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

        ResponseMessage.Content().ReadAs(ResponseText);
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

    procedure RestApiFormData(url: Text; Token: Text; FormData: Text; FileData: InStream; Boundary: Text): Text
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

        RequestContent.WriteFrom(FileData);
        RequestContent.GetHeaders(contentHeaders);
        contentHeaders.Clear();
        contentHeaders.Add('Content-Type', StrSubstNo('multipart/form-data; boundary=%1', Boundary));

        Client.Post(URL, RequestContent, ResponseMessage);

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

    procedure ListFolder(FolderId: Text; var Files: Record "Name/Value Buffer" temporary; SoloSubfolder: Boolean)
    var
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
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
        ItemUrl: Text;
    begin
        Files.DeleteAll();

        // Para Strapi, listamos todos los archivos de la colección configurada
        Url := CompanyInfo."Strapi Base URL" + '/api/' + CompanyInfo."Strapi Collection Name";

        Respuesta := RestApiToken(Url, CompanyInfo."Strapi API Token", RequestType::get, '');

        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);

            if StatusInfo.Get('data', JEntryToken) then begin
                JEntries := JEntryToken.AsArray();

                foreach JEntryTokens in JEntries do begin
                    JEntry := JEntryTokens.AsObject();

                    // Obtener el ID del elemento
                    if JEntry.Get('id', JEntryToken) then
                        ItemId := JEntryToken.AsValue().AsText()
                    else
                        ItemId := '';

                    // Obtener los atributos del elemento
                    if JEntry.Get('attributes', JEntryToken) then begin
                        StatusInfo := JEntryToken.AsObject();

                        // Obtener el nombre del archivo
                        if StatusInfo.Get('name', JEntryToken) then
                            ItemName := JEntryToken.AsValue().AsText()
                        else if StatusInfo.Get('alternativeText', JEntryToken) then
                            ItemName := JEntryToken.AsValue().AsText()
                        else
                            ItemName := 'Archivo_' + ItemId;

                        // Obtener la URL del archivo
                        if StatusInfo.Get('url', JEntryToken) then begin
                            ItemUrl := JEntryToken.AsValue().AsText();
                            if CopyStr(ItemUrl, 1, 1) = '/' then
                                ItemUrl := CompanyInfo."Strapi Base URL" + ItemUrl;
                        end else
                            ItemUrl := '';

                        // Crear registro temporal
                        FilesTemp.Init();
                        a += 1;
                        FilesTemp.ID := a;
                        FilesTemp.Name := ItemName;
                        FilesTemp."Google Drive ID" := ItemId; // Reutilizamos el campo para Strapi ID
                        FilesTemp."Google Drive Parent ID" := FolderId; // Reutilizamos el campo para Parent ID
                        FilesTemp.Value := ''; // Strapi no tiene carpetas nativas, todos son archivos
                        FilesTemp."File Extension" := GetFileExtension(ItemName);

                        FilesTemp.Insert();
                    end;
                end;
            end;
        end;

        // Para Strapi, todos son archivos, no hay carpetas
        a := 0;
        if FilesTemp.FindSet() then
            repeat
                a += 1;
                Files := FilesTemp;
                Files.ID := a;
                Files.Insert();
            until FilesTemp.Next() = 0;
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



    internal procedure CreateFolderStructure(BaseFolderId: Text; FolderPath: Text): Text
    var
    // Para Strapi, como no tiene carpetas nativas, simplemente retornamos el ID base
    // ya que todos los archivos se almacenan en la misma colección
    begin
        // Strapi no tiene estructura de carpetas nativa
        // Todos los archivos se almacenan en la misma colección
        // Por lo tanto, simplemente retornamos el ID base
        exit(BaseFolderId);
    end;

    internal procedure DeleteFile(GetDocumentID: Text): Boolean
    var
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        ResponseMessage: HttpResponseMessage;
    begin
        Url := CompanyInfo."Strapi Base URL" + '/api/' + CompanyInfo."Strapi Collection Name" + '/' + GetDocumentID;
        ResponseMessage := RestApiTokenResponse(Url, CompanyInfo."Strapi API Token", RequestType::delete, '');
        if ResponseMessage.IsSuccessStatusCode() then
            exit(true)
        else
            exit(false);
    end;

    internal procedure OpenFileInBrowser(StrapiID: Text[250])
    var
        RequestType: Option Get,patch,put,post,delete;
        Url: Text;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
    begin
        Url := CompanyInfo."Strapi Base URL" + '/api/' + CompanyInfo."Strapi Collection Name" + '/' + StrapiID;
        ResponseMessage := RestApiTokenResponse(Url, CompanyInfo."Strapi API Token", RequestType::get, '');
        if ResponseMessage.IsSuccessStatusCode() then begin
            ResponseMessage.Content().ReadAs(ResponseText);
            Hyperlink(ResponseText);
        end
        else
            Error('Error al abrir el archivo en el navegador: %1', ResponseText);
    end;

    internal procedure CreateSubfolderStructure(Id: Text; SubFolder: Text): Text
    begin
        if SubFolder = '' then
            exit(Id);

        exit(FindOrCreateSubfolder(Id, SubFolder, false));
    end;

    internal procedure EditFile(StrapiID: Text[250])
    begin
        OpenFileInBrowser(StrapiID);
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

    local procedure FindOrCreateSubfolder(ParentFolderId: Text; FolderName: Text; SoloSubfolder: Boolean): Text
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
        CompanyInfo.Get();
        Ticket := CompanyInfo."Strapi API Token";
        Url := CompanyInfo."Strapi Base URL" + '/api/' + CompanyInfo."Strapi Collection Name";
        Clear(Body);
        if RootFolder then
            Body.Add('name', FolderName)
        else
            Body.Add('name', ParentFolderId + '/' + FolderName);
        Body.WriteTo(Json);
        Respuesta := RestApiToken(Url, Ticket, RequestType::post, Json);
        if Respuesta <> '' then begin
            StatusInfo.ReadFrom(Respuesta);
            if StatusInfo.Get('id', JToken) then
                exit(JToken.AsValue().AsText());
        end;
        exit('');
    end;

    procedure CreateSubfolderPath(TableID: Integer; DocumentNo: Text; DocumentDate: Date; Origen: Enum "Data Storage Provider"): Text
    var
        FolderMapping: Record "Google Drive Folder Mapping";
        SubfolderPath: Text;
        Year: Text;
        Month: Text;
    begin
        if not FolderMapping.Get(TableID) then
            exit('');

        if not FolderMapping."Auto Create Subfolders" then
            exit(FolderMapping."Default Folder ID");

        if FolderMapping."Subfolder Pattern" = '' then
            exit(FolderMapping."Default Folder ID");
        SubfolderPath := FolderMapping."Subfolder Pattern";

        // Replace patterns
        if StrPos(SubfolderPath, '{DOCNO}') > 0 then
            SubfolderPath := DocumentNo;
        if DocumentDate = 0D then
            exit(SubfolderPath);
        if StrPos(SubfolderPath, '{YEAR}') > 0 then begin
            Year := Format(Date2DMY(DocumentDate, 3));
            SubfolderPath := Year;
        end;

        if StrPos(SubfolderPath, '{MONTH}') > 0 then begin
            Month := Format(DocumentDate, 0, '<Month Text>');
            SubfolderPath := Month;
        end;

        exit(SubfolderPath);
    end;
}