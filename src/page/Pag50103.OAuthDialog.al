// page 95104 "OAuth Completion Dialog"
// {
//     PageType = StandardDialog;
//     Caption = 'Completar Autenticación OAuth';

//     layout
//     {
//         area(content)
//         {
//             group(Instructions)
//             {
//                 Caption = 'Instrucciones';
//                 field(InstructionText; InstructionLbl)
//                 {
//                     ApplicationArea = All;
//                     Editable = false;
//                     ShowCaption = false;
//                     MultiLine = true;
//                 }
//             }

//             group(OOBInstructions)
//             {
//                 Caption = 'Proceso de Autorización';
//                 field(OOBInstructionText; OOBInstructionLbl)
//                 {
//                     ApplicationArea = All;
//                     Editable = false;
//                     ShowCaption = false;
//                     MultiLine = true;
//                 }
//             }

//             group(OAuthData)
//             {
//                 Caption = 'Datos de Autenticación';

//                 field(AuthorizationCode; AuthCode)
//                 {
//                     ApplicationArea = All;
//                     Caption = 'Código de Autorización';
//                     ToolTip = 'Ingrese el código de autorización obtenido de Google.';
//                     MultiLine = true;
//                 }

//                 field(StateParameter; StateParam)
//                 {
//                     ApplicationArea = All;
//                     Caption = 'Parámetro State';
//                     ToolTip = 'Ingrese el parámetro state de la URL de respuesta de Google.';
//                 }
//             }
//         }
//     }

//     actions
//     {
//         area(processing)
//         {
//             action(Complete)
//             {
//                 ApplicationArea = All;
//                 Caption = 'Completar Autenticación';
//                 Image = Approve;
//                 InFooterBar = true;

//                 trigger OnAction()
//                 var
//                     GoogleDriveManager: Codeunit "Google Drive Manager";
//                 begin
//                     if (AuthCode = '') or (StateParam = '') then begin
//                         Error('Por favor, complete todos los campos requeridos.');
//                     end;

//                     GoogleDriveManager.Initialize();
//                     if GoogleDriveManager.CompleteOAuthFlow(AuthCode, StateParam) then begin
//                         Message('Autenticación completada exitosamente.');
//                         CurrPage.Close();
//                     end;
//                 end;
//             }

//             action(Cancel)
//             {
//                 ApplicationArea = All;
//                 Caption = 'Cancelar';
//                 Image = Cancel;
//                 InFooterBar = true;

//                 trigger OnAction()
//                 begin
//                     CurrPage.Close();
//                 end;
//             }
//         }
//     }

//     var
//         AuthCode: Text;
//         StateParam: Text;
//         InstructionLbl: Label 'Después de autorizar el acceso en Google, será redirigido a una página con el código de autorización.\Copie el código y el parámetro state de la respuesta.';
//         OOBInstructionLbl: Label 'PASOS A SEGUIR:\1. Haga clic en el enlace de autorización que se mostró\2. Inicie sesión en Google si es necesario\3. Autorice el acceso a Google Drive\4. Google mostrará un código de autorización\5. Copie ese código en el campo "Código de Autorización"\6. Copie el parámetro state en el campo correspondiente\7. Haga clic en "Completar Autenticación"';
// }