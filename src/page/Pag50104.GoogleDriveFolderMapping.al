page 95106 "Google Drive Folder Mapping"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Google Drive Folder Mapping";
    Caption = 'Drive Folder Mapping';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el ID de la tabla de Business Central.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }

                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Muestra el nombre de la tabla de Business Central.';
                }

                field("Default Folder Name"; Rec."Default Folder Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el nombre de la carpeta de Google Drive (solo para referencia).';
                }

                field("Default Folder ID"; Rec."Default Folder ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el ID de la carpeta de Google Drive donde se almacenarán los archivos.';
                    Editable = false;
                }

                field("Auto Create Subfolders"; Rec."Auto Create Subfolders")
                {
                    ApplicationArea = All;
                    ToolTip = 'Si está habilitado, creará automáticamente subcarpetas basadas en el patrón especificado.';
                }

                field("Subfolder Pattern"; Rec."Subfolder Pattern")
                {
                    ApplicationArea = All;
                    ToolTip = 'Patrón para crear subcarpetas. Use {DOCNO} para número de documento, {NO} para el Código, {YEAR} para año, {MONTH} para mes.';
                }

                field("Active"; Rec."Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica si esta configuración está activa.';
                }

                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción opcional para esta configuración.';
                }

                field("Created Date"; Rec."Created Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha y hora de creación de este registro.';
                }

                field("Modified Date"; Rec."Modified Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha y hora de última modificación de este registro.';
                }
            }
        }

        area(FactBoxes)
        {
            part(GoogleDriveFolders; "Google Drive Factbox")
            {
                ApplicationArea = All;
                Caption = 'Drive Folders';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Setup Default Mappings")
            {
                ApplicationArea = All;
                Caption = 'Configurar Mapeos por Defecto';
                ToolTip = 'Crea configuraciones por defecto para las tablas más comunes.';
                Image = Setup;

                trigger OnAction()
                begin
                    Rec.SetupDefaultMappings();
                    CurrPage.Update();
                end;
            }

            action("Browse Google Drive Folder")
            {
                ApplicationArea = All;
                Caption = 'Explorar Carpeta Google Drive';
                ToolTip = 'Abre el explorador de Google Drive para seleccionar una carpeta.';
                Image = AddToHome;
                Scope = Repeater;

                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    FolderBrowser: Page "Google Drive Factbox";
                begin
                    // Open Google Drive folder browser
                    Message('Funcionalidad de explorador de carpetas será implementada próximamente.\' +
                           'Por ahora, puede obtener el ID de carpeta desde Google Drive:\' +
                           '\' +
                           '1. Abra Google Drive en su navegador\' +
                           '2. Navegue a la carpeta deseada\' +
                           '3. Copie el ID de la URL (la parte después de /folders/)');
                end;
            }
            action("Recuperar ID de Carpeta")
            {
                ApplicationArea = All;
                Caption = 'Recuperar ID de Carpeta';
                ToolTip = 'Recupera el ID de la carpeta especificada.';
                Image = Indent;
                Scope = Repeater;

                trigger OnAction()
                var

                begin
                    Rec."Default Folder ID" := Rec.RecuperarIdFolder(Rec."Default Folder Name", true, false);
                    Rec.Modify();
                end;
            }

            action("Test Folder Access")
            {
                ApplicationArea = All;
                Caption = 'Probar Acceso a Carpeta';
                ToolTip = 'Prueba si se puede acceder a la carpeta especificada.';
                Image = TestReport;
                Scope = Repeater;

                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    Files: Record "Name/Value Buffer" temporary;
                begin
                    if Rec."Default Folder ID" = '' then begin
                        Message('Por favor, especifique un ID de carpeta primero.');
                        exit;
                    end;

                    GoogleDriveManager.Initialize();
                    GoogleDriveManager.ListFolder(Rec."Default Folder ID", Files, false);

                    if Files.FindFirst() then
                        Message('✅ Acceso exitoso a la carpeta. Se encontraron %1 elementos.', Files.Count)
                    else
                        Message('⚠️ La carpeta está vacía o no se pudo acceder. Verifique el ID de carpeta y los permisos.');
                end;
            }

            action("Create Test Subfolder")
            {
                ApplicationArea = All;
                Caption = 'Crear Subcarpeta de Prueba';
                ToolTip = 'Crea una subcarpeta de prueba usando el patrón especificado.';
                Image = Documents;
                Scope = Repeater;

                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    TestPath: Text;
                    TestDocNo: Text;
                    TestDate: Date;
                    FolderId: Text;
                    Origen: Enum "Data Storage Provider";
                begin
                    if Rec."Default Folder ID" = '' then begin
                        Message('Por favor, especifique un ID de carpeta primero.');
                        exit;
                    end;

                    TestDocNo := 'TEST-001';
                    TestDate := Today;

                    TestPath := Rec.CreateSubfolderPath(Rec."Table ID", TestDocNo, TestDate, Origen::"Google Drive");

                    if TestPath = '' then begin
                        Message('No se pudo generar la ruta de subcarpeta. Verifique la configuración.');
                        exit;
                    end;

                    GoogleDriveManager.Initialize();
                    FolderId := GoogleDriveManager.CreateFolder('TEST-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2>-<Hours24><Minutes,2>'), '', false);

                    if FolderId <> '' then
                        Message('✅ Subcarpeta de prueba creada exitosamente.\ID de carpeta: %1', FolderId)
                    else
                        Message('❌ Error al crear la subcarpeta de prueba.');
                end;
            }
        }

        area(Navigation)
        {
            action("Open Google Drive")
            {
                ApplicationArea = All;
                Caption = 'Abrir  Drive';
                ToolTip = 'Abre Google Drive en el navegador.';
                Image = Web;

                trigger OnAction()
                begin
                    Hyperlink('https://drive.google.com/');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Show helpful message on first open
        if not Rec.FindFirst() then begin
            Message('Esta página permite configurar dónde se almacenarán los archivos de diferentes tablas en Google Drive.\' +
                   '\' +
                   'Use "Configurar Mapeos por Defecto" para crear configuraciones iniciales.');
        end;
    end;
}