function createUploadMarkup() {
    return `
        <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
        <div class="upload-container">
            <div id="drop-zone" class="drop-zone">
                <div id="drop-zone1" class="drop-zone1">
                    <i class='bx bx-arrow-to-top upload-icon'></i>
                    <p class="drop-text">Coloque los archivos para cargar o</p>
                    <input type="file" id="fileInput" multiple class="file-input" accept=".jpg, .jpeg, .bmp, .png, .gif, .tiff, .tif, .pdf, .docx, .doc, .xlsx, .xls, .pptx, .ppt, .msg, .xml">
                    <label for="fileInput" class="upload-link">haga clic aquí para examinar</label>   
                </div>          
                <div id="CopyRight" class="CopyRight">
                    <b class="Malla-CopyRight" align="right">© Malla 2025</b>
                </div>
            </div>
            <div class="file-list-container">
                <div id="file-list" class="file-list"></div>
            </div>
        </div>
        <style>
            .upload-container {
                height: 100%;
                display: flex;
                flex-direction: column;
                padding: 10px;
                font-family: "Segoe UI Semibold", "Segoe WP Semibold", device-segoe-semibold, "Segoe UI", "Segoe WP", Segoe, Tahoma, Helvetica, Arial, sans-serif !important;
            }
            

            .drop-zone {
                width: 97%;
                min-height: 100px;
                border: 2px dashed #00838f;
                border-radius: 4px;
                padding: 25px;
                text-align: center;
                background: #ffffff;
                margin-bottom: 10px;
                display: flex;
                flex-direction: column;
                justify-content: center;
                transition: all 0.2s ease;
                cursor: pointer;
            }

            .drop-zone:hover {
                background: #D9F0F2;
            }

            .drop-zone:hover .upload-link {
                text-decoration: underline;
            }

            .drop-zone p {
                color: #00838f;
                margin-bottom: 1px;
                font-family: "Segoe UI Semibold", "Segoe WP Semibold", device-segoe-semibold, "Segoe UI", "Segoe WP", Segoe, Tahoma, Helvetica, Arial, sans-serif !important;
                font-size: 10pt;
                font-weight: 400;
            }

            .drop-zone.dragover {
                background: #F3F3F3;
                border-color: #00838f;
                transform: scale(1.02);
                box-shadow: 0 4px 12px rgba(67, 97, 238, 0.15);
            }
            
            .file-input {
                display: none;
            }
            .CopyRight {
                text-align: right;
            }
            .CopyRight b {
                color: #99092C;
                font-size: 6pt;
                margin-top: 1px;
                margin-bottom: 1px;
                margin-right: 1px;
            }

            .upload-button {
                display: inline-block;
                padding: 8px 8px;
                background: #4361ee;
                color: white;
                border-radius: 8px;
                cursor: pointer;
                font-weight: 400;
                transition: all 0.2s ease;
                border: none;
                font-size: 10pt;
            }

            .upload-button:hover {
                background: #3451db;
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(67, 97, 238, 0.2);
            }

            .file-list-container {
                flex: 1;
                min-height: 140px;
                max-height: calc(131vh - 300px);
                overflow-y: auto;
                overflow-x: hidden;
                width: 100%;
                background: #ffffff;
                scrollbar-width: thin;
                scrollbar-color: #B2E4E8 #F5FBFC;
            }

            .file-list-container::-webkit-scrollbar {
                width: 8px;
            }

            .file-list-container::-webkit-scrollbar-track {
                background: #F5FBFC;
                border-radius: 4px;
            }

            .file-list-container::-webkit-scrollbar-thumb {
                background-color: #B2E4E8;
                border-radius: 4px;
                border: 2px solid #F5FBFC;
            }

            .file-list-container::-webkit-scrollbar-thumb:hover {
                background-color: #8ED8DE;
            }

            .file-list {
                padding: 10px;
                width: 100%;
            }

            .file-list strong {
                display: block;
                margin-bottom: 10px;
                color: #333;
                font-size: 1.1em;
            }

            .file-item {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 6px 8px;
                font-size: normal !important;
                font-family: "Segoe UI Semibold", "Segoe WP Semibold", device-segoe-semibold, "Segoe UI", "Segoe WP", Segoe, Tahoma, Helvetica, Arial, sans-serif !important;
                color: #00838f;
                background: white;
                border-radius: 4px;
                margin-bottom: 4px;
                transition: all 0.2s ease;
            }

            .file-item:hover {
                transform: translateX(4px);
                box-shadow: 0 2px 4px rgba(0,0,0,0.05);
            }

            .file-item::before {
                margin-right: 8px;
            }

            .delete-button {
                background: none;
                border: none;
                color: #666666;
                font-size: 1.2em;
                cursor: pointer;
                padding: 4px;
                border-radius: 2px;
                transition: all 0.2s ease;
                display: flex;
                align-items: center;
                justify-content: center;
            }

            .delete-button:hover {
                color: #D83B01;
                background-color: #F3F3F3;
            }

            .delete-button i {
                font-size: 18px;
            }

            .file-info {
                display: flex;
                align-items: center;
                gap: 8px;
                flex: 1;
                width: 100%;
            }

            .file-icon {
                font-size: 1.2em;
                min-width: 24px;
                display: flex;
                align-items: center;
                justify-content: center;
                transition: transform 0.2s ease;
                cursor: pointer;
            }

            .file-icon:hover {
                transform: scale(1.2);
            }

            .file-icon i {
                font-size: 24px;
                transition: color 0.2s ease;
            }

            .file-icon:hover i {
                color: #00838f;
            }

            .file-icon.pdf i { color: #e13f2b; }
            .file-icon.word i { color: #2b579a; }
            .file-icon.excel i { color: #217346; }
            .file-icon.powerpoint i { color: #d24726; }
            .file-icon.image i { color: #0078d4; }
            .file-icon.archive i { color: #7e4c00; }
            .file-icon.code i { color: #474747; }
            .file-icon.audio i { color: #107c10; }
            .file-icon.video i { color: #c43e1c; }
            .file-icon.default i { color: #767676; }

            .file-name {
                margin-right: 0;
                color: #00838f;
                font-size: 10pt;
                flex: 1;
            }

            .file-size {
                color: #222222;
                font-size: 10pt;
                margin-left: auto;
                padding-left: 16px;
            }

            .upload-link {
                color: #00838f;
                cursor: pointer;
                text-decoration: none;
                font-size: 10pt;
                font-weight: 400;
                transition: all 0.2s ease;
            }

            .upload-link:hover {
                text-decoration: underline;
                color: #00838f;
            }

            @media (max-width: 768px) {
                .drop-zone {
                    min-height: 100px;
                    padding: 5px;
                }

                .upload-button {
                    padding: 10px 20px;
                    font-size: 0.9em;
                }
            }

            .upload-icon {
                color: #00838f;
                font-size: 20px;
                
            }

            
        </style>
    `;
}

