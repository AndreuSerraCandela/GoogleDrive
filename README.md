# Google Drive Integration para Business Central

Esta extensión permite integrar Business Central con Google Drive para almacenar y gestionar documentos automáticamente.

## 🚀 Características Principales

- **Autenticación OAuth 2.0** completa con Google Drive
- **Mapeo de carpetas** por tipo de tabla/documento
- **Creación automática de subcarpetas** basada en patrones configurables
- **Gestión de tokens** con renovación automática
- **Diagnóstico avanzado** de configuración OAuth
- **Subida y descarga** de archivos
- **Gestión de carpetas** (crear, mover, eliminar)

## 📋 Requisitos Previos

1. **Google Cloud Console Project** configurado
2. **Google Drive API** habilitada
3. **Credenciales OAuth 2.0** (Client ID y Client Secret)

## 🔧 Configuración Inicial

### 1. Configurar Google Cloud Console

1. Vaya a [Google Cloud Console](https://console.cloud.google.com/)
2. Cree un nuevo proyecto o seleccione uno existente
3. Habilite la **Google Drive API**
4. Vaya a **Credenciales** > **Crear credenciales** > **ID de cliente OAuth 2.0**
5. Configure el tipo de aplicación como **Aplicación de escritorio**
6. Copie el **Client ID** y **Client Secret**

### 2. Configurar en Business Central

1. Vaya a **Company Information**
2. En la sección **Google Drive Configuration**, complete:
   - **Google Client ID**: Su Client ID de Google Cloud Console
   - **Google Client Secret**: Su Client Secret de Google Cloud Console
3. Use **"Configurar Valores por Defecto"** para establecer las URLs estándar

### 3. Obtener Tokens OAuth (MÉTODO RECOMENDADO)

⚠️ **IMPORTANTE**: Use siempre **SUS propias credenciales**, no las del OAuth Playground.

1. En Company Information, haga clic en **"Usar OAuth Playground (Recomendado)"**
2. En OAuth Playground:
   - **🔧 PASO CRÍTICO**: Haga clic en ⚙️ (Settings) en la esquina superior derecha
   - ✅ Marque **"Use your own OAuth credentials"**
   - Ingrese **SU Client ID** y **Client Secret**
   - Haga clic en **"Close"**
3. Seleccione los scopes:
   - `https://www.googleapis.com/auth/drive`
   - `https://www.googleapis.com/auth/drive.file`
4. Haga clic en **"Authorize APIs"**
5. Haga clic en **"Exchange authorization code for tokens"**
6. Copie el **access_token** y **refresh_token**
7. En Business Central:
   - Use **"Habilitar Entrada Manual de Tokens"**
   - Pegue los tokens en los campos correspondientes

## ❌ Solución de Problemas Comunes

### Error "invalid_client" / "Unauthorized"

Este error indica que las credenciales no son válidas. **Causas más comunes**:

#### 1. **Credenciales del OAuth Playground (NO las suyas)**
- **Problema**: Olvidó marcar "Use your own OAuth credentials"
- **Solución**: Repita el proceso asegurándose de configurar SUS credenciales

#### 2. **Client ID o Secret incorrectos**
- **Problema**: Credenciales copiadas incorrectamente
- **Solución**: Verifique que no haya espacios extra o caracteres faltantes

#### 3. **Proyecto de Google Cloud mal configurado**
- **Problema**: API no habilitada o credenciales deshabilitadas
- **Solución**: Verifique en Google Cloud Console que:
  - Google Drive API esté habilitada
  - Las credenciales OAuth estén activas
  - El proyecto esté en estado "En producción" o "Testing"

#### 4. **Tokens generados con credenciales diferentes**
- **Problema**: Los tokens se generaron con otras credenciales
- **Solución**: Regenere los tokens usando SUS credenciales

### Usar el Diagnóstico Integrado

1. En Company Information, use **"Diagnosticar Configuración OAuth"**
2. Revise la información mostrada:
   - Longitud de credenciales
   - Estado de tokens
   - URLs configuradas

## 📁 Configuración de Mapeo de Carpetas

### Acceder a la Configuración

1. En Company Information, haga clic en **"Configurar Mapeo de Carpetas"**
2. O busque **"Google Drive Folder Mapping"** en el menú

### Configurar Mapeos

1. Use **"Configurar Mapeos por Defecto"** para crear configuraciones iniciales
2. Para cada tabla, configure:
   - **Table ID**: ID de la tabla de Business Central
   - **Default Folder Name**: Nombre de referencia
   - **Default Folder ID**: ID de la carpeta en Google Drive
   - **Auto Create Subfolders**: Si crear subcarpetas automáticamente
   - **Subfolder Pattern**: Patrón para subcarpetas

### Patrones de Subcarpetas

Use estos marcadores en **Subfolder Pattern**:
- `{YEAR}`: Año del documento (ej: 2024)
- `{MONTH}`: Mes del documento (ej: 03)
- `{DOCNO}`: Número del documento

**Ejemplos**:
- `{YEAR}/{MONTH}`: Crea carpetas como "2024/03"
- `{YEAR}`: Crea carpetas como "2024"
- `{DOCNO}`: Crea carpetas con el número de documento

### Obtener IDs de Carpetas

1. Abra Google Drive en su navegador
2. Navegue a la carpeta deseada
3. Copie el ID de la URL: `https://drive.google.com/drive/folders/[ID_DE_CARPETA]`
4. O use **"Recuperar ID de Carpeta"** en la configuración

## 🔄 Funciones Principales

### Autenticación
- `StartOAuthFlow()`: Inicia flujo OAuth tradicional
- `StartOAuthFlowPlayground()`: Abre OAuth Playground (recomendado)
- `RefreshAccessToken()`: Actualiza tokens automáticamente
- `RevokeAccess()`: Revoca acceso y limpia tokens

### Gestión de Archivos
- `UploadFileToConfiguredFolder()`: Sube archivo a carpeta configurada
- `DownloadFile()`: Descarga archivo desde Google Drive
- `CreateFolder()`: Crea nueva carpeta
- `ListFolder()`: Lista contenido de carpeta

### Diagnóstico
- `DiagnoseOAuthConfiguration()`: Diagnóstico completo de configuración
- `ValidateConfiguration()`: Valida configuración básica
- `TestTokenValidity()`: Verifica validez de tokens

## 📊 Tablas Configuradas por Defecto

| Table ID | Tabla | Carpeta Sugerida | Patrón |
|----------|-------|------------------|---------|
| 36 | Sales Header | Sales Orders | {YEAR} |
| 38 | Purchase Header | Purchase Orders | {YEAR} |
| 112 | Sales Invoice Header | Sales Invoices | {YEAR}/{MONTH} |
| 18 | Customer | Customers | - |
| 23 | Vendor | Vendors | - |

## 🛠️ Desarrollo y Personalización

### Estructura de Archivos

```
src/
├── table/
│   └── Tab95100.GoogleDriveFolderMapping.al
├── tableextension/
│   └── CompanyInfoExt.al
├── page/
│   ├── Pag95103.OAuthDialog.al
│   └── Pag95104.GoogleDriveFolderMapping.al
├── page-ext/
│   └── Pag-Ext95101.CompanyInfoExt.al
└── codeunit/
    └── Cod95100.GoogleDriveManager.al
```

### Extender Funcionalidad

Para agregar soporte a nuevas tablas:

1. Agregue entrada en **Google Drive Folder Mapping**
2. Configure carpeta y patrón de subcarpetas
3. Use `GetTargetFolderForDocument()` en su código

## 📞 Soporte

Si experimenta problemas:

1. Use **"Diagnosticar Configuración OAuth"** primero
2. Verifique que esté usando **SUS credenciales** en OAuth Playground
3. Confirme que Google Drive API esté habilitada
4. Regenere tokens si es necesario

## 🔐 Seguridad

- Los tokens se almacenan con máscara de seguridad
- Client Secret está protegido
- Refresh automático de tokens
- Revocación de acceso disponible

---

**Versión**: 1.0.0  
**Compatibilidad**: Business Central 2023+  
**Autor**: [Su Nombre] 