table 50100 "Google Drive Folder Mapping"
{
    Caption = 'Google Drive Folder Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()
            begin
                CalcFields("Table Name");
            end;
        }

        field(2; "Table Name"; Text[100])
        {
            Caption = 'Table Name';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
            Editable = false;
        }

        field(3; "Default Folder ID"; Text[250])
        {
            Caption = 'Default Google Drive Folder ID';
            DataClassification = CustomerContent;
            ToolTip = 'Especifica el ID de la carpeta de Google Drive donde se almacenarán los archivos de esta tabla por defecto.';
        }

        field(4; "Default Folder Name"; Text[250])
        {
            Caption = 'Default Folder Name';
            DataClassification = CustomerContent;
            ToolTip = 'Especifica el nombre de la carpeta de Google Drive (solo para referencia).';
        }

        field(5; "Auto Create Subfolders"; Boolean)
        {
            Caption = 'Auto Create Subfolders';
            DataClassification = CustomerContent;
            ToolTip = 'Si está habilitado, creará automáticamente subcarpetas basadas en el número de documento.';
            InitValue = false;
        }

        field(6; "Subfolder Pattern"; Text[100])
        {
            Caption = 'Subfolder Pattern';
            DataClassification = CustomerContent;
            ToolTip = 'Patrón para crear subcarpetas. Use {DOCNO} para número de documento, {YEAR} para año, {MONTH} para mes.';
        }

        field(7; "Active"; Boolean)
        {
            Caption = 'Active';
            DataClassification = CustomerContent;
            InitValue = true;
        }

        field(8; "Description"; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Descripción opcional para esta configuración.';
        }

        field(9; "Created Date"; DateTime)
        {
            Caption = 'Created Date';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(10; "Modified Date"; DateTime)
        {
            Caption = 'Modified Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Table ID")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        "Created Date" := CurrentDateTime;
        "Modified Date" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Modified Date" := CurrentDateTime;
    end;

    procedure RecuperarIdFolder(Folder: Text): Text
    var
        GoogleDriveManager: Codeunit "Google Drive Manager";
        Files: Record "Name/Value Buffer" temporary;
        Id: Text;
    begin
        exit(GoogleDriveManager.RecuperaIdFolder(Id, Folder, Files));

    end;

    procedure GetDefaultFolderForTable(TableID: Integer): Text
    var
        FolderMapping: Record "Google Drive Folder Mapping";
    begin
        if FolderMapping.Get(TableID) and FolderMapping.Active then
            exit(FolderMapping."Default Folder ID");

        exit(''); // Return empty if no mapping found
    end;

    procedure CreateSubfolderPath(TableID: Integer; DocumentNo: Text; DocumentDate: Date): Text
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
            SubfolderPath := StrSubstNo(SubfolderPath, '{DOCNO}', DocumentNo);
        if DocumentDate = 0D then
            exit(SubfolderPath);
        if StrPos(SubfolderPath, '{YEAR}') > 0 then begin
            Year := Format(Date2DMY(DocumentDate, 3));
            SubfolderPath := StrSubstNo(SubfolderPath, '{YEAR}', Year);
        end;

        if StrPos(SubfolderPath, '{MONTH}') > 0 then begin
            Month := Format(Date2DMY(DocumentDate, 2));
            if StrLen(Month) = 1 then
                Month := '0' + Month;
            SubfolderPath := StrSubstNo(SubfolderPath, '{MONTH}', Month);
        end;

        exit(SubfolderPath);
    end;

    procedure SetupDefaultMappings()
    var
        FolderMapping: Record "Google Drive Folder Mapping";
    begin
        // Sales Invoice Header
        if not FolderMapping.Get(112) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 112;
            FolderMapping."Default Folder Name" := 'Sales Invoices';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{YEAR}/{MONTH}';
            FolderMapping.Description := 'Sales Invoice Header documents';
            FolderMapping.Insert();
        end;

        // Sales Header
        if not FolderMapping.Get(36) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 36;
            FolderMapping."Default Folder Name" := 'Sales Orders';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{YEAR}';
            FolderMapping.Description := 'Sales Header documents';
            FolderMapping.Insert();
        end;

        // Purchase Header
        if not FolderMapping.Get(38) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 38;
            FolderMapping."Default Folder Name" := 'Purchase Orders';
            FolderMapping."Auto Create Subfolders" := true;
            FolderMapping."Subfolder Pattern" := '{YEAR}';
            FolderMapping.Description := 'Purchase Header documents';
            FolderMapping.Insert();
        end;

        // Customer
        if not FolderMapping.Get(18) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 18;
            FolderMapping."Default Folder Name" := 'Customers';
            FolderMapping."Auto Create Subfolders" := false;
            FolderMapping.Description := 'Customer documents';
            FolderMapping.Insert();
        end;

        // Vendor
        if not FolderMapping.Get(23) then begin
            FolderMapping.Init();
            FolderMapping."Table ID" := 23;
            FolderMapping."Default Folder Name" := 'Vendors';
            FolderMapping."Auto Create Subfolders" := false;
            FolderMapping.Description := 'Vendor documents';
            FolderMapping.Insert();
        end;

        Message('Configuraciones por defecto creadas exitosamente.');
    end;
}