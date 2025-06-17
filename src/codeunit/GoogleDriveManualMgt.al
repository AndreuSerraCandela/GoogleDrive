codeunit 95115 "Google Drive Manual Mgt"
{
    procedure GetManualContent(var TempBlob: Codeunit "Temp Blob")
    var
        CompanyInfo: Record "Company Information";
        InStr: InStream;
        OutStr: OutStream;
    begin
        CompanyInfo.Get();
        //if not CompanyInfo."Google Drive Manual".HasValue() then
        InitializeManual();

        CompanyInfo.Get();
        CompanyInfo.CalcFields("Google Drive Manual");
        CompanyInfo."Google Drive Manual".CreateInStream(InStr, TextEncoding::UTF8);
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;

    procedure InitializeManual()
    var
        CompanyInfo: Record "Company Information";
        OutStr: OutStream;
    begin
        CompanyInfo.Get();
        CompanyInfo."Google Drive Manual".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(GetDefaultManualContent());
        CompanyInfo.Modify();
    end;

    local procedure GetDefaultManualContent(): Text
    var
        Header: Text;
        Content: Text;
    begin
        Header := GetHeader();
        Content := GetContent();

        exit('<html>' +
        '<head>' +
        '<style>' +
        GetStyles() +
        '</style>' +
        '</head>' +
        '<body>' +
        Header +
        Content +
        '</body>' +
        '</html>'
        );
    end;

    local procedure GetStyles(): Text
    begin
        exit(
            '<style>' +
            'body { font-family: ''Segoe UI'', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }' +
            'h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }' +
            'h2 { color: #34495e; border-bottom: 2px solid #ecf0f1; padding-bottom: 8px; }' +
            'h3 { color: #2c3e50; }' +
            '.highlight { background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; margin: 20px 0; }' +
            '.success { background-color: #d4edda; border: 1px solid #c3e6cb; color: #155724; }' +
            '.warning { background-color: #fff3cd; border: 1px solid #ffeaa7; color: #856404; }' +
            '.info { background-color: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }' +
            'code { background-color: #f8f9fa; border: 1px solid #e9ecef; padding: 2px 6px; }' +
            'pre { background-color: #f8f9fa; border: 1px solid #e9ecef; padding: 15px; }' +
            'table { width: 100%; border-collapse: collapse; margin: 20px 0; }' +
            'th, td { border: 1px solid #dee2e6; padding: 12px; text-align: left; }' +
            'th { background-color: #f8f9fa; }' +
            '.feature-list { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin: 20px 0; }' +
            '.feature-item { background-color: #f8f9fa; border-left: 4px solid #007bff; padding: 15px; border-radius: 0 5px 5px 0; }' +
            '.step-list { counter-reset: step-counter; list-style: none; padding-left: 0; }' +
            '.step-list li { counter-increment: step-counter; margin: 15px 0; padding: 15px; background-color: #f8f9fa; border-left: 4px solid #28a745; border-radius: 0 5px 5px 0; position: relative; }' +
            '.step-list li::before { content: counter(step-counter); position: absolute; left: -20px; top: 15px; background-color: #28a745; color: white; width: 30px; height: 30px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; }' +
            '</style>'
        );
    end;

    local procedure GetHeader(): Text
    begin
        exit(
            '<h1>Manual de Usuario - Extensión Google Drive para Business Central</h1>' +
            '<div class="highlight info">' +
            '<h2>Tabla de Contenidos</h2>' +
            '<ul>' +
            '<li><a href="#introduccion">1. Introducción</a></li>' +
            '<li><a href="#requisitos">2. Requisitos Previos</a></li>' +
            '<li><a href="#configuracion">3. Configuración Inicial</a></li>' +
            '<li><a href="#funcionalidades">4. Funcionalidades Principales</a></li>' +
            '<li><a href="#gestion-archivos">5. Gestión de Archivos</a></li>' +
            '<li><a href="#configuracion-carpetas">6. Configuración de Carpetas</a></li>' +
            '<li><a href="#integracion-documentos">7. Integración con Documentos Adjuntos</a></li>' +
            '<li><a href="#solucion-problemas">8. Solución de Problemas</a></li>' +
            '<li><a href="#preguntas-frecuentes">9. Preguntas Frecuentes</a></li>' +
            '</ul>' +
            '</div>'
        );
    end;

    local procedure GetContent(): Text
    begin
        exit(
            GetIntroduction() +
            GetRequirements() +
            GetConfiguration() +
            GetFeatures() +
            GetFileManagement() +
            GetFolderConfiguration() +
            GetDocumentIntegration() +
            GetTroubleshooting() +
            GetFAQ()
        );
    end;

    local procedure GetIntroduction(): Text
    begin
        exit(
            '<section id="introduccion">' +
            '<h2>1. Introducción</h2>' +
            '<p>La <strong>Extensión Google Drive para Business Central</strong> permite integrar completamente Google Drive con Microsoft Dynamics 365 Business Central, proporcionando capacidades avanzadas de gestión de documentos y archivos directamente desde el ERP.</p>' +
            '<div class="feature-list">' +
            '<div class="feature-item"><strong>✅ Navegación completa</strong><br>Por carpetas y archivos de Google Drive</div>' +
            '<div class="feature-item"><strong>✅ Subida y descarga</strong><br>De archivos con interfaz intuitiva</div>' +
            '<div class="feature-item"><strong>✅ Creación y eliminación</strong><br>De carpetas directamente desde BC</div>' +
            '<div class="feature-item"><strong>✅ Movimiento de archivos</strong><br>Entre carpetas con drag & drop</div>' +
            '<div class="feature-item"><strong>✅ Integración nativa</strong><br>Con el sistema de documentos adjuntos</div>' +
            '<div class="feature-item"><strong>✅ Configuración automática</strong><br>De carpetas por tipo de documento</div>' +
            '<div class="feature-item"><strong>✅ Autenticación OAuth2</strong><br>Segura y estándar de Google</div>' +
            '<div class="feature-item"><strong>✅ Selección múltiple</strong><br>De archivos para operaciones en lote</div>' +
            '</div>' +
            '</section>'
        );
    end;

    local procedure GetRequirements(): Text
    begin
        exit(
            '<section id="requisitos">' +
            '<h2>2. Requisitos Previos</h2>' +
            '<div class="highlight info">' +
            '<h3>Requisitos del Sistema</h3>' +
            '<ul>' +
            '<li>Microsoft Dynamics 365 Business Central (versión 18.0 o superior)</li>' +
            '<li>Cuenta de Google Drive activa</li>' +
            '<li>Permisos de administrador en Business Central</li>' +
            '<li>Conexión a Internet estable</li>' +
            '</ul>' +
            '</div>' +
            '<h3>Configuración en Google Cloud Console</h3>' +
            '<ol class="step-list">' +
            '<li><strong>Crear un Proyecto en Google Cloud Console</strong><br>Vaya a <a href="https://console.cloud.google.com/">Google Cloud Console</a> y cree un nuevo proyecto o seleccione uno existente</li>' +
            '<li><strong>Habilitar la API de Google Drive</strong><br>En el panel de APIs y servicios, busque "Google Drive API" y haga clic en "Habilitar"</li>' +
            '<li><strong>Crear Credenciales OAuth2</strong><br>Vaya a "Credenciales" → "Crear credenciales" → "ID de cliente OAuth"<br>Tipo de aplicación: "Aplicación web"<br>Configure las URIs de redirección autorizadas</li>' +
            '<li><strong>Obtener Client ID y Client Secret</strong><br>Descargue el archivo JSON con las credenciales<br>Guarde el Client ID y Client Secret para la configuración</li>' +
            '</ol>' +
            '</section>'
        );
    end;

    local procedure GetConfiguration(): Text
    begin
        exit(
            '<section id="configuracion">' +
            '<h2>3. Configuración Inicial</h2>' +
            '<h3>Paso 1: Configurar Credenciales de Google</h3>' +
            '<ol class="step-list">' +
            '<li><strong>Acceder a Información de la Empresa</strong><br>Navegue a <code>Configuración</code> → <code>Información de la empresa</code><br>Busque la sección "Google Drive Configuration"</li>' +
            '<li><strong>Completar los Campos de Configuración</strong><br><pre>Google Client ID: [Su Client ID de Google]' +
            '<br>Google Client Secret: [Su Client Secret de Google]' +
            '<br>Google Auth URI: https://accounts.google.com/o/oauth2/auth' +
            '<br>Google Token URI: https://oauth2.googleapis.com/token' +
            '<br>Google Drive API URL: https://www.googleapis.com/drive/v3/' +
            '</pre></li>' +
            '</ol>' +
            '</ol>' +
            '<h3>Paso 2: Autenticación OAuth2</h3>' +
            '<ol class="step-list">' +
            '<li><strong>Iniciar el Proceso de Autenticación</strong><br>La primera vez que use cualquier funcionalidad de Google Drive, el sistema le solicitará autenticarse</li>' +
            '<li><strong>Completar la Autorización</strong><br>Se abrirá una ventana del navegador<br>Inicie sesión con su cuenta de Google<br>Autorice el acceso a Google Drive<br>Copie el código de autorización proporcionado</li>' +
            '<li><strong>Introducir el Código de Autorización</strong><br>Pegue el código en el diálogo de Business Central<br>El sistema obtendrá automáticamente los tokens de acceso</li>' +
            '</ol>' +
            '<div class="highlight success">' +
            '<strong>Probar la Conexión:</strong> Use la acción "Test Folder Access" en cualquier configuración para verificar que puede listar archivos y carpetas.' +
            '</div>' +
            '</section>'
        );
    end;

    local procedure GetFeatures(): Text
    begin
        exit(
            '<section id="funcionalidades">' +
            '<h2>4. Funcionalidades Principales</h2>' +
            '<h3>1. Explorador de Google Drive (Factbox)</h3>' +
            '<p>El <strong>Google Drive Factbox</strong> proporciona una interfaz similar al explorador de archivos para navegar por Google Drive.</p>' +
            '<h4>Características:</h4>' +
            '<ul>' +
            '<li><strong>Navegación por carpetas:</strong> Haga doble clic en una carpeta para abrirla</li>' +
            '<li><strong>Navegación hacia atrás:</strong> Use el botón "Anterior" o haga clic en ".."</li>' +
            '<li><strong>Visualización de tipos:</strong> Distingue entre carpetas y archivos</li>' +
            '<li><strong>Acciones contextuales:</strong> Diferentes acciones según el tipo de elemento</li>' +
            '</ul>' +
            '<h4>Acciones Disponibles:</h4>' +
            '<table>' +
            '<thead><tr><th>Acción</th><th>Descripción</th><th>Disponible para</th></tr></thead>' +
            '<tbody>' +
            '<tr><td>Anterior</td><td>Navegar a la carpeta padre</td><td>Siempre</td></tr>' +
            '<tr><td>Descargar Archivo</td><td>Descargar archivos seleccionados</td><td>Solo archivos</td></tr>' +
            '<tr><td>Mover</td><td>Mover archivos/carpetas a otra ubicación</td><td>Archivos y carpetas</td></tr>' +
            '<tr><td>Crear Carpeta</td><td>Crear nuevas carpetas</td><td>Siempre</td></tr>' +
            '<tr><td>Borrar</td><td>Eliminar archivos/carpetas</td><td>Archivos y carpetas</td></tr>' +
            '<tr><td>Subir Archivo</td><td>Cargar archivos desde el equipo local</td><td>Siempre</td></tr>' +
            '</tbody>' +
            '</table>' +
            '</section>'
        );
    end;

    local procedure GetFileManagement(): Text
    begin
        exit(
            '<section id="gestion-archivos">' +
            '<h2>5. Gestión de Archivos</h2>' +
            '<h3>Subir Archivos</h3>' +
            '<h4>1. Desde el Explorador</h4>' +
            '<ol class="step-list">' +
            '<li>Navegue a la carpeta deseada</li>' +
            '<li>Haga clic en "Subir Archivo"</li>' +
            '<li>Seleccione el archivo desde su equipo</li>' +
            '<li>El archivo se cargará automáticamente</li>' +
            '</ol>' +
            '<h4>2. Desde Documentos Adjuntos</h4>' +
            '<ol class="step-list">' +
            '<li>Use la acción "Cargar archivo desde Google Drive"</li>' +
            '<li>Seleccione archivos existentes en Google Drive</li>' +
            '<li>Se vincularán automáticamente al registro</li>' +
            '</ol>' +
            '</section>'
        );
    end;

    local procedure GetFolderConfiguration(): Text
    begin
        exit(
            '<section id="configuracion-carpetas">' +
            '<h2>6. Configuración de Carpetas</h2>' +
            '<h3>Google Drive Folder Mapping</h3>' +
            '<p>Esta funcionalidad permite configurar carpetas específicas de Google Drive para diferentes tipos de documentos en Business Central.</p>' +
            '<h4>Campos de Configuración</h4>' +
            '<table>' +
            '<thead><tr><th>Campo</th><th>Descripción</th><th>Ejemplo</th></tr></thead>' +
            '<tbody>' +
            '<tr><td><strong>Table ID</strong></td><td>ID de la tabla de BC</td><td>18 (Customer)</td></tr>' +
            '<tr><td><strong>Table Name</strong></td><td>Nombre de la tabla</td><td>Customer</td></tr>' +
            '<tr><td><strong>Default Folder Name</strong></td><td>Nombre de referencia</td><td>Clientes</td></tr>' +
            '<tr><td><strong>Default Folder ID</strong></td><td>ID de carpeta en Google Drive</td><td>1BxY...xyz</td></tr>' +
            '<tr><td><strong>Auto Create Subfolders</strong></td><td>Crear subcarpetas automáticamente</td><td>✓</td></tr>' +
            '<tr><td><strong>Subfolder Pattern</strong></td><td>Patrón para subcarpetas</td><td>{YEAR}/{DOCNO}</td></tr>' +
            '<tr><td><strong>Active</strong></td><td>Configuración activa</td><td>✓</td></tr>' +
            '<tr><td><strong>Description</strong></td><td>Descripción opcional</td><td>Documentos de clientes</td></tr>' +
            '</tbody>' +
            '</table>' +
            '</section>'
        );
    end;

    local procedure GetDocumentIntegration(): Text
    begin
        exit(
            '<section id="integracion-documentos">' +
            '<h2>7. Integración con Documentos Adjuntos</h2>' +
            '<h3>Configuración de Documentos Adjuntos</h3>' +
            '<p>La extensión modifica el comportamiento estándar de los documentos adjuntos para usar Google Drive como almacenamiento.</p>' +
            '<h4>Campos Adicionales</h4>' +
            '<ul>' +
            '<li><strong>Store in Google Drive:</strong> Checkbox para habilitar almacenamiento en Google Drive</li>' +
            '<li><strong>Google Drive ID:</strong> ID del archivo en Google Drive (solo lectura)</li>' +
            '</ul>' +
            '</section>'
        );
    end;

    local procedure GetTroubleshooting(): Text
    begin
        exit(
            '<section id="solucion-problemas">' +
            '<h2>8. Solución de Problemas</h2>' +
            '<div class="highlight warning">' +
            '<h3>Problemas de Autenticación</h3>' +
            '<h4>Error: "Token Expired"</h4>' +
            '<p><strong>Causa:</strong> El token de acceso ha expirado.</p>' +
            '<p><strong>Solución:</strong></p>' +
            '<ol>' +
            '<li>El sistema intentará renovar automáticamente el token</li>' +
            '<li>Si falla, vuelva a autenticarse desde la configuración</li>' +
            '<li>Verifique que el Refresh Token sea válido</li>' +
            '</ol>' +
            '</div>' +
            '</section>'
        );
    end;

    local procedure GetFAQ(): Text
    begin
        exit(
            '<section id="preguntas-frecuentes">' +
            '<h2>9. Preguntas Frecuentes</h2>' +
            '<div class="highlight info">' +
            '<h3>General</h3>' +
            '<p><strong>P: ¿Puedo usar múltiples cuentas de Google Drive?</strong></p>' +
            '<p>R: Actualmente, la extensión soporta una cuenta de Google Drive por empresa en Business Central.</p>' +
            '<p><strong>P: ¿Los archivos se sincronizan automáticamente?</strong></p>' +
            '<p>R: Los archivos se almacenan directamente en Google Drive. Los cambios realizados en Google Drive se reflejan inmediatamente en Business Central.</p>' +
            '</div>' +
            '</section>'
        );
    end;
}