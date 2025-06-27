# Manual de Usuario - Extensión Google Drive para Business Central

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Requisitos Previos](#requisitos-previos)
3. [Configuración Inicial](#configuración-inicial)
4. [Funcionalidades Principales](#funcionalidades-principales)
5. [Gestión de Archivos](#gestión-de-archivos)
6. [Configuración de Carpetas](#configuración-de-carpetas)
7. [Integración con Documentos Adjuntos](#integración-con-documentos-adjuntos)
8. [Solución de Problemas](#solución-de-problemas)
9. [Preguntas Frecuentes](#preguntas-frecuentes)

---

## Introducción

La **Extensión Google Drive para Business Central** permite integrar completamente Google Drive con Microsoft Dynamics 365 Business Central, proporcionando capacidades avanzadas de gestión de documentos y archivos directamente desde el ERP.

### Características Principales

- ✅ **Navegación completa** por carpetas y archivos de Google Drive
- ✅ **Subida y descarga** de archivos
- ✅ **Creación y eliminación** de carpetas
- ✅ **Movimiento de archivos** entre carpetas
- ✅ **Integración nativa** con el sistema de documentos adjuntos de BC
- ✅ **Configuración automática** de carpetas por tipo de documento
- ✅ **Autenticación OAuth2** segura
- ✅ **Selección múltiple** de archivos
- ✅ **Gestión de permisos** y acceso

---

## Requisitos Previos

### Requisitos del Sistema

- Microsoft Dynamics 365 Business Central (versión 18.0 o superior)
- Cuenta de Google Drive activa
- Permisos de administrador en Business Central
- Conexión a Internet estable

### Configuración en Google Cloud Console

Antes de usar la extensión, debe configurar un proyecto en Google Cloud Console:

1. **Crear un Proyecto en Google Cloud Console**
   - Vaya a [Google Cloud Console](https://console.cloud.google.com/)
   - Cree un nuevo proyecto o seleccione uno existente

2. **Habilitar la API de Google Drive**
   - En el panel de APIs y servicios
   - Busque "Google Drive API"
   - Haga clic en "Habilitar"

3. **Crear Credenciales OAuth2**
   - Vaya a "Credenciales" → "Crear credenciales" → "ID de cliente OAuth"
   - Tipo de aplicación: "Aplicación web"
   - Configure las URIs de redirección autorizadas

4. **Obtener Client ID y Client Secret**
   - Descargue el archivo JSON con las credenciales
   - Guarde el Client ID y Client Secret para la configuración

---

## Configuración Inicial

### Paso 1: Configurar Credenciales de Google

1. **Acceder a Información de la Empresa**
   - Navegue a `Configuración` → `Información de la empresa`
   - Busque la sección "Google Drive Configuration"

2. **Completar los Campos de Configuración**
   ```
   Google Client ID: [Su Client ID de Google]
   Google Client Secret: [Su Client Secret de Google]
   Google Auth URI: https://accounts.google.com/o/oauth2/auth
   Google Token URI: https://oauth2.googleapis.com/token
   Google Drive API URL: https://www.googleapis.com/drive/v3/
   ```

### Paso 2: Autenticación OAuth2

1. **Iniciar el Proceso de Autenticación**
   - La primera vez que use cualquier funcionalidad de Google Drive
   - El sistema le solicitará autenticarse

2. **Completar la Autorización**
   - Se abrirá una ventana del navegador
   - Inicie sesión con su cuenta de Google
   - Autorice el acceso a Google Drive
   - Copie el código de autorización proporcionado

3. **Introducir el Código de Autorización**
   - Pegue el código en el diálogo de Business Central
   - El sistema obtendrá automáticamente los tokens de acceso

### Paso 3: Verificar la Configuración

1. **Probar la Conexión**
   - Use la acción "Test Folder Access" en cualquier configuración
   - Verifique que puede listar archivos y carpetas

---

## Funcionalidades Principales

### 1. Explorador de Google Drive (Factbox)

El **Google Drive Factbox** proporciona una interfaz similar al explorador de archivos para navegar por Google Drive.

#### Características:
- **Navegación por carpetas**: Haga doble clic en una carpeta para abrirla
- **Navegación hacia atrás**: Use el botón "Anterior" o haga clic en ".."
- **Visualización de tipos**: Distingue entre carpetas y archivos
- **Acciones contextuales**: Diferentes acciones según el tipo de elemento

#### Acciones Disponibles:
- **Anterior**: Navegar a la carpeta padre
- **Descargar Archivo**: Descargar archivos seleccionados
- **Mover**: Mover archivos/carpetas a otra ubicación
- **Crear Carpeta**: Crear nuevas carpetas
- **Borrar**: Eliminar archivos/carpetas
- **Subir Archivo**: Cargar archivos desde el equipo local

### 2. Lista de Google Drive (Selección)

La **Google Drive List** permite seleccionar múltiples archivos para operaciones en lote.

#### Características:
- **Selección múltiple**: Marque varios archivos usando checkboxes
- **Selección individual**: Haga clic en un archivo para seleccionarlo
- **Filtrado visual**: Distingue carpetas de archivos
- **Navegación completa**: Misma funcionalidad que el Factbox

#### Acciones Especiales:
- **Seleccionar**: Seleccionar el archivo actual
- **Seleccionar Marcados**: Seleccionar todos los archivos marcados
- **Todas las acciones del Factbox**

### 3. Gestión de Archivos

#### Subir Archivos
1. **Desde el Explorador**
   - Navegue a la carpeta deseada
   - Haga clic en "Subir Archivo"
   - Seleccione el archivo desde su equipo
   - El archivo se cargará automáticamente

2. **Desde Documentos Adjuntos**
   - Use la acción "Cargar archivo desde Google Drive"
   - Seleccione archivos existentes en Google Drive
   - Se vincularán automáticamente al registro

#### Descargar Archivos
1. **Descarga Individual**
   - Seleccione el archivo
   - Haga clic en "Descargar Archivo"
   - El archivo se descargará a su equipo

2. **Descarga Múltiple**
   - Marque varios archivos en la lista
   - Use "Seleccionar Marcados"
   - Procese la descarga en lote

#### Mover Archivos
1. **Seleccionar Origen**
   - Navegue al archivo/carpeta a mover
   - Haga clic en "Mover"

2. **Seleccionar Destino**
   - El sistema mostrará las carpetas disponibles
   - Seleccione la carpeta de destino
   - Confirme la operación

#### Crear Carpetas
1. **Navegación**
   - Vaya a la ubicación donde crear la carpeta
   - Haga clic en "Crear Carpeta"

2. **Configuración**
   - Introduzca el nombre de la carpeta
   - Confirme la creación

#### Eliminar Elementos
1. **Selección**
   - Seleccione el archivo/carpeta a eliminar
   - Haga clic en "Borrar"

2. **Confirmación**
   - Confirme la eliminación
   - El elemento se moverá a la papelera de Google Drive

---

## Configuración de Carpetas

### Google Drive Folder Mapping

Esta funcionalidad permite configurar carpetas específicas de Google Drive para diferentes tipos de documentos en Business Central.

#### Acceso a la Configuración
- Navegue a `Configuración` → `Google Drive Folder Mapping`

#### Campos de Configuración

| Campo | Descripción | Ejemplo |
|-------|-------------|---------|
| **Table ID** | ID de la tabla de BC | 18 (Customer) |
| **Table Name** | Nombre de la tabla | Customer |
| **Default Folder Name** | Nombre de referencia | Clientes |
| **Default Folder ID** | ID de carpeta en Google Drive | 1BxY...xyz |
| **Auto Create Subfolders** | Crear subcarpetas automáticamente | ✓ |
| **Subfolder Pattern** | Patrón para subcarpetas | {YEAR}/{DOCNO}/{NO} |
| **Active** | Configuración activa | ✓ |
| **Description** | Descripción opcional | Documentos de clientes |

#### Patrones de Subcarpetas

Puede usar los siguientes tokens en el patrón de subcarpetas:

- `{DOCNO}`: Número de documento
- `{NO}`: Código de la ficha
- `{YEAR}`: Año actual
- `{MONTH}`: Mes actual (01-12)
- `{DAY}`: Día actual (01-31)

#### Ejemplos de Configuración

**Para Facturas de Venta:**
```
Table ID: 112
Default Folder Name: Facturas de Venta
Subfolder Pattern: {YEAR}/Facturas/{DOCNO}
```

**Para Documentos de Cliente:**
```
Table ID: 18
Default Folder Name: Clientes
Subfolder Pattern: {NO}/{YEAR}
```

#### Acciones Disponibles

1. **Configurar Mapeos por Defecto**
   - Crea configuraciones predeterminadas para tablas comunes
   - Incluye: Clientes, Proveedores, Productos, Facturas, etc.

2. **Explorar Carpeta Google Drive**
   - Abre el explorador para seleccionar carpetas
   - Facilita la obtención de IDs de carpeta

3. **Recuperar ID de Carpeta**
   - Busca automáticamente el ID basado en el nombre
   - Útil para carpetas existentes

4. **Probar Acceso a Carpeta**
   - Verifica que la configuración funciona correctamente
   - Muestra el número de elementos encontrados

5. **Crear Subcarpeta de Prueba**
   - Crea una subcarpeta usando el patrón configurado
   - Permite probar la configuración antes de usar

---

## Integración con Documentos Adjuntos

### Configuración de Documentos Adjuntos

La extensión modifica el comportamiento estándar de los documentos adjuntos para usar Google Drive como almacenamiento.

#### Campos Adicionales

En cualquier lista de documentos adjuntos, encontrará:

- **Store in Google Drive**: Checkbox para habilitar almacenamiento en Google Drive
- **Google Drive ID**: ID del archivo en Google Drive (solo lectura)

#### Funcionalidades Mejoradas

1. **Carga Automática**
   - Los archivos marcados como "Store in Google Drive" se suben automáticamente
   - Se almacena el ID de Google Drive en lugar del contenido en BC

2. **Descarga Transparente**
   - Al abrir un archivo almacenado en Google Drive
   - Se descarga automáticamente desde Google Drive

3. **Gestión de Tipos de Archivo**
   - Reconocimiento automático de tipos de archivo
   - Configuración de iconos y comportamientos específicos

### Cargar Archivos desde Google Drive

#### Proceso Paso a Paso

1. **Acceder a Documentos Adjuntos**
   - Abra cualquier registro que soporte documentos adjuntos
   - Vaya a la sección "Documentos Adjuntos"

2. **Usar la Acción Especial**
   - Haga clic en "Cargar archivo desde Google Drive"
   - Se abrirá el explorador de Google Drive

3. **Navegar y Seleccionar**
   - Navegue por las carpetas de Google Drive
   - Seleccione uno o múltiples archivos
   - Use "Seleccionar Marcados" para selección múltiple

4. **Confirmación**
   - Los archivos se vincularán automáticamente al registro
   - Se crearán entradas de documentos adjuntos
   - Los archivos permanecen en Google Drive

#### Ventajas de esta Integración

- **Ahorro de Espacio**: Los archivos no se duplican en BC
- **Sincronización**: Cambios en Google Drive se reflejan automáticamente
- **Colaboración**: Múltiples usuarios pueden acceder a los mismos archivos
- **Versionado**: Google Drive mantiene el historial de versiones

---

## Casos de Uso Comunes

### 1. Gestión de Documentos de Cliente

**Escenario**: Almacenar contratos, facturas y correspondencia de clientes.

**Configuración**:
```
Table ID: 18 (Customer)
Default Folder Name: Clientes
Subfolder Pattern: {CUSTOMERNO}/{YEAR}
Auto Create Subfolders: ✓
```

**Flujo de Trabajo**:
1. Al adjuntar un documento a un cliente
2. Se crea automáticamente la carpeta "Clientes/CUST001/2024"
3. El documento se almacena en Google Drive
4. Se mantiene la referencia en Business Central

### 2. Archivo de Facturas

**Escenario**: Organizar facturas por año y número.

**Configuración**:
```
Table ID: 112 (Sales Invoice Header)
Default Folder Name: Facturas
Subfolder Pattern: {YEAR}/Facturas/{DOCNO}
Auto Create Subfolders: ✓
```

**Resultado**: Estructura como "Facturas/2024/Facturas/FAC-001"

### 3. Documentos de Productos

**Escenario**: Manuales, especificaciones técnicas, imágenes.

**Configuración**:
```
Table ID: 27 (Item)
Default Folder Name: Productos
Subfolder Pattern: {ITEMNO}/Documentos
Auto Create Subfolders: ✓
```

### 4. Gestión de Proyectos

**Escenario**: Documentos relacionados con proyectos específicos.

**Configuración**:
```
Table ID: 167 (Job)
Default Folder Name: Proyectos
Subfolder Pattern: {JOBNO}/{YEAR}
Auto Create Subfolders: ✓
```

---

## Solución de Problemas

### Problemas de Autenticación

#### Error: "Token Expired"
**Causa**: El token de acceso ha expirado.
**Solución**:
1. El sistema intentará renovar automáticamente el token
2. Si falla, vuelva a autenticarse desde la configuración
3. Verifique que el Refresh Token sea válido

#### Error: "Invalid Client ID"
**Causa**: Credenciales incorrectas o proyecto de Google Cloud mal configurado.
**Solución**:
1. Verifique el Client ID y Client Secret
2. Confirme que la API de Google Drive está habilitada
3. Revise las URIs de redirección en Google Cloud Console

### Problemas de Conectividad

#### Error: "Cannot Connect to Google Drive"
**Causa**: Problemas de red o configuración de proxy.
**Solución**:
1. Verifique la conexión a Internet
2. Confirme que no hay bloqueos de firewall
3. Revise la configuración de proxy si aplica

#### Error: "Folder Not Found"
**Causa**: ID de carpeta incorrecto o carpeta eliminada.
**Solución**:
1. Verifique que la carpeta existe en Google Drive
2. Confirme que tiene permisos de acceso
3. Use "Recuperar ID de Carpeta" para obtener el ID correcto

### Problemas de Permisos

#### Error: "Access Denied"
**Causa**: Permisos insuficientes en Google Drive.
**Solución**:
1. Verifique que tiene permisos de escritura en la carpeta
2. Confirme que la carpeta no está restringida
3. Revise los permisos de compartir en Google Drive

#### Error: "Quota Exceeded"
**Causa**: Límite de almacenamiento de Google Drive alcanzado.
**Solución**:
1. Libere espacio en Google Drive
2. Considere actualizar su plan de almacenamiento
3. Archive archivos antiguos

### Problemas de Rendimiento

#### Carga Lenta de Archivos
**Causa**: Archivos grandes o conexión lenta.
**Solución**:
1. Comprima archivos grandes antes de subir
2. Use conexión de red más rápida
3. Suba archivos en horarios de menor tráfico

#### Tiempo de Respuesta Lento
**Causa**: Muchas carpetas o archivos en la estructura.
**Solución**:
1. Organice archivos en subcarpetas más pequeñas
2. Use filtros para limitar la visualización
3. Archive carpetas antiguas

---

## Preguntas Frecuentes

### General

**P: ¿Puedo usar múltiples cuentas de Google Drive?**
R: Actualmente, la extensión soporta una cuenta de Google Drive por empresa en Business Central.

**P: ¿Los archivos se sincronizan automáticamente?**
R: Los archivos se almacenan directamente en Google Drive. Los cambios realizados en Google Drive se reflejan inmediatamente en Business Central.

**P: ¿Qué pasa si elimino un archivo en Google Drive?**
R: El enlace en Business Central seguirá existiendo, pero el archivo no estará disponible. Se mostrará un error al intentar acceder.

### Seguridad

**P: ¿Es segura la integración?**
R: Sí, utiliza OAuth2 estándar de Google y no almacena credenciales sensibles en Business Central.

**P: ¿Puedo controlar quién accede a los archivos?**
R: Los permisos se gestionan desde Google Drive. Puede configurar permisos específicos para cada carpeta y archivo.

**P: ¿Se pueden auditar las acciones?**
R: Google Drive mantiene un registro de actividad. Business Central registra las acciones en sus logs estándar.

### Técnicas

**P: ¿Hay límites de tamaño de archivo?**
R: Los límites son los mismos que Google Drive (15 GB por archivo para cuentas gratuitas).

**P: ¿Funciona con Business Central On-Premises?**
R: Sí, siempre que tenga conexión a Internet para acceder a Google Drive.

**P: ¿Puedo personalizar la extensión?**
R: Sí, el código fuente está disponible y puede modificarse según sus necesidades específicas.

### Migración

**P: ¿Puedo migrar archivos existentes a Google Drive?**
R: Puede usar las funciones de carga para migrar archivos existentes, pero debe hacerlo manualmente.

**P: ¿Qué pasa si quiero dejar de usar Google Drive?**
R: Puede descargar todos los archivos desde Google Drive y volver al sistema estándar de Business Central.

---

## Mejores Prácticas

### Organización de Carpetas

1. **Estructura Jerárquica Clara**
   - Use una estructura lógica y consistente
   - Evite carpetas demasiado profundas (máximo 5 niveles)
   - Use nombres descriptivos y estándares

2. **Convenciones de Nomenclatura**
   - Establezca convenciones claras para nombres de archivos
   - Use fechas en formato YYYY-MM-DD
   - Incluya identificadores únicos cuando sea necesario

3. **Gestión de Permisos**
   - Configure permisos a nivel de carpeta principal
   - Use grupos de Google para gestionar accesos
   - Revise permisos regularmente

### Configuración de Mapeos

1. **Planificación Previa**
   - Diseñe la estructura de carpetas antes de configurar
   - Considere el crecimiento futuro
   - Documente las decisiones tomadas

2. **Patrones Consistentes**
   - Use patrones similares para tablas relacionadas
   - Evite patrones demasiado complejos
   - Pruebe los patrones antes de implementar

3. **Mantenimiento Regular**
   - Revise y actualice configuraciones periódicamente
   - Archive carpetas antiguas
   - Limpie configuraciones no utilizadas

### Rendimiento

1. **Optimización de Consultas**
   - Limite el número de archivos por carpeta
   - Use subcarpetas para organizar grandes volúmenes
   - Evite consultas innecesarias

2. **Gestión de Cache**
   - Permita que el sistema mantenga tokens en cache
   - No fuerce renovaciones innecesarias
   - Monitoree el uso de la API

### Seguridad

1. **Gestión de Credenciales**
   - Mantenga las credenciales seguras
   - Rote las credenciales regularmente
   - Use cuentas de servicio cuando sea posible

2. **Auditoría**
   - Revise logs de acceso regularmente
   - Monitoree actividad inusual
   - Mantenga registros de cambios de configuración

---

## Soporte y Contacto

### Recursos Adicionales

- **Documentación de Google Drive API**: [developers.google.com/drive](https://developers.google.com/drive)
- **Business Central Documentation**: [docs.microsoft.com/dynamics365/business-central](https://docs.microsoft.com/dynamics365/business-central)
- **OAuth2 Documentation**: [oauth.net/2/](https://oauth.net/2/)

### Información de Versión

- **Versión de la Extensión**: 1.0.0
- **Compatibilidad**: Business Central 18.0+
- **Última Actualización**: 2024
- **Autor**: [Información del desarrollador]

---

*Este manual está sujeto a actualizaciones. Consulte la documentación más reciente para obtener información actualizada sobre nuevas funcionalidades y cambios.* 