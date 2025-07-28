/// <summary>
/// Page PDF Viewer Part (ID 50012).
/// </summary>
page 95123 "PDF Viewer Part Google Drive" //extends "PDF Viewer Part"

{

    Caption = 'Visor Documents';
    PageType = CardPart;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            group(Group1)
            {
                ShowCaption = false;
                Visible = VisibleControl1;
                usercontrol(PDFViewer1; "PDFV PDF Viewer")
                {
                    ApplicationArea = All;

                    trigger ControlAddinReady()
                    var
                        URL: Text;

                    begin
                        IsControlAddInReady := true;
                        URL := PDFStorageT."Google Drive ID";
                        if URL <> '' then begin
                            SetPDFDocumentUrl(URL, 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF))
                        end
                        else
                            SetPDFDocument(GetPDFAsTxt(PDFStoraget), 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF), '', '');
                    end;

                    trigger onView()
                    begin
                        RunFullView(PDFStoraget);
                    end;

                    trigger OnSiguiente()
                    var
                        UrlProvider: Text;
                        GoogleDriveManager: Codeunit "Google Drive Manager";
                        Url: Text;
                    begin
                        a += 1;
                        if pdfstoraget.next() = 0 then begin
                            If Not pdfstoraget.findlast() then exit;
                            a := PDFStoraget.Count;
                        end;
                        if PDFStorageT."Google Drive ID" <> '' then
                            SetPDFDocumentUrl(PDFStorageT."Google Drive ID", 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF))
                        else
                            SetPDFDocument(GetPDFAsTxt(PDFStoraget), 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF), '', '');

                    end;

                    trigger OnAnterior()
                    begin
                        a -= 1;
                        if pdfstoraget.Next(-1) = 0 then begin
                            pdfstoraget.findfirst();
                            a := 1;
                        end;
                        if PDFStorageT."Google Drive ID" <> '' then
                            SetPDFDocumentUrl(PDFStorageT."Google Drive ID", 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF))
                        else
                            SetPDFDocument(GetPDFAsTxt(PDFStoraget), 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF), '', '');

                    end;

                    trigger OnDownload()
                    var
                        PDFViewerCard: Page "PDF Viewer";
                        tempblob: Codeunit "Temp Blob";
                        DocumentStream: OutStream;
                        Base64Convert: Codeunit "Base64 Convert";
                        Int: InStream;
                        DocumentInStream: Instream;
                        FileName: Text;
                        Base64: Text;
                        FileManagement: Codeunit "File Management";
                        StorageProvider: Enum "Data Storage Provider";
                        URL: Text;
                    begin
                        iF PDFStorageT."Google Drive ID" <> '' then begin
                            URL := PDFStoraget."Google Drive ID";
                            StorageProvider := StorageProvider::"Google Drive";
                        end;
                        if PDFStoraget."Store in OneDrive" then begin
                            URL := PDFStoraget."OneDrive ID";
                            StorageProvider := StorageProvider::OneDrive;
                        end;
                        if PDFStoraget."Store in DropBox" then begin
                            URL := PDFStoraget."DropBox ID";
                            StorageProvider := StorageProvider::DropBox;
                        end;
                        if PDFStoraget."Store in Strapi" then begin
                            URL := PDFStoraget."Strapi ID";
                            StorageProvider := StorageProvider::Strapi;
                        end;
                        if URL <> '' then begin
                            TempBlob.CreateOutStream(DocumentStream);
                            If Not PDFStoraget.ToBase64StringOcr(URL, Base64, PDFStorageT."File Name", StorageProvider) then
                                exit;
                            Base64Convert.FromBase64(Base64, DocumentStream);
                            FileManagement.BLOBExport(TempBlob, PDFStorageT."File Name" + '.' + PDFStorageT."File Extension", true);
                        end;
                        if PDFStoraget.IsEmpty() then
                            exit;
                        TempBlob.CreateOutStream(DocumentStream);
                        PDFStoraget.Export(true);


                    end;
                }
            }

        }
    }
    trigger OnOpenPage()
    begin
        a := 1;
        SetRecord();

    end;

    local procedure GetPDFAsTxt(PDFStorage: Record "Document Attachment"): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        Int: InStream;
        DocumentStream: OutStream;
    begin
        TempBlob.CreateOutStream(DocumentStream);
        PDFStorage."Document Reference ID".ExportStream(DocumentStream);
        TempBlob.CreateInStream(Int);


        exit(Base64Convert.ToBase64(Int));
    end;

    local procedure SetPDFDocument(PDFAsTxt: Text; i: Integer; Pdf: Boolean; Url: Text; driveType: Text);
    var
        IsVisible: Boolean;
    begin
        IsVisible := PDFAsTxt <> '';
        case i of
            1:
                begin
                    VisibleControl1 := IsVisible;
                    if not IsVisible or not IsControlAddInReady then
                        exit;
                    CurrPage.PDFViewer1.SetVisible(IsVisible);
                    If Pdf then
                        CurrPage.PDFViewer1.LoadPDF(PDFAsTxt, true)
                    else begin
                        case PDFStorageT."File Type" of
                            PDFStorageT."File Type"::PDF:
                                CurrPage.PDFViewer1.LoadOtros(PDFAsTxt, true, 'pdf', Url, driveType);
                            PDFStorageT."File Type"::Image:
                                CurrPage.PDFViewer1.LoadOtros(PDFAsTxt, true, 'image', Url, driveType);
                            PDFStorageT."File Type"::Word:
                                CurrPage.PDFViewer1.LoadOtros(PDFAsTxt, true, 'word', Url, driveType);
                            PDFStorageT."File Type"::Excel:
                                CurrPage.PDFViewer1.LoadOtros(PDFAsTxt, true, 'excel', Url, driveType);
                            PDFStorageT."File Type"::PowerPoint:
                                CurrPage.PDFViewer1.LoadOtros(PDFAsTxt, true, 'powerpoint', Url, driveType);
                        end;
                    end;
                    CurrPage.PDFViewer1.Fichero(a);
                    CurrPage.PDFViewer1.Ficheros(PDFStoraget.Count);
                end;

        end;

    end;

    local procedure SetPDFDocumentUrl(PDFAsTxt: Text; i: Integer; Pdf: Boolean);
    var
        IsVisible: Boolean;
        Base64: Text;
        StorageProvider: Enum "Data Storage Provider";
        UrlProvider: Text;
        URL: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
        DriveType: Text;
    begin
        if PDFStorageT."Store in Google Drive" then begin
            StorageProvider := StorageProvider::"Google Drive";
            UrlProvider := GoogleDriveManager.GetUrl(URL);
            DriveType := 'google';
        end;
        if PDFStorageT."Store in OneDrive" then begin
            StorageProvider := StorageProvider::OneDrive;
            UrlProvider := OneDriveManager.GetUrl(URL);
            DriveType := 'onedrive';
        end;
        if PDFStorageT."Store in DropBox" then begin
            StorageProvider := StorageProvider::DropBox;
            UrlProvider := DropBoxManager.GetUrl(URL);
            DriveType := 'dropbox';
        end;
        if PDFStorageT."Store in Strapi" then begin
            StorageProvider := StorageProvider::Strapi;
            UrlProvider := StrapiManager.GetUrl(URL);
            DriveType := 'strapi';
        end;
        UrlProvider := URL;
        If Not PDFStorageT.ToBase64StringOcr(PDFAsTxt, Base64, PDFStorageT."File Name", StorageProvider) then
            exit;

        IsVisible := Base64 <> '';
        case i of
            1:
                begin
                    VisibleControl1 := IsVisible;
                    if not IsVisible or not IsControlAddInReady then
                        exit;
                    CurrPage.PDFViewer1.SetVisible(IsVisible);
                    If Pdf then
                        CurrPage.PDFViewer1.LoadPDF(Base64, true)
                    else begin
                        case PDFStorageT."File Type" of
                            PDFStorageT."File Type"::PDF:
                                CurrPage.PDFViewer1.LoadOtros(Base64, true, 'pdf', DriveType, UrlProvider);
                            PDFStorageT."File Type"::Image:
                                CurrPage.PDFViewer1.LoadOtros(Base64, true, 'image', DriveType, UrlProvider);
                            PDFStorageT."File Type"::Word:
                                CurrPage.PDFViewer1.LoadOtros(Base64, true, 'word', DriveType, UrlProvider);
                            PDFStorageT."File Type"::Excel:
                                CurrPage.PDFViewer1.LoadOtros(Base64, true, 'excel', DriveType, UrlProvider);
                            PDFStorageT."File Type"::PowerPoint:
                                CurrPage.PDFViewer1.LoadOtros(Base64, true, 'powerpoint', DriveType, UrlProvider);
                            PDFStorageT."File Type"::XML:
                                CurrPage.PDFViewer1.LoadOtros(Base64, true, 'xml', DriveType, UrlProvider);
                        end;
                    end;
                    CurrPage.PDFViewer1.Fichero(a);
                    CurrPage.PDFViewer1.Ficheros(PDFStoraget.Count);


                end;
        end;
    end;

    local procedure SetRecord()
    var

        HandleErr: Boolean;
        i: Integer;
        RecRef: RecordRef;
        DocTypeS: Enum "Sales Document Type";
        FolderMapping: Record "Google Drive Folder Mapping";
        GoogleDriveManager: Codeunit "Google Drive Manager";
        Id: Text;
        SubFolder: Text;
        Path: Text;
        DocTypeD: Enum "Purchase Document Type";
        PDFStorage: Record "Document Attachment";
        FileList: Record "Name/Value Buffer" temporary;
        Instream: InStream;
        CompaniInfo: Record "Company Information";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";

    begin
        CompaniInfo.Get();
        //Clear(PDFStorageArray);
        Clear(VisibleControl1);
        Clear(VisibleControl2);
        Clear(VisibleControl3);
        Clear(VisibleControl4);
        Clear(VisibleControl5);
        //PDFStorage.SetRange("Source Record ID", gSourceRecordId);
        //
        if gSourceRecordId.TableNo = 0 Then begin
            VisibleControl1 := false;
            exit;
        end;
        If Not RecRef.Get(gSourceRecordId) then begin
            VisibleControl1 := false;
            exit;
        end;
        case CompaniInfo."Data Storage Provider" of
            CompaniInfo."Data Storage Provider"::"Google Drive":
                GoogleDriveManager.GetFolderMapping(gSourceRecordId.TableNo, Id);
            CompaniInfo."Data Storage Provider"::OneDrive:
                OneDriveManager.GetFolderMapping(gSourceRecordId.TableNo, Id);
            CompaniInfo."Data Storage Provider"::DropBox:
                DropBoxManager.GetFolderMapping(gSourceRecordId.TableNo, Id);
            CompaniInfo."Data Storage Provider"::Strapi:
                StrapiManager.GetFolderMapping(gSourceRecordId.TableNo, Id);
        end;
        PDFStorage.SetRange("Table ID", gSourceRecordId.TableNo);
        Case gSourceRecordId.TableNo of
            Database::Customer, Database::Vendor, Database::Item, Database::"Bank Account", Database::"G/L Account", Database::"Fixed Asset", Database::Employee, Database::Job, Database::Resource:
                begin

                    PDFStorage.SetRange("No.", RecRef.Field(1).Value);
                    SubFolder := ObtenerSubfolder(gSourceRecordId.TableNo, RecRef.Field(1).Value, 0D, SubFolder, Path);
                end;
            36:
                begin
                    DocTypeS := RecRef.Field(1).Value;
                    PDFStorage.SetRange("No.", RecRef.Field(3).Value);
                    SubFolder := ObtenerSubfolder(gSourceRecordId.TableNo, RecRef.Field(3).Value, RecRef.Field(20).Value, SubFolder, Path);
                    Case DocTypeS of
                        DocTypeS::"Blanket Order":
                            PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::"Blanket Order");
                        DocTypeS::"Credit Memo":
                            PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::"Credit Memo");
                        DocTypeS::Order:
                            PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::Order);
                        DocTypeS::Quote:
                            PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::Quote);
                        DocTypeS::Invoice:
                            PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::Invoice);
                        DocTypeS::"Return Order":
                            PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::"Return Order");
                    End;
                end;
            38:
                begin
                    PDFStorage.SetRange("No.", RecRef.Field(3).Value);
                    SubFolder := ObtenerSubfolder(gSourceRecordId.TableNo, RecRef.Field(3).Value, RecRef.Field(20).Value, SubFolder, Path);
                    DocTyped := RecRef.Field(1).Value;
                    Case DocTyped of
                        DocTyped::"Blanket Order":
                            PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::"Blanket Order");
                        DocTyped::"Credit Memo":
                            PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::"Credit Memo");
                        DocTyped::Order:
                            PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::Order);
                        DocTyped::Quote:
                            PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::Quote);
                        DocTyped::Invoice:
                            PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::Invoice);
                        DocTyped::"Return Order":
                            PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::"Return Order");
                    End;
                end;
            110, 112, 114, 120, 122, 124:
                begin
                    PDFStorage.SetRange("No.", RecRef.Field(3).Value);
                    SubFolder := ObtenerSubfolder(gSourceRecordId.TableNo, RecRef.Field(3).Value, RecRef.Field(20).Value, SubFolder, Path);
                end;
            // 112:
            //     begin
            //         PDFStorage.SetRange("No.", RecRef.Field(3).Value);
            //         SubFolder := ObtenerSubfolder(gSourceRecordId.TableNo, RecRef.Field(3).Value, RecRef.Field(20).Value, SubFolder, Path);
            //     end;
            // 114:
            //     begin
            //         PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::"Credit Memo");
            //         SubFolder := ObtenerSubfolder(gSourceRecordId.TableNo, RecRef.Field(3).Value, RecRef.Field(20).Value, SubFolder, Path);
            //     end;
            // 122:
            //     begin
            //         PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::Invoice);
            //         SubFolder := ObtenerSubfolder(gSourceRecordId.TableNo, RecRef.Field(3).Value, RecRef.Field(20).Value, SubFolder, Path);
            //     end;
            // 144:
            //     begin
            //         PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::"Credit Memo");
            //         SubFolder := ObtenerSubfolder(gSourceRecordId.TableNo, RecRef.Field(3).Value, RecRef.Field(20).Value, SubFolder, Path);
            //     end;
            1173:
                begin
                    PDFStorage.SetRange(ID, RecRef.Field(PDFStorage.FieldNo("ID")).Value);
                    PDFStorage.SetRange("Table ID", RecRef.Field(PDFStorage.FieldNo("Table ID")).Value);
                    PDFStorage.SetRange("No.", RecRef.Field(PDFStorage.FieldNo("No.")).Value);
                    PDFStorage.SetRange("Line No.", RecRef.Field(PDFStorage.FieldNo("Line No.")).Value);
                    PDFStorage.SetRange("Document Type", RecRef.Field(PDFStorage.FieldNo("Document Type")).Value);
                    SubFolder := ObtenerSubfolder(RecRef.Field(PDFStorage.FieldNo("Table ID")).Value, RecRef.Field(PDFStorage.FieldNo("No.")).Value, RecRef.Field(PDFStorage.FieldNo("Line No.")).Value, SubFolder, Path);
                end;



        end;
        //
        IF SubFolder <> '' then begin
            case CompaniInfo."Data Storage Provider" of
                CompaniInfo."Data Storage Provider"::"Google Drive":
                    begin
                        Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);
                        GoogleDriveManager.ListFolder(Id, FileList, true);
                    end;
                CompaniInfo."Data Storage Provider"::OneDrive:
                    begin
                        IF SubFolder <> '' then begin
                            Id := OneDriveManager.CreateFolderStructure(Id, SubFolder);
                            Path += SubFolder + '/'
                        end;
                        OneDriveManager.ListFolder(Id, FileList, true);

                    end;
                CompaniInfo."Data Storage Provider"::DropBox:
                    begin
                        Id := DropBoxManager.CreateSubfolderStructure(Id, SubFolder);
                        DropBoxManager.ListFolder(Id, FileList, true);
                    end;
                CompaniInfo."Data Storage Provider"::Strapi:
                    begin
                        Id := StrapiManager.CreateSubfolderStructure(Id, SubFolder);
                        StrapiManager.ListFolder(Id, FileList, true);
                    end;
            end;
        end;


        FileList.SetFilter("Name", '*.pdf');
        VisibleControl1 := false;
        if PDFStorage.FindSet() then VisibleControl1 := true;
        PDFStorageT.DeleteAll();
        repeat
            PDFStorageT := PDFStorage;
            If PDFStorageT.Insert() Then;
        until (PDFStorage.Next() = 0);
        a := 0;
        If PDFStorageT.FindLast() then a := PDFStorageT.id;
        Case gSourceRecordId.TableNo of
            36, 38:
                Begin
                    if FileList.FindFirst() then
                        repeat
                            PDFStorageT.init;
                            a += 1;
                            PDFStorageT.id := a;
                            PDFStorageT."Table ID" := gSourceRecordId.TableNo;
                            PDFStorageT."No." := RecRef.Field(3).Value;
                            PDFStorageT."Document Type" := RecRef.Field(1).Value;
                            PDFStorageT."Google Drive ID" := FileList."Google Drive ID";
                            PDFStorageT."File Type" := PDFStorageT."File Type"::PDF;
                            PDFStorageT."File Name" := FileList."Name";
                            PDFStorageT."Store in Google Drive" := True;
                            VisibleControl1 := true;
                            If PDFStorageT.Insert() Then;

                        until FileList.Next() = 0;
                end;
            Database::Customer, Database::Vendor, Database::Item, Database::"Bank Account", Database::"G/L Account", Database::"Fixed Asset", Database::Employee, Database::Job, Database::Resource:
                begin
                    if FileList.FindFirst() then
                        repeat
                            PDFStorageT.init;
                            a += 1;
                            PDFStorageT.id := a;
                            PDFStorageT."Table ID" := gSourceRecordId.TableNo;
                            PDFStorageT."No." := RecRef.Field(1).Value;
                            PDFStorageT."Google Drive ID" := FileList."Google Drive ID";
                            PDFStorageT."File Type" := PDFStorageT."File Type"::PDF;
                            PDFStorageT."File Name" := FileList."Name";
                            PDFStorageT."Store in Google Drive" := True;
                            VisibleControl1 := true;
                            If PDFStorageT.Insert() Then;
                        until FileList.Next() = 0;
                end;
            110, 112, 114, 120, 122, 124:
                begin
                    if FileList.FindFirst() then
                        repeat
                            PDFStorageT.init;
                            a += 1;
                            PDFStorageT.id := a;
                            PDFStorageT."Table ID" := gSourceRecordId.TableNo;
                            PDFStorageT."No." := RecRef.Field(3).Value;
                            PDFStorageT."Google Drive ID" := FileList."Google Drive ID";
                            PDFStorageT."File Type" := PDFStorageT."File Type"::PDF;
                            PDFStorageT."File Name" := FileList."Name";
                            PDFStorageT."Store in Google Drive" := True;
                            VisibleControl1 := true;
                            If PDFStorageT.Insert() Then;
                        until FileList.Next() = 0;
                end;
        end;
        commit;
        PDFStorageT.SetRange("File Type", PDFStorageT."File Type"::PDF);
        if PDFStorageT.FindFirst() then
            if IsControlAddInReady then
                if PDFStorageT.Url <> '' then
                    SetPDFDocumentUrl(PDFStorageT.Url, 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF))
                else
                    SetPDFDocument(GetPDFAsTxt(PDFStoraget), 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF), '', '');
        // SetPDFDocument(GetPDFAsTxt(PDFStorageArray[1]), 1);
        // SetPDFDocument(GetPDFAsTxt(PDFStorageArray[2]), 2);
        // SetPDFDocument(GetPDFAsTxt(PDFStorageArray[3]), 3);
        // SetPDFDocument(GetPDFAsTxt(PDFStorageArray[4]), 4);
        // SetPDFDocument(GetPDFAsTxt(PDFStorageArray[5]), 5);
    end;

    /// <summary>
    /// SetRecord.
    /// </summary>
    /// <param name="SourceRecordID">RecordId.</param>
    procedure SetRecord(SourceRecordID: RecordId)
    begin
        gSourceRecordId := SourceRecordID;
        SetRecord();
        CurrPage.Update(false);
    end;



    local procedure RunFullView(PDFStorage: Record "Document Attachment")
    var
        PDFViewerCard: Page "PDF Viewer";
        tempblob: Codeunit "Temp Blob";
        DocumentStream: OutStream;
        Base64Convert: Codeunit "Base64 Convert";
        Base64: Text;
        Int: InStream;
        StorageProvider: Enum "Data Storage Provider";
        URL: Text;
    begin
        if PDFStorage."Google Drive iD" <> '' then begin
            URL := PDFStorage."Google Drive ID";
            StorageProvider := StorageProvider::"Google Drive";
        end;
        if PDFStorage."Store in OneDrive" then begin
            URL := PDFStorage."OneDrive ID";
            StorageProvider := StorageProvider::OneDrive;
        end;
        if PDFStorage."Store in DropBox" then begin
            URL := PDFStorage."DropBox ID";
            StorageProvider := StorageProvider::DropBox;
        end;
        if PDFStorage."Store in Strapi" then begin
            URL := PDFStorage."Strapi ID";
            StorageProvider := StorageProvider::Strapi;
        end;
        if URL <> '' then begin
            If Not PDFStorage.ToBase64StringOcr(URL, Base64, PDFStorage."File Name", StorageProvider) then
                exit;
            PDFViewerCard.LoadPdfFromBlob(Base64);
        end
        else begin
            if PDFStorage.IsEmpty() then
                exit;

            TempBlob.CreateOutStream(DocumentStream);
            PDFStorage."Document Reference ID".ExportStream(DocumentStream);
            TempBlob.CreateInStream(Int);
            PDFViewerCard.LoadPdfFromBlob(Base64Convert.ToBase64(Int));
        end;
        PDFViewerCard.Run();

    end;

    local procedure ObtenerSubfolder(TableNo: Integer; Value: Variant; Date: Date; var SubFolder: Text; var Path: Text): Text
    var
        FolderMapping: Record "Google Drive Folder Mapping";
        CompanyInfo: Record "Company Information";
        Id: Text;
        GoogleDriveManager: Codeunit "Google Drive Manager";
        OneDriveManager: Codeunit "OneDrive Manager";
        DropBoxManager: Codeunit "DropBox Manager";
        StrapiManager: Codeunit "Strapi Manager";
    begin
        CompanyInfo.Get();
        case CompanyInfo."Data Storage Provider" of
            CompanyInfo."Data Storage Provider"::"Google Drive":
                SubFolder := FolderMapping.CreateSubfolderPath(TableNo, Value, Date, CompanyInfo."Data Storage Provider");
            CompanyInfo."Data Storage Provider"::OneDrive:
                begin
                    SubFolder := OneDriveManager.CreateFolderStructure(Id, SubFolder);
                    FolderMapping.SetRange("Table ID", TableNo);
                    if FolderMapping.FindFirst() Then Path += FolderMapping."Default Folder Name" + '/';
                    SubFolder := FolderMapping.CreateSubfolderPath(TableNo, Value, Date, CompanyInfo."Data Storage Provider");
                end;
            CompanyInfo."Data Storage Provider"::DropBox:
                SubFolder := FolderMapping.CreateSubfolderPath(TableNo, Value, Date, CompanyInfo."Data Storage Provider");
            CompanyInfo."Data Storage Provider"::Strapi:
                SubFolder := FolderMapping.CreateSubfolderPath(TableNo, Value, Date, CompanyInfo."Data Storage Provider");

        end;
        exit(SubFolder);
    end;

    var
        //PDFStorageArray: array[5] of Record "Document Attachment";
        gSourceRecordId: RecordId;

        VisibleControl1: Boolean;

        VisibleControl2: Boolean;

        VisibleControl3: Boolean;

        VisibleControl4: Boolean;

        VisibleControl5: Boolean;
        PDFStorageT: Record "Document Attachment" temporary;

        IsControlAddInReady: Boolean;
        l: Integer;
        a: Integer;
}