let selectedFiles = [];

function initialize() {
    const controlAddIn = document.getElementById('controlAddIn');
    if (controlAddIn) {
        controlAddIn.innerHTML = createUploadMarkup();
        setupEventListeners();
        // Notificar que el control está listo
        try {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnControlAddInReady');
            console.log('Control inicializado correctamente');
        } catch (error) {
            console.error('Error al inicializar el control:', error);
        }
    }
}

// Configurar los event listeners
function setupEventListeners() {
    const dropZone = document.getElementById('drop-zone');
    const fileInput = document.getElementById('fileInput');

    // Prevenir comportamiento por defecto del navegador
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        dropZone.addEventListener(eventName, preventDefaults, false);
    });

    function preventDefaults(e) {
        e.preventDefault();
        e.stopPropagation();
    }

    // Efectos visuales durante el arrastre
    ['dragenter', 'dragover'].forEach(eventName => {
        dropZone.addEventListener(eventName, () => {
            dropZone.classList.add('dragover');
        });
    });

    ['dragleave', 'drop'].forEach(eventName => {
        dropZone.addEventListener(eventName, () => {
            dropZone.classList.remove('dragover');
        });
    });

    // Manejar la subida de archivos
    dropZone.addEventListener('drop', handleDrop);
    fileInput.addEventListener('change', handleFileSelect);
}

// Procesar los archivos soltados
function handleDrop(e) {
    const dt = e.dataTransfer;
    const files = dt.files;
    handleFiles(files);
}

// Procesar los archivos seleccionados
function handleFileSelect(e) {
    const files = e.target.files;
    handleFiles(files);
}

// Procesar los archivos y convertirlos a base64
function handleFiles(files) {
    const filesArray = Array.from(files);

    Promise.all(filesArray.map(file => {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                const base64String = reader.result.split(',')[1];
                resolve({
                    name: file.name,
                    content: base64String,
                    size: file.size
                });
            };
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }))
    .then(filesData => {
        selectedFiles = selectedFiles.concat(filesData);
        updateFileList();
    })
    .catch(error => {
        console.error('Error processing files:', error);
    });
}

// Nueva función para eliminar archivo
function removeFile(index) {
    selectedFiles.splice(index, 1);
    updateFileList();
}

// Modificar la función updateFileList
function updateFileList() {
    const fileList = document.getElementById('file-list');
    if (!fileList) return;

    if (selectedFiles.length === 0) {
        fileList.innerHTML = '';
        return;
    }

    fileList.innerHTML = '<strong>Archivos seleccionados</strong>' + 
        selectedFiles.map((file, index) => `
            <div class="file-item">
                <div class="file-info">
                    <span class="file-icon">${getFileIcon(file.name)}</span>
                    <span class="file-name">${file.name}</span>
                    <span class="file-size">${formatFileSize(file.size)}</span>
                </div>
                <button class="delete-button" onclick="removeFile(${index})">
                    <i class='bx bxs-eraser' ></i>
                </button>
            </div>
        `).join('');
}

// Añadir función para enviar archivos (llamada desde AL)
function submitFiles() {
    if (selectedFiles.length > 0) {
        try {
            const jsonString = JSON.stringify(selectedFiles);
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("FileUploaded", [jsonString]);
        } catch (error) {
            console.error("Error en submitFiles:", error);
        }
    }
}

// Asegurarnos de que las funciones sean globales
window.submitFiles = submitFiles;
window.removeFile = removeFile;
window.initialize = initialize;

// Modificar la inicialización
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
} else {
    setTimeout(initialize, 100);
}

// Añadir esta función para formatear el tamaño del archivo
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Añadir función para obtener el icono según la extensión
function getFileIcon(fileName) {
    const extension = fileName.split('.').pop().toLowerCase();
    const icons = {
        // Documentos
        'pdf': '<span class="file-icon pdf"><i class="bx bxs-file-pdf"></i></span>',
        'doc': '<span class="file-icon word"><i class="bx bxs-file-doc"></i></span>',
        'docx': '<span class="file-icon word"><i class="bx bxs-file-doc"></i></span>',
        'txt': '<span class="file-icon default"><i class="bx bxs-file-txt"></i></span>',
        // Hojas de cálculo
        'xls': '<span class="file-icon excel"><i class="bx bxs-spreadsheet"></i></span>',
        'xlsx': '<span class="file-icon excel"><i class="bx bxs-spreadsheet"></i></span>',
        'csv': '<span class="file-icon excel"><i class="bx bxs-spreadsheet"></i></span>',
        // Presentaciones
        'ppt': '<span class="file-icon powerpoint"><i class="bx bxs-slideshow"></i></span>',
        'pptx': '<span class="file-icon powerpoint"><i class="bx bxs-slideshow"></i></span>',
        // Imágenes
        'jpg': '<span class="file-icon image"><i class="bx bxs-image"></i></span>',
        'jpeg': '<span class="file-icon image"><i class="bx bxs-image"></i></span>',
        'png': '<span class="file-icon image"><i class="bx bxs-image"></i></span>',
        'gif': '<span class="file-icon image"><i class="bx bxs-image"></i></span>',
        'bmp': '<span class="file-icon image"><i class="bx bxs-image"></i></span>',
        // Comprimidos
        'zip': '<span class="file-icon archive"><i class="bx bxs-file-archive"></i></span>',
        'rar': '<span class="file-icon archive"><i class="bx bxs-file-archive"></i></span>',
        '7z': '<span class="file-icon archive"><i class="bx bxs-file-archive"></i></span>',
        // Código
        'json': '<span class="file-icon code"><i class="bx bxs-file-json"></i></span>',
        'xml': '<span class="file-icon code"><i class="bx bxs-file-html"></i></span>',
        'html': '<span class="file-icon code"><i class="bx bxs-file-html"></i></span>',
        'js': '<span class="file-icon code"><i class="bx bxs-file-js"></i></span>',
        'css': '<span class="file-icon code"><i class="bx bxs-file-css"></i></span>',
        // Audio/Video
        'mp3': '<span class="file-icon audio"><i class="bx bxs-music"></i></span>',
        'wav': '<span class="file-icon audio"><i class="bx bxs-music"></i></span>',
        'mp4': '<span class="file-icon video"><i class="bx bxs-video"></i></span>',
        'avi': '<span class="file-icon video"><i class="bx bxs-video"></i></span>',
        'mov': '<span class="file-icon video"><i class="bx bxs-video"></i></span>'
    };
    return icons[extension] || '<span class="file-icon default"><i class="bx bxs-file"></i></span>';
}
