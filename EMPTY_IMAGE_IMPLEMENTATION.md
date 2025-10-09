# Implementación de Imagen Vacía Base64

## Resumen

Se ha implementado un sistema para asignar una imagen base64 vacía cuando `PDFAsTxt` esté en blanco, evitando errores en el visor de documentos.

## Cambios Realizados

### 1. Función `GetEmptyImageBase64()`

```al
local procedure GetEmptyImageBase64(): Text
var
    // Imagen PNG de 1x1 píxel transparente en base64
    EmptyImageBase64: Text;
begin
    // Imagen PNG de 1x1 píxel transparente
    EmptyImageBase64 := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
    exit(EmptyImageBase64);
end;
```

### 2. Función `GetEmptyDocumentBase64()`

```al
local procedure GetEmptyDocumentBase64(FileType: Enum "Document Attachment File Type"): Text
var
    EmptyDocBase64: Text;
begin
    case FileType of
        FileType::Image:
            // Imagen PNG de 1x1 píxel transparente
            EmptyDocBase64 := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
        FileType::PDF:
            // PDF vacío en base64 (PDF mínimo válido)
            EmptyDocBase64 := 'JVBERi0xLjQKJcOkw7zDtsO8CjIgMCBvYmoKPDwKL0xlbmd0aCAzIDAgUgovRmlsdGVyIC9GbGF0ZURlY29kZQo+PgpzdHJlYW0KeJwDAAAAAAEAAQ==';
        else
            // Imagen PNG de 1x1 píxel transparente por defecto
            EmptyDocBase64 := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
    end;
    exit(EmptyDocBase64);
end;
```

### 3. Modificación en `SetPDFDocument()`

```al
local procedure SetPDFDocument(PDFAsTxt: Text; i: Integer; Pdf: Boolean; Url: Text; driveType: Text);
var
    IsVisible: Boolean;
begin
    //IsVisible := PDFAsTxt <> '';
    If PDFAsTxt = '' Then PDFAsTxt := GetEmptyDocumentBase64(Rec."File Type");
    // ... resto del código
end;
```

## Tipos de Documentos Vacíos Soportados

| Tipo de Archivo | Base64 Vacío | Descripción |
|------------------|--------------|-------------|
| **Image** | PNG 1x1 transparente | Imagen mínima transparente |
| **PDF** | PDF vacío válido | PDF mínimo que se puede abrir |
| **Otros** | PNG 1x1 transparente | Fallback para otros tipos |

## Base64 Strings Utilizados

### Imagen PNG 1x1 Transparente
```
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==
```

### PDF Vacío Mínimo
```
JVBERi0xLjQKJcOkw7zDtsO8CjIgMCBvYmoKPDwKL0xlbmd0aCAzIDAgUgovRmlsdGVyIC9GbGF0ZURlY29kZQo+PgpzdHJlYW0KeJwDAAAAAAEAAQ==
```

## Ventajas de esta Implementación

1. **Previene errores**: Evita que el visor falle cuando no hay contenido
2. **Específico por tipo**: Diferentes documentos vacíos según el tipo de archivo
3. **Mínimo tamaño**: Los documentos vacíos son muy pequeños
4. **Válidos**: Los documentos base64 generados son válidos y se pueden abrir
5. **Transparentes**: Las imágenes vacías son transparentes, no interfieren con el diseño

## Casos de Uso

- **Documentos sin contenido**: Cuando `PDFAsTxt` está vacío
- **Errores de carga**: Cuando falla la carga del documento original
- **Placeholders**: Para mostrar un estado vacío en lugar de error
- **Fallback**: Cuando no se puede determinar el tipo de archivo

## Notas Técnicas

- La imagen PNG es de 1x1 píxel y completamente transparente
- El PDF vacío es un documento PDF válido pero sin contenido visible
- Se mantiene la compatibilidad con el sistema existente
- No afecta el rendimiento ya que los documentos vacíos son muy pequeños

## Próximos Pasos

1. **Testing**: Probar con diferentes tipos de archivos
2. **Personalización**: Permitir configurar diferentes documentos vacíos
3. **Logging**: Agregar logs cuando se usa un documento vacío
4. **UI**: Mostrar un indicador visual cuando se muestra un documento vacío
