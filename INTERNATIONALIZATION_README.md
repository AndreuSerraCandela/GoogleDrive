# Implementación de Internacionalización para Control Add-In

## Resumen

Este documento explica cómo se ha implementado la internacionalización en el control add-in para que los textos se muestren en el idioma configurado en Business Central.

## Cambios Realizados

### 1. Control Add-In (AL)

Se modificó el archivo `src/ControlAdin/controladdin Ocr.al` para agregar un parámetro de idioma:

```al
procedure InitializeControl(url: Text; language: Text);
```

### 2. JavaScript (script.js)

Se implementó un sistema de traducciones con:

- **Variable global**: `currentLanguage` para almacenar el idioma actual
- **Función auxiliar**: `getTranslation(key)` para obtener traducciones
- **Traducciones incluidas**: Inglés (en-US) y Español (es-ES)

#### Traducciones Disponibles

| Clave | Inglés | Español |
|-------|--------|---------|
| `upload-title` | Upload Files | Cargar Archivos |
| `show-button` | Show | Mostrar |
| `hide-button` | Hide | Ocultar |
| `drop-zone-text` | Drop files here to upload or | Coloque los archivos aquí para cargar o |
| `click-to-browse` | click here to browse | haga clic aquí para examinar |
| `file-count-prefix` | Files: | Arch: |

### 3. Archivos de Traducción

Se crearon archivos XLF para mantener las traducciones organizadas:
- `src/Translations/ControlAddInTranslations.g.xlf` (idioma base)
- `src/Translations/ControlAddInTranslations.es-ES.xlf` (español)

## Cómo Usar

### Desde Business Central

```al
// En tu página o control add-in
usercontrol(ControlAddIn; "OcrFirmas")
{
    ApplicationArea = All;
    
    trigger OnControlAddInReady()
    begin
        // Obtener el idioma actual del usuario
        CurrentLanguage := GetCurrentLanguage();
        
        // Inicializar el control add-in con el idioma
        ControlAddIn.InitializeControl('', CurrentLanguage);
    end;
}

local procedure GetCurrentLanguage(): Text
var
    UserPersonalization: Record "User Personalization";
    Language: Record Language;
begin
    // Intentar obtener el idioma del usuario
    if UserPersonalization.Get(UserId) then begin
        if Language.Get(UserPersonalization."Language ID") then
            exit(Language."Language Code");
    end;
    
    // Fallback al inglés
    exit('en-US');
end;
```

### Agregar Nuevos Idiomas

1. **Crear archivo de traducción**: Copiar `ControlAddInTranslations.g.xlf` y cambiar el `target-language`
2. **Agregar traducciones**: Añadir las traducciones en el archivo XLF
3. **Actualizar JavaScript**: Agregar el nuevo idioma en la función `getTranslation()`

#### Ejemplo para Francés:

```javascript
'fr-FR': {
    'upload-title': 'Télécharger des fichiers',
    'show-button': 'Afficher',
    'hide-button': 'Masquer',
    'drop-zone-text': 'Déposez les fichiers ici pour les télécharger ou',
    'click-to-browse': 'cliquez ici pour parcourir',
    'file-count-prefix': 'Fichiers:'
}
```

## Ventajas de esta Implementación

1. **Centralizada**: Todas las traducciones están en un solo lugar
2. **Fácil mantenimiento**: Agregar nuevos idiomas es sencillo
3. **Fallback automático**: Si no existe una traducción, usa inglés por defecto
4. **Integración con BC**: Respeta el idioma configurado en Business Central
5. **Escalable**: Fácil agregar más idiomas en el futuro

## Notas Importantes

- El idioma se debe pasar desde Business Central al inicializar el control add-in
- Las traducciones se cargan dinámicamente según el idioma recibido
- Se mantiene compatibilidad con versiones anteriores (idioma por defecto: inglés)
- Los archivos XLF siguen el estándar de Business Central para traducciones

## Próximos Pasos

1. **Implementar en páginas existentes**: Modificar las páginas que usan este control add-in
2. **Agregar más idiomas**: Según las necesidades de los usuarios
3. **Automatizar**: Crear un proceso para detectar automáticamente el idioma del usuario
4. **Testing**: Probar con diferentes configuraciones de idioma

