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
                    ToolTip = 'Specifies the ID of the Business Central table.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the name of the Business Central table.';
                }

                field("Default Folder Name"; Rec."Default Folder Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the Drive folder (for reference only).';
                }

                field("Default Folder ID"; Rec."Default Folder ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the Drive folder where files will be stored.';
                    Editable = false;
                }

                field("Auto Create Subfolders"; Rec."Auto Create Subfolders")
                {
                    ApplicationArea = All;
                    ToolTip = 'If enabled, it will automatically create subfolders based on the specified pattern.';
                }

                field("Subfolder Pattern"; Rec."Subfolder Pattern")
                {
                    ApplicationArea = All;
                    ToolTip = 'Pattern for creating subfolders. Use {DOCNO} for document number, {NO} for Code, {YEAR} for year, {MONTH} for month.';
                }

                field("Active"; Rec."Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if this configuration is active.';
                }

                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Optional description for this configuration.';
                }

                field("Created Date"; Rec."Created Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Date and time when this record was created.';
                }

                field("Modified Date"; Rec."Modified Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Date and time when this record was last modified.';
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
                Caption = 'Setup Default Mappings';
                ToolTip = 'Creates default configurations for the most common tables.';
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
                Caption = 'Browse Drive Folder';
                ToolTip = 'Opens the Google Drive browser to select a folder.';
                Image = AddToHome;
                Scope = Repeater;

                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    FolderBrowser: Page "Google Drive Factbox";
                begin
                    // Open Google Drive folder browser
                    Message(FolderBrowserNotImplementedLbl);
                end;
            }
            action("Recuperar ID de Carpeta")
            {
                ApplicationArea = All;
                Caption = 'Retrieve Folder ID';
                ToolTip = 'Retrieves the ID of the specified folder.';
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
                Caption = 'Test Folder Access';
                ToolTip = 'Tests if the specified folder can be accessed.';
                Image = TestReport;
                Scope = Repeater;

                trigger OnAction()
                var
                    GoogleDriveManager: Codeunit "Google Drive Manager";
                    Files: Record "Name/Value Buffer" temporary;
                begin
                    if Rec."Default Folder ID" = '' then begin
                        Message(PleaseSpecifyFolderIDLbl);
                        exit;
                    end;

                    GoogleDriveManager.Initialize();
                    GoogleDriveManager.ListFolder(Rec."Default Folder ID", Files, false);

                    if Files.FindFirst() then
                        Message(FolderAccessSuccessLbl, Files.Count)
                    else
                        Message(FolderEmptyOrInaccessibleLbl);
                end;
            }

            action("Create Test Subfolder")
            {
                ApplicationArea = All;
                Caption = 'Create Test Subfolder';
                ToolTip = 'Creates a test subfolder using the specified pattern.';
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
                        Message(PleaseSpecifyFolderIDLbl);
                        exit;
                    end;

                    TestDocNo := 'TEST-001';
                    TestDate := Today;

                    TestPath := Rec.CreateSubfolderPath(Rec."Table ID", TestDocNo, TestDate, Origen::"Google Drive");

                    if TestPath = '' then begin
                        Message(CouldNotGenerateSubfolderPathLbl);
                        exit;
                    end;

                    GoogleDriveManager.Initialize();
                    FolderId := GoogleDriveManager.CreateFolder('TEST-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2>-<Hours24><Minutes,2>'), '', false);

                    if FolderId <> '' then
                        Message(TestSubfolderCreatedSuccessLbl, FolderId)
                    else
                        Message(ErrorCreatingTestSubfolderLbl);
                end;
            }
        }

        area(Navigation)
        {
            action("Open Google Drive")
            {
                ApplicationArea = All;
                Caption = 'Open Drive';
                ToolTip = 'Opens Drive in the browser.';
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
            Message(SetupDefaultMappingsLbl);
        end;
    end;

    var
        FolderBrowserNotImplementedLbl: Label 'Folder browser functionality will be implemented soon.\For now, you can get the folder ID from Google Drive:\1. Open Google Drive in your browser\2. Navigate to the desired folder\3. Copy the ID from the URL (the part after /folders/)';
        PleaseSpecifyFolderIDLbl: Label 'Please specify a folder ID first.';
        FolderAccessSuccessLbl: Label '✅ Successful folder access. Found %1 items.', Comment = '%1 = Number of items found';
        FolderEmptyOrInaccessibleLbl: Label '⚠️ The folder is empty or could not be accessed. Verify the folder ID and permissions.';
        CouldNotGenerateSubfolderPathLbl: Label 'Could not generate subfolder path. Verify the configuration.';
        TestSubfolderCreatedSuccessLbl: Label '✅ Test subfolder created successfully.\Folder ID: %1', Comment = '%1 = Folder ID';
        ErrorCreatingTestSubfolderLbl: Label '❌ Error creating test subfolder.';
        SetupDefaultMappingsLbl: Label 'This page allows you to configure where files from different tables will be stored in Drive.\Use "Setup Default Mappings" to create initial configurations.';

}