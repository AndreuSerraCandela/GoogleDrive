# Document Attachment Upload API

Endpoint para adjuntar archivos a registros de Business Central (pedidos, facturas, clientes, etc.) enviando un JSON con el contenido en Base64. El archivo se sube al drive configurado (Google Drive, OneDrive, DropBox, etc.).

## Requisitos

1. **Publicar el Web Service** en Business Central:
   - Ir a **Web Services** (buscar "Web Services" o Configuración).
   - **New** → Object Type: **Codeunit**, Object ID: **95101** ("Doc. Attachment Mgmt. GDrive").
   - Marcar **Published** y guardar.
   - Anotar la **URL** del servicio (ej. `https://api.businesscentral.dynamics.com/v2.0/{tenant}/{environment}/ODataV4/...`).

2. **Autenticación**: necesitas un **access token** (OAuth2) válido de Microsoft/BC. En entornos SaaS suele obtenerse vía Azure AD.

---

## Contrato del JSON

| Campo           | Tipo    | Obligatorio | Descripción |
|-----------------|---------|-------------|-------------|
| `base64Content` | string  | Sí          | Contenido del archivo codificado en Base64. |
| `tableId`       | integer | Sí          | ID de la tabla (ej. 36 = Sales Header, 112 = Sales Invoice Header, 18 = Customer). |
| `no`            | string  | Sí          | Número/código del registro (ej. "ORD-001", "10000"). |
| `fileName`      | string  | Sí          | Nombre del archivo con extensión (ej. "document.pdf"). |
| `documentType`  | integer | Sí          | Tipo de documento cuando aplica (Sales/Purchase Header: 1=Order, 2=Invoice...). Usar **0** si la tabla no tiene tipo. |

### Tablas habituales (tableId)

| tableId | Tabla |
|--------|--------|
| 36 | Sales Header |
| 38 | Purchase Header |
| 112 | Sales Invoice Header |
| 114 | Sales Cr.Memo Header |
| 122 | Purch. Inv. Header |
| 124 | Purch. Cr. Memo Hdr. |
| 18 | Customer |
| 23 | Vendor |
| 5050 | Contact |
| 27 | Item |
| 15 | G/L Account |

### documentType (Sales Header 36 / Purchase Header 38)

- 0 = Blank  
- 1 = Order  
- 2 = Invoice  
- 3 = Credit Memo  
- 4 = Quote  
- 5 = Open Order  
- 6 = Open Invoice  

---

## Uso con Postman

### 1. Crear la petición

- **Method:** `POST`
- **URL:**  
  `{baseUrl}/ODataV4/DocAttachmentMgmtGDrive_UploadAttachment?company={companyNameOrId}`

  Ejemplo:
  ```text
  https://api.businesscentral.dynamics.com/v2.0/12345678-1234-1234-1234-123456789012/production/ODataV4/DocAttachmentMgmtGDrive_UploadAttachment?company=CRONUS%20USA%20Inc.
  ```

  Sustituir:
  - `{baseUrl}`: URL base de tu entorno BC (tenant + environment).
  - `company`: nombre de la empresa codificado en URL (espacios como `%20`) o GUID de la empresa.

### 2. Headers

| Key             | Value              |
|-----------------|--------------------|
| `Content-Type`  | `application/json` |
| `Authorization` | `Bearer {tu_access_token}` |

### 3. Body

Seleccionar **raw** y **JSON**, y usar un body como:

```json
{
  "base64Content": "JVBERi0xLjQKJeLjz9MKMSAwIG9iago8PAovVHlwZSAvQ2F0YWxvZwovUGFnZXMgMiAwIFIKPj4KZW5kb2JqCjIgMCBvYmoKPDwKL1R5cGUgL1BhZ2VzCi9LaWRzIFszIDAgUl0KL0NvdW50IDEKL01lZGlhQm94IFswIDAgNTk1IDg0Ml0KPj4KZW5kb2JqCjMgMCBvYmoKPDwKL1R5cGUgL1BhZ2UKL1BhcmVudCAyIDAgUgovQ29udGVudHMgNCAwIFIKPj4KZW5kb2JqCjQgMCBvYmoKPDwKL0xlbmd0aCA0NAo+PgpzdHJlYW0KQlQKL0YxIDEyIFRmCjEwMCA3MDAgVGQKKEhpKSBUagpFVAplbmRzdHJlYW0KZW5kb2JqCnhyZWYKMCA1CjAwMDAwMDAwMDAgNjU1MzUgZiAKMDAwMDAwMDAwOSAwMDAwMCBuIAowMDAwMDAwMDc4IDAwMDAwIG4gCjAwMDAwMDAxNjcgMDAwMDAgbiAKMDAwMDAwMDI0OCAwMDAwMCBuIAp0cmFpbGVyCjw8Ci9TaXplIDUKL1Jvb3QgMSAwIFIKPj4Kc3RhcnR4cmVmCjM0MQolJUVPRgo=",
  "tableId": 36,
  "no": "ORD-001",
  "fileName": "attachment.pdf",
  "documentType": 1
}
```

### 4. Respuesta esperada

- **200 OK** con body similar a:
  ```json
  {
    "@odata.context": "https://...",
    "value": true
  }
  ```
  Indica que el adjunto se creó y se subió al drive.

- **4xx/5xx**: Error (registro no encontrado, tabla no soportada, token inválido, etc.). El body suele incluir el mensaje de error.

### 5. Variables en Postman (opcional)

Puedes definir variables de entorno:

- `bc_base_url`: URL base del OData (sin el path del codeunit).
- `bc_company`: Nombre o ID de la empresa.
- `bc_token`: Access token (renovado manualmente o por script).

URL en Postman:
```text
{{bc_base_url}}/ODataV4/DocAttachmentMgmtGDrive_UploadAttachment?company={{bc_company}}
```

Header:
```text
Authorization: Bearer {{bc_token}}
```

---

## Uso con JavaScript

### Requisitos

- Tener una función o flujo que obtenga el **access token** de BC (OAuth2 con Azure AD / Microsoft Identity). No se incluye aquí la lógica de login.

### Ejemplo con `fetch`

```javascript
const BC_BASE_URL = 'https://api.businesscentral.dynamics.com/v2.0/{tenant-id}/{environment}';
const COMPANY = 'CRONUS USA Inc.'; // o el ID de empresa

async function uploadDocumentAttachment(accessToken, fileBase64, tableId, no, fileName, documentType = 0) {
  const url = `${BC_BASE_URL}/ODataV4/DocAttachmentMgmtGDrive_UploadAttachment?company=${encodeURIComponent(COMPANY)}`;

  const body = {
    base64Content: fileBase64,
    tableId: tableId,
    no: no,
    fileName: fileName,
    documentType: documentType
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`
    },
    body: JSON.stringify(body)
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`BC API error ${response.status}: ${errorText}`);
  }

  const data = await response.json();
  return data.value; // true si OK
}

// Ejemplo: adjuntar un PDF a un pedido de venta
(async () => {
  const token = 'YOUR_ACCESS_TOKEN';
  const pdfBase64 = 'JVBERi0xLjQK...'; // contenido del PDF en Base64

  try {
    const ok = await uploadDocumentAttachment(
      token,
      pdfBase64,
      36,           // Sales Header
      'ORD-001',    // número del pedido
      'contrato.pdf',
      1             // Order
    );
    console.log('Upload success:', ok);
  } catch (err) {
    console.error('Upload failed:', err.message);
  }
})();
```

### Convertir un File (input o drag & drop) a Base64

```javascript
function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => {
      // Quitar el prefijo "data:application/pdf;base64," si lo hay
      const base64 = reader.result.split(',')[1] || reader.result;
      resolve(base64);
    };
    reader.onerror = () => reject(reader.error);
  });
}

// Uso con <input type="file">
document.querySelector('input[type="file"]').addEventListener('change', async (e) => {
  const file = e.target.files[0];
  if (!file) return;
  const base64 = await fileToBase64(file);
  const token = 'YOUR_ACCESS_TOKEN';
  await uploadDocumentAttachment(token, base64, 36, 'ORD-001', file.name, 1);
});
```

### Ejemplo con Axios

```javascript
const axios = require('axios');

async function uploadAttachment(accessToken, base64Content, tableId, no, fileName, documentType = 0) {
  const url = `${BC_BASE_URL}/ODataV4/DocAttachmentMgmtGDrive_UploadAttachment`;
  const { data } = await axios.post(url, {
    base64Content: base64Content,
    tableId: tableId,
    no: no,
    fileName: fileName,
    documentType: documentType
  }, {
    params: { company: COMPANY },
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`
    }
  });
  return data.value;
}
```

---

## Resumen rápido

| Dónde   | Qué hacer |
|--------|-----------|
| Postman | POST a `.../ODataV4/DocAttachmentMgmtGDrive_UploadAttachment?company=...` con header `Authorization: Bearer {token}` y body JSON con `base64Content`, `tableId`, `no`, `fileName`, `documentType`. |
| JavaScript | `fetch` o `axios` POST al mismo URL, mismo body y mismo header; manejar respuesta y errores. |
| Base64   | En JS puedes usar `FileReader.readAsDataURL()` y quitar el prefijo `data:...;base64,` para obtener solo la cadena Base64. |
