/// <summary>
/// Page PDF Viewer Part (ID 50012).
/// </summary>
page 95123 "PDF Viewer Part Google Drive" //extends "PDF Viewer Part"

{

    Caption = 'PDF Documents';
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
                        if URL <> '' then
                            SetPDFDocumentUrl(URL, 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF))
                        else
                            SetPDFDocument(GetPDFAsTxt(PDFStoraget), 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF));
                    end;

                    trigger onView()
                    begin
                        RunFullView(PDFStoraget);
                    end;

                    trigger OnSiguiente()
                    begin
                        a += 1;
                        if pdfstoraget.next() = 0 then begin
                            If Not pdfstoraget.findlast() then exit;
                            a := PDFStoraget.Count;
                        end;
                        if PDFStorageT.Url <> '' then
                            SetPDFDocumentUrl(PDFStorageT.Url, 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF))
                        else
                            SetPDFDocument(GetPDFAsTxt(PDFStoraget), 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF));

                    end;

                    trigger OnAnterior()
                    begin
                        a -= 1;
                        if pdfstoraget.Next(-1) = 0 then begin
                            pdfstoraget.findfirst();
                            a := 1;
                        end;
                        if PDFStorageT.Url <> '' then
                            SetPDFDocumentUrl(PDFStorageT.Url, 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF))
                        else
                            SetPDFDocument(GetPDFAsTxt(PDFStoraget), 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF));

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
                    begin
                        if PDFStoraget."Google Drive ID" <> '' then begin
                            TempBlob.CreateOutStream(DocumentStream);
                            Base64 := PDFStoraget.ToBase64StringOcr(PDFStoraget."Google Drive ID");
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

    local procedure SetPDFDocument(PDFAsTxt: Text; i: Integer; Pdf: Boolean);
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
                    else
                        CurrPage.PDFViewer1.LoadOtros(PDFAsTxt, true);
                    CurrPage.PDFViewer1.Fichero(a);
                    CurrPage.PDFViewer1.Ficheros(PDFStoraget.Count);
                end;

        end;

    end;

    local procedure SetPDFDocumentUrl(PDFAsTxt: Text; i: Integer; Pdf: Boolean);
    var
        IsVisible: Boolean;
    begin
        PDFAsTxt := PDFStorageT.ToBase64StringOcr(PDFAsTxt);

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
                    else
                        CurrPage.PDFViewer1.LoadOtros(PDFAsTxt, true);
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
        DocTypeD: Enum "Purchase Document Type";
        PDFStorage: Record "Document Attachment";
        FileList: Record "Name/Value Buffer" temporary;
        Instream: InStream;
    begin
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
        GoogleDriveManager.GetFolderMapping(gSourceRecordId.TableNo, Id);
        PDFStorage.SetRange("Table ID", gSourceRecordId.TableNo);
        Case gSourceRecordId.TableNo of
            18, 23, 27, 167, 156, 5600:
                begin

                    PDFStorage.SetRange("No.", RecRef.Field(1).Value);
                    SubFolder := FolderMapping.CreateSubfolderPath(gSourceRecordId.TableNo, RecRef.Field(1).Value, 0D);
                end;
            36:
                begin
                    DocTypeS := RecRef.Field(1).Value;
                    // if DocTypeS = DocTypeS::Order Then begin
                    //     Ticket := Alfresco.Token();
                    //     rInf.Get;
                    //     UrlAlfresco := '?&alf_ticket=' + Ticket;
                    //     Node := RecRef.Field(Contrato.FieldNo(nodeRef)).Value;
                    //     Url := rInf."Servidor Alfresco" + Nodes + '/'
                    //     + Node + '/content' + UrlAlfresco;
                    //     PDFStorage.Id := 0;
                    //     PDFStorage."Grupos Usuario" := Url;
                    //     PDFStorage."File Name" := 'URL';
                    //     MostrarPrimero := true;
                    //     If PDFStorage.Insert Then;
                    // end;
                    PDFStorage.SetRange("No.", RecRef.Field(3).Value);
                    SubFolder := FolderMapping.CreateSubfolderPath(gSourceRecordId.TableNo, RecRef.Field(3).Value, RecRef.Field(20).Value);
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
                    SubFolder := FolderMapping.CreateSubfolderPath(gSourceRecordId.TableNo, RecRef.Field(3).Value, RecRef.Field(20).Value);
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
            112:
                begin
                    PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::Invoice);
                    SubFolder := FolderMapping.CreateSubfolderPath(gSourceRecordId.TableNo, RecRef.Field(3).Value, RecRef.Field(20).Value);
                end;
            114:
                begin
                    PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::"Credit Memo");
                    SubFolder := FolderMapping.CreateSubfolderPath(gSourceRecordId.TableNo, RecRef.Field(3).Value, RecRef.Field(20).Value);
                end;
            122:
                begin
                    PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::Invoice);
                    SubFolder := FolderMapping.CreateSubfolderPath(gSourceRecordId.TableNo, RecRef.Field(3).Value, RecRef.Field(20).Value);
                end;
            144:
                begin
                    PDFStorage.SetRange("Document Type", PDFStorage."Document Type"::"Credit Memo");
                    SubFolder := FolderMapping.CreateSubfolderPath(gSourceRecordId.TableNo, RecRef.Field(3).Value, RecRef.Field(20).Value);
                end;
            1173:
                begin
                    PDFStorage.SetRange(ID, RecRef.Field(PDFStorage.FieldNo("ID")).Value);
                    PDFStorage.SetRange("Table ID", RecRef.Field(PDFStorage.FieldNo("Table ID")).Value);
                    PDFStorage.SetRange("No.", RecRef.Field(PDFStorage.FieldNo("No.")).Value);
                    PDFStorage.SetRange("Line No.", RecRef.Field(PDFStorage.FieldNo("Line No.")).Value);
                    PDFStorage.SetRange("Document Type", RecRef.Field(PDFStorage.FieldNo("Document Type")).Value);
                    SubFolder := FolderMapping.CreateSubfolderPath(RecRef.Field(PDFStorage.FieldNo("Table ID")).Value, RecRef.Field(PDFStorage.FieldNo("No.")).Value, RecRef.Field(PDFStorage.FieldNo("Line No.")).Value);
                end;



        end;
        //
        IF SubFolder <> '' then
            Id := GoogleDriveManager.CreateFolderStructure(Id, SubFolder);

        GoogleDriveManager.ListFolder(Id, FileList, true);
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
            18, 23, 27, 156, 167, 5600:
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
            112, 114, 122, 144:
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
                    SetPDFDocument(GetPDFAsTxt(PDFStoraget), 1, (PDFStorageT."File Type" = PDFStorageT."File Type"::PDF));
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
        Int: InStream;
    begin
        if PDFStorage."Google Drive ID" <> '' then
            PDFViewerCard.LoadPdfFromBlob(PDFStorage.ToBase64StringOcr(PDFStorage."Google Drive ID"))
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
