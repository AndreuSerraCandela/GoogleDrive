# Manual: Configurar OneDrive en Business Central

Guía rápida para conectar **OneDrive / SharePoint** con la extensión de almacenamiento (E&A GoogleDrive).

---

## 1. Requisitos previos

- Acceso al **Azure Portal** (App Registration).
- Permisos de administrador en Business Central.
- Extensión publicada con el campo **OneDrive Code** como Blob (para que el código OAuth quepa completo).

---

## 2. Configurar la aplicación en Azure Portal

### 2.1 Crear o abrir la App Registration

1. Entra en [Azure Portal](https://portal.azure.com) → **Microsoft Entra ID** → **App registrations**.
2. Abre tu aplicación (o crea una nueva).
3. Anota estos valores (los necesitarás en BC):

| Campo en Azure | Campo en Business Central |
|----------------|---------------------------|
| Application (client) ID | **ID de Cliente de OneDrive** |
| Directory (tenant) ID | **ID del Inquilino de OneDrive** |
| Client secret (Valor) | **Secreto de Cliente de OneDrive** |

> Importante: copia el **Valor** del secreto, no el *Secret ID*.

### 2.2 Redirect URI (URI de redirección)

1. Ve a **Authentication** → **Add a platform**.
2. Elige **Mobile and desktop applications** (recomendado).
3. Añade o marca:

```text
https://login.microsoftonline.com/common/oauth2/nativeclient
```

4. Opcional: activa **Allow public client flows** = **Yes**.

> Si `nativeclient` está solo en plataforma **Web**, también puede funcionar, pero es más correcto en **Mobile and desktop**.

### 2.3 Permisos de API (Microsoft Graph)

En **API permissions** → **Add a permission** → **Microsoft Graph** → **Delegated**:

| Permiso | Para qué sirve |
|---------|----------------|
| `Files.ReadWrite.All` | Leer y escribir archivos |
| `offline_access` | Obtener refresh token |

Pulsa **Grant admin consent** (consentimiento de administrador) si tu tenant lo exige.

---

## 3. Configurar OneDrive en Business Central

1. Abre **Información de la empresa**.
2. Acción **Configuración de almacenamiento** (Storage Configuration).
3. En **Proveedor de almacenamiento de Datos**, elige **OneDrive**.
4. Rellena:

| Campo | Valor |
|-------|--------|
| ID de Cliente de OneDrive | Application (client) ID de Azure |
| Secreto de Cliente de OneDrive | Valor del client secret |
| ID del Inquilino de OneDrive | Directory (tenant) ID |
| URL de API de OneDrive | `https://graph.microsoft.com/v1.0` (por defecto) |

5. Si usas un **sitio de SharePoint** (recomendado para empresas):

| Campo | Ejemplo |
|-------|---------|
| URL del Sitio de OneDrive | `mallapalma.sharepoint.com:/sites/Prueba` |
| ID del Sitio de OneDrive | Se obtiene con la acción **Id Site** |

6. Guarda.

---

## 4. Obtener el token (OAuth)

### Paso A – Iniciar OAuth

1. En la página **Configuración de almacenamiento**, con proveedor **OneDrive**.
2. Pulsa **Start OAuth** (grupo OneDrive).
3. Inicia sesión con la cuenta de Microsoft / Entra ID.
4. Acepta los permisos solicitados.

### Paso B – “Capturar” el código (code)

Tras aceptar, el navegador te lleva a una página con un aviso tipo:

> *Por lo general, esta página no se muestra… podría ser un signo de phishing…*

**Eso es normal.** Significa que el login ha funcionado. El código está en la **barra de direcciones**.

#### Ejemplo de URL

```text
https://login.microsoftonline.com/common/oauth2/nativeclient?code=1.AU4AcATtLEaDJE-X2uwCnVbZg...LvXBiCKM&state=12345&session_state=006b4cda-...
```

#### Qué copiar

Copia **solo** lo que va entre `code=` y `&state=` (sin incluir `code=` ni `&state=`):

```text
1.AU4AcATtLEaDJE-X2uwCnVbZg...LvXBiCKM
```

#### Qué NO copiar

| Incorrecto | Motivo |
|------------|--------|
| La URL completa | Incluye `state` y otros parámetros |
| `code=1.AU4Ac...` | No debe llevar el prefijo `code=` |
| `...CKM&state=12345` | No debe incluir `&state` ni lo posterior |
| Código de Postman (`oauth.pstmn.io`) | Redirect distinto; fallará el canje |

#### Cómo pegarlo en Business Central

1. Vuelve a **Configuración de almacenamiento**.
2. En el campo **OneDrive Code** (multilínea), pega el código completo.
3. Comprueba que **termina igual** que en el navegador (por ejemplo `...LvXBiCKM`).
4. Si se corta a mitad, no publiques un campo corto: debe ser Blob (ya corregido en la extensión).

> El código caduca en pocos minutos y **solo sirve una vez**. Pégalo y canjéalo enseguida.

### Paso C – Canjear el código por token

1. Pulsa **Get Token** del grupo **OneDrive**  
   (no uses “Obtener token” de Google Drive).
2. Si todo va bien, verás un mensaje de éxito.
3. El campo **OneDrive Code** se limpia (el code ya no hace falta).
4. Deberían rellenarse **Token de Acceso** y **Token de Renovación** (internos).

---

## 5. Comprobar que está bien configurado

Usa estas acciones del grupo **OneDrive**:

| Acción | Qué comprueba |
|--------|----------------|
| **Validate Configuration** | Credenciales, tokens, caducidad, sitio |
| **Test Token Validity** | Si el access token sigue vigente por fecha |
| **Test Connection** | Llamada real a Microsoft Graph (`/me/drive` o drive del sitio) |
| **Id Site** | Rellena el Site ID a partir de la URL del sitio |

Orden recomendado tras Get Token:

1. **Validate Configuration**
2. **Test Connection**
3. Si usas sitio SharePoint: **Id Site** → otra vez **Test Connection**
4. Opcional: **Crea Root** para crear/asignar carpeta raíz

---

## 6. Flujo resumido (checklist)

```text
Azure App Registration
  ├─ Client ID / Tenant ID / Client Secret
  ├─ Redirect: https://login.microsoftonline.com/common/oauth2/nativeclient
  └─ Permisos Graph: Files.ReadWrite.All + offline_access (+ admin consent)

Business Central
  ├─ Proveedor = OneDrive
  ├─ Pegar Client ID, Secret, Tenant ID
  ├─ Start OAuth
  ├─ Copiar code=... (hasta antes de &state=)
  ├─ Pegar en OneDrive Code (completo)
  ├─ Get Token (OneDrive)
  ├─ Validate Configuration
  └─ Test Connection
```

---

## 7. Errores frecuentes

| Error | Causa | Solución |
|-------|--------|----------|
| `invalid_grant` + redirect `pstmn.io` vs `nativeclient` | Code obtenido con Postman | Usar solo **Start OAuth** de BC |
| `invalid_grant` / `AADSTS9002313` | Code truncado, caducado o mal pegado | Pegar code completo (Blob), code nuevo, solo valor de `code=` |
| Página “phishing” en `nativeclient` | Comportamiento normal | Copiar el `code` de la URL y continuar |
| `invalid_client` | Client ID/Secret incorrectos o secret caducado | Revisar secret en Azure |
| Get Token de Google con proveedor OneDrive | Botón equivocado | Usar **Get Token** del grupo OneDrive |
| Test Connection falla sin token | Aún no hay access token | Completar Start OAuth → Get Token primero |

---

## 8. Seguridad

- No compartas URLs con `code=` (el código es sensible).
- No pegues el code en chats o tickets.
- El client secret debe tratarse como contraseña.
- Tras un Get Token correcto, el code se borra de la configuración.

---

## 9. Mantenimiento

- El **access token** caduca (normalmente ~1 hora). La extensión puede renovarlo con el **refresh token** (**Refresh Token**).
- Si el refresh token deja de valer (revocación, cambio de secret, etc.), vuelve a ejecutar **Start OAuth** + **Get Token**.
