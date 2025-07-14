var pdfDoc = null,
    pdfDocPrint = null,
    pageNum = 1,
    pageRendering = false,
    pageNumPending = null,
    IsFirstLoad = true;
    selectedFiles = [];

function InitializeControl(controlId) {
    var controlAddIn = document.getElementById(controlId);
    controlAddIn.innerHTML =
        '<div id="pdf-contents">' +
            '<div id="pdf-meta">' +
                '<div id="pdf-buttons">' +
                    '<button id="prev" class="button-style"><i class="fas fa-arrow-left"></i></button>' +
                    '<button id="next"class="button-style"><i class="fas fa-arrow-right"></i></button>' +
                    '<button id="pdf-view" class="button-style"><i class="fas fa-search-plus"></i></button>' +
                    '<button id="Download" class="button-style"><i class="fas fa-cloud-download-alt"></i></i></button>' +
                    '<button id="Imprimir" class="button-style"><i class="fas fa-print"></i></i></button>' +
                    '<button id="Anterior" class="button-style"><i class="fas fa-fast-backward"></i></i></button>' +
                    '<button id="Siguiente" class="button-style"><i class="fas fa-fast-forward"></i></i></button>' +
                    '<span id="page-count-container">' +
                        '<span id="page_num"></span>' +
                        '<span id="page_count"></span>' +
                    '</span>' +
                '</div>' +
            '</div>' +
            // Área de carga de archivos
            '<div id="upload-section" style="background: #f8f9fa; padding: 10px; border-bottom: 1px solid #dee2e6; margin-bottom: 10px;">' +
                '<div class="upload-container">' +
                    '<div class="upload-section-header">' +
                        '<h3 class="upload-title">Cargar Archivos</h3>' +
                        '<button class="toggle-upload-btn" onclick="toggleUploadSection()">' +
                            '<i class="fas fa-chevron-up"></i> Ocultar' +
                        '</button>' +
                    '</div>' +
                    '<div id="upload-content">' +
                        '<div id="drop-zone" class="drop-zone">' +
                            '<i class="fas fa-cloud-upload-alt upload-icon"></i>' +
                            '<p>Coloque los archivos aquí para cargar o</p>' +
                            '<input type="file" id="fileInput" multiple class="file-input" accept=".jpg, .jpeg, .bmp, .png, .gif, .tiff, .tif, .pdf, .docx, .doc, .xlsx, .xls, .pptx, .ppt, .msg, .xml">' +
                            '<label for="fileInput" class="upload-link">haga clic aquí para examinar</label>' +
                        '</div>' +
                        '<div id="file-list-container" class="file-list-container">' +
                            '<div id="file-list" class="file-list"></div>' +
                        '</div>' +
                    '</div>' +
                '</div>' +
            '</div>' +
            '<div class="loading-indicator">' +
                '<div class="spinner"></div>' +
            '</div>' +
            '<canvas id="the-canvas"></canvas>' +
            '<div id="iframe-container"></div>' +
            '<div id="file-count-content">' +
                '<span id="file-count-container">Arch: ' +
                    '<span id="file_num"></span> / ' +
                    '<span id="file_count"></span>' +
                '</span>' +
            '</div>' +
        '</div>' +
        '<style>' +
            '.upload-container {' +
                'background: white;' +
                'border-radius: 8px;' +
                'box-shadow: 0 2px 8px rgba(0,0,0,0.1);' +
                'padding: 15px;' +
                'width: 95%;' +
                'max-width: 95%;' +
            '}' +
            '.drop-zone {' +
                'width: 90%;' +
                'min-height: 80px;' +
                'border: 2px dashed #00838f;' +
                'border-radius: 6px;' +
                'padding: 15px;' +
                'text-align: center;' +
                'background: #ffffff;' +
                'margin-bottom: 10px;' +
                'display: flex;' +
                'flex-direction: column;' +
                'justify-content: center;' +
                'align-items: center;' +
                'transition: all 0.3s ease;' +
                'cursor: pointer;' +
                'position: relative;' +
            '}' +
            '.drop-zone:hover {' +
                'background: #D9F0F2;' +
                'border-color: #006d75;' +
            '}' +
            '.drop-zone.dragover {' +
                'background: #F3F3F3;' +
                'border-color: #00838f;' +
                'transform: scale(1.02);' +
                'box-shadow: 0 4px 12px rgba(0, 131, 143, 0.2);' +
            '}' +
            '.drop-zone p {' +
                'color: #00838f;' +
                'margin: 3px 0;' +
                'font-size: 11pt;' +
                'font-weight: 400;' +
            '}' +
            '.file-input {' +
                'display: none;' +
            '}' +
            '.upload-link {' +
                'color: #00838f;' +
                'cursor: pointer;' +
                'text-decoration: none;' +
                'font-size: 11pt;' +
                'font-weight: 500;' +
                'padding: 5px 10px;' +
                'border-radius: 4px;' +
                'transition: all 0.2s ease;' +
            '}' +
            '.upload-link:hover {' +
                'text-decoration: underline;' +
                'background: #e3f2fd;' +
            '}' +
            '.upload-icon {' +
                'color: #00838f;' +
                'font-size: 24px;' +
                'margin-bottom: 8px;' +
            '}' +
            '.file-list-container {' +
                'max-height: 150px;' +
                'overflow-y: auto;' +
                'background: #ffffff;' +
                'border-radius: 6px;' +
                'margin-top: 10px;' +
                'border: 1px solid #e9ecef;' +
            '}' +
            '.file-list {' +
                'padding: 8px;' +
            '}' +
            '.file-list strong {' +
                'display: block;' +
                'margin-bottom: 6px;' +
                'color: #333;' +
                'font-size: 11pt;' +
                'font-weight: 600;' +
            '}' +
            '.file-item {' +
                'display: flex;' +
                'justify-content: space-between;' +
                'align-items: center;' +
                'padding: 6px 8px;' +
                'font-size: 10pt;' +
                'color: #00838f;' +
                'background: #f8f9fa;' +
                'border-radius: 4px;' +
                'margin-bottom: 4px;' +
                'transition: all 0.2s ease;' +
                'border: 1px solid #e9ecef;' +
            '}' +
            '.file-item:hover {' +
                'background: #e9ecef;' +
                'transform: translateX(2px);' +
            '}' +
            '.delete-button {' +
                'background: none;' +
                'border: none;' +
                'color: #666666;' +
                'font-size: 1.1em;' +
                'cursor: pointer;' +
                'padding: 4px;' +
                'border-radius: 3px;' +
                'transition: all 0.2s ease;' +
            '}' +
            '.delete-button:hover {' +
                'color: #D83B01;' +
                'background-color: #F3F3F3;' +
            '}' +
            '.file-info {' +
                'display: flex;' +
                'align-items: center;' +
                'gap: 8px;' +
                'flex: 1;' +
            '}' +
            '.file-icon {' +
                'font-size: 1.1em;' +
                'min-width: 20px;' +
            '}' +
            '.file-name {' +
                'color: #00838f;' +
                'font-size: 10pt;' +
                'flex: 1;' +
                'overflow: hidden;' +
                'text-overflow: ellipsis;' +
                'white-space: nowrap;' +
            '}' +
            '.file-size {' +
                'color: #222222;' +
                'font-size: 9pt;' +
                'margin-left: 10px;' +
                'font-weight: 500;' +
            '}' +
            '.upload-section-header {' +
                'display: flex;' +
                'justify-content: space-between;' +
                'align-items: center;' +
                'margin-bottom: 10px;' +
            '}' +
            '.upload-title {' +
                'color: #00838f;' +
                'font-size: 12pt;' +
                'font-weight: 600;' +
                'margin: 0;' +
            '}' +
            '.toggle-upload-btn {' +
                'background: #00838f;' +
                'color: white;' +
                'border: none;' +
                'border-radius: 4px;' +
                'padding: 6px 12px;' +
                'cursor: pointer;' +
                'font-size: 10pt;' +
                'transition: all 0.2s ease;' +
            '}' +
            '.toggle-upload-btn:hover {' +
                'background: #006d75;' +
            '}' +
            '.file-icon.pdf i { color: #e13f2b; }' +
            '.file-icon.word i { color: #2b579a; }' +
            '.file-icon.excel i { color: #217346; }' +
            '.file-icon.powerpoint i { color: #d24726; }' +
            '.file-icon.image i { color: #0078d4; }' +
            '.file-icon.archive i { color: #7e4c00; }' +
            '.file-icon.code i { color: #474747; }' +
            '.file-icon.audio i { color: #107c10; }' +
            '.file-icon.video i { color: #c43e1c; }' +
            '.file-icon.default i { color: #767676; }' +
        '</style>';
    // Configurar los event listeners para la carga
    setupUploadEventListeners();
}
function toggleUploadSection() {
    const uploadSection = document.getElementById('upload-section');
    const uploadContent = document.getElementById('upload-content');
    const toggleBtn = document.querySelector('.toggle-upload-btn');
    
    if (uploadContent.style.display === 'none') {
        uploadContent.style.display = 'block';
        uploadSection.style.minHeight = '120px';
        toggleBtn.innerHTML = '<i class="fas fa-chevron-up"></i> Ocultar';
    } else {
        uploadContent.style.display = 'none';
        uploadSection.style.minHeight = '40px';
        toggleBtn.innerHTML = '<i class="fas fa-chevron-down"></i> Mostrar';
    }
}

function setupUploadEventListeners() {
    const dropZone = document.getElementById('drop-zone');
    const fileInput = document.getElementById('fileInput');

    if (!dropZone || !fileInput) return;

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

function handleDrop(e) {
    const dt = e.dataTransfer;
    const files = dt.files;
    handleFiles(files);
}

function handleFileSelect(e) {
    const files = e.target.files;
    handleFiles(files);
}

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
        
        // Enviar archivos automáticamente después de procesarlos
        setTimeout(() => {
            submitFiles();
        }, 500);
    })
    .catch(error => {
        console.error('Error processing files:', error);
    });
}

function removeFile(index) {
    selectedFiles.splice(index, 1);
    updateFileList();
}

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
                    <i class="fas fa-eraser"></i>
                </button>
            </div>
        `).join('');
}

function submitFiles() {
    if (selectedFiles.length > 0) {
        try {
            const jsonString = JSON.stringify(selectedFiles);
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("FileUploaded", [jsonString]);
            
            // Limpiar archivos después del envío exitoso
            setTimeout(() => {
                selectedFiles = [];
                updateFileList();
            }, 1000);
            
        } catch (error) {
            console.error("Error en submitFiles:", error);
        }
    }
}

function clearFiles() {
    selectedFiles = [];
    updateFileList();
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function getFileIcon(fileName) {
    const extension = fileName.split('.').pop().toLowerCase();
    const icons = {
        'pdf': '<span class="file-icon pdf"><i class="fas fa-file-pdf"></i></span>',
        'doc': '<span class="file-icon word"><i class="fas fa-file-word"></i></span>',
        'docx': '<span class="file-icon word"><i class="fas fa-file-word"></i></span>',
        'txt': '<span class="file-icon default"><i class="fas fa-file-alt"></i></span>',
        'xls': '<span class="file-icon excel"><i class="fas fa-file-excel"></i></span>',
        'xlsx': '<span class="file-icon excel"><i class="fas fa-file-excel"></i></span>',
        'csv': '<span class="file-icon excel"><i class="fas fa-file-csv"></i></span>',
        'ppt': '<span class="file-icon powerpoint"><i class="fas fa-file-powerpoint"></i></span>',
        'pptx': '<span class="file-icon powerpoint"><i class="fas fa-file-powerpoint"></i></span>',
        'jpg': '<span class="file-icon image"><i class="fas fa-file-image"></i></span>',
        'jpeg': '<span class="file-icon image"><i class="fas fa-file-image"></i></span>',
        'png': '<span class="file-icon image"><i class="fas fa-file-image"></i></span>',
        'gif': '<span class="file-icon image"><i class="fas fa-file-image"></i></span>',
        'bmp': '<span class="file-icon image"><i class="fas fa-file-image"></i></span>',
        'zip': '<span class="file-icon archive"><i class="fas fa-file-archive"></i></span>',
        'rar': '<span class="file-icon archive"><i class="fas fa-file-archive"></i></span>',
        '7z': '<span class="file-icon archive"><i class="fas fa-file-archive"></i></span>',
        'json': '<span class="file-icon code"><i class="fas fa-file-code"></i></span>',
        'xml': '<span class="file-icon code"><i class="fas fa-file-code"></i></span>',
        'html': '<span class="file-icon code"><i class="fas fa-file-code"></i></span>',
        'js': '<span class="file-icon code"><i class="fas fa-file-code"></i></span>',
        'css': '<span class="file-icon code"><i class="fas fa-file-code"></i></span>',
        'mp3': '<span class="file-icon audio"><i class="fas fa-file-audio"></i></span>',
        'wav': '<span class="file-icon audio"><i class="fas fa-file-audio"></i></span>',
        'mp4': '<span class="file-icon video"><i class="fas fa-file-video"></i></span>',
        'avi': '<span class="file-icon video"><i class="fas fa-file-video"></i></span>',
        'mov': '<span class="file-icon video"><i class="fas fa-file-video"></i></span>'
    };
    return icons[extension] || '<span class="file-icon default"><i class="fas fa-file"></i></span>';
}

function SetVisible(IsVisible) {
    if (IsVisible) {
        document.querySelector("#pdf-contents").style.display = 'block';
    } else {
        document.querySelector("#pdf-contents").style.display = 'none';
    }
}

function Ficheros(NumerodeFicheros) {
    document.getElementById('file_count').textContent = NumerodeFicheros;
}
function Fichero(Numero) {
    document.getElementById('file_num').textContent = Numero;
}
function LoadPDF(PDFDocument, IsFactbox) {
    var canvas = document.getElementById('the-canvas'),
    pdfcontents = document.getElementById('pdf-contents'),
    ctx = canvas.getContext('2d'),
    iframe = window.frameElement,
    factboxarea = window.frameElement.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement,
    scale = 1.3;
    document.getElementById('Imprimir').style.display = 'block';
    clearViewerState();

    pageRendering = false;
    pageNum = 1;
    pageNumPending = null;

    pdfDocPrint = PDFDocument;
    PDFDocument = atob(PDFDocument);

    if (IsFactbox) {
        if (factboxarea.className = "ms-nav-layout-factbox-content-area ms-nav-scrollable") {
            factboxarea.style.paddingLeft = "5px";
            factboxarea.style.paddingRight = "0px";
            factboxarea.style.overflowY = "scroll";
        }
        scale = 0.6;
    } else {
        document.querySelector("#pdf-view").style.display = 'none';
        document.querySelector("#Download").style.display = 'none';
        document.querySelector("#Imprimir").style.display = 'none';
        document.querySelector("#Anterior").style.display = 'none';
        document.querySelector("#Siguiente").style.display = 'none';
    }

    requestAnimationFrame(() => {
        function renderPage(num) {
            pageRendering = true;
            pdfDoc.getPage(num).then(function (page) {
                var viewport = page.getViewport({ scale: scale });
                canvas.height = viewport.height;
                canvas.width = viewport.width;
                pdfcontents.height = viewport.height;
                pdfcontents.width = viewport.width;
                iframe.style.height = "1020px";
                iframe.parentElement.style.height = "1020px";
                iframe.style.maxHeight = "1020px";
                iframe.parentElement.style.maxHeight = "1020px";
                iframe.style.overflowY = "scroll";
                

                var renderContext = {
                    canvasContext: ctx,
                    viewport: viewport
                };
                var renderTask = page.render(renderContext);

                renderTask.promise.then(function () {
                    pageRendering = false;
                    if (pageNumPending !== null) {
                        renderPage(pageNumPending);
                        pageNumPending = null;
                    }
                });
            });
            document.getElementById('page_num').textContent = num;
        }

        function queueRenderPage(num) {
            if (pageRendering) {
                pageNumPending = num;
            } else {
                renderPage(num);
            }
        }

        function onPrevPage() {
            if (pageNum <= 1) return;
            pageNum--;
            queueRenderPage(pageNum);
        }
        if (IsFirstLoad) {
            document.getElementById('prev').addEventListener('click', onPrevPage);
        }

        function onNextPage() {
            if (pageNum >= pdfDoc.numPages) return;
            pageNum++;
            queueRenderPage(pageNum);
        }
        if (IsFirstLoad) {
            document.getElementById('next').addEventListener('click', onNextPage);
        }

        function OnPrintDiv() {
            const binary = atob(pdfDocPrint.replace(/\s/g, ''));
            const len = binary.length;
            const buffer = new ArrayBuffer(len);
            const view = new Uint8Array(buffer);
            for (let i = 0; i < len; i++) {
                view[i] = binary.charCodeAt(i);
            }
            const blob = new Blob([view], { type: "application/pdf" });
            const url = URL.createObjectURL(blob);
            const iframe = document.createElement('iframe');
            iframe.style.display = 'none';
            iframe.src = url;
            document.body.appendChild(iframe);
            iframe.contentWindow.print();
        }
        if (IsFirstLoad) {
            document.getElementById('Imprimir').addEventListener('click', OnPrintDiv);
        }

        function onView() {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('onView');
        }
        if (IsFirstLoad) {
            document.getElementById('pdf-view').addEventListener('click', onView);
        }
        function onSiguiente() {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('onSiguiente');
        }
        if (IsFirstLoad) {
            document.getElementById('Siguiente').addEventListener('click', onSiguiente);
        }
        function onAnterior() {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('onAnterior');
        }
        if (IsFirstLoad) {
            document.getElementById('Anterior').addEventListener('click', onAnterior);
        }
        function onDownload() {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('onDownload');
        }
        if (IsFirstLoad) {
            document.getElementById('Download').addEventListener('click', onDownload);
        }

        IsFirstLoad = false;

        pdfjsLib.getDocument({ data: PDFDocument }).promise.then(function (pdfDoc_) {
            pdfDoc = pdfDoc_;
            document.getElementById('page_count').textContent = '/' + pdfDoc.numPages;
            renderPage(pageNum);
        });
    });
}
// Funciones para el modal
// function openModal() {
//     return;
     
//      // Crear un blob del PDF para abrir en nueva pestaña
//      const binary = atob(pdfDocPrint.replace(/\s/g, ''));
//      const len = binary.length;
//      const buffer = new ArrayBuffer(len);
//      const view = new Uint8Array(buffer);
//      for (let i = 0; i < len; i++) {
//          view[i] = binary.charCodeAt(i);
//      }
//      const blob = new Blob([view], {type: "application/pdf"});
//      const url = URL.createObjectURL(blob);
     
//      // Abrir en nueva pestaña
//      window.open(url, '_blank');
// }
 
//  function openModalImage() {
//      // Para imágenes, crear una nueva pestaña con la imagen en tamaño completo
//      return;
//      const canvas = document.getElementById('the-canvas');
//      const imageData = canvas.toDataURL('image/png');
     
//      // Crear una nueva ventana con la imagen
//      const newWindow = window.open('', '_blank');
//      newWindow.document.write(`
//          <!DOCTYPE html>
//          <html>
//          <head>
//              <title>Vista del Documento</title>
//              <style>
//                  body {
//                      margin: 0;
//                      padding: 20px;
//                      background: #f5f5f5;
//                      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
//                  }
//                  .container {
//                      max-width: 95%;
//                      margin: 0 auto;
//                      background: white;
//                      border-radius: 8px;
//                      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
//                      overflow: hidden;
//                  }
//                  .header {
//                      background: #007bff;
//                      color: white;
//                      padding: 15px 20px;
//                      display: flex;
//                      justify-content: space-between;
//                      align-items: center;
//                  }
//                  .header h1 {
//                      margin: 0;
//                      font-size: 18px;
//                  }
//                  .close-btn {
//                      background: #dc3545;
//                      color: white;
//                      border: none;
//                      border-radius: 50%;
//                      width: 30px;
//                      height: 30px;
//                      cursor: pointer;
//                      font-size: 16px;
//                      display: flex;
//                      align-items: center;
//                      justify-content: center;
//                  }
//                  .close-btn:hover {
//                      background: #c82333;
//                  }
//                  .content {
//                      padding: 20px;
//                      text-align: center;
//                  }
//                  img {
//                      max-width: 100%;
//                      height: auto;
//                      border-radius: 4px;
//                      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
//                  }
//              </style>
//          </head>
//          <body>
//              <div class="container">
//                  <div class="header">
//                      <h1>Vista del Documento</h1>
//                      <button class="close-btn" onclick="window.close()">&times;</button>
//                  </div>
//                  <div class="content">
//                      <img src="${imageData}" alt="Documento" />
//                  </div>
//              </div>
//          </body>
//          </html>
//      `);
//      newWindow.document.close();
// }
 
//  function closeModal() {
//      return;
//      modalOverlay.style.display = 'none';
//      document.body.style.overflow = ''; // Restaurar scroll del body
// }
// Función para limpiar el estado del visor
function clearViewerState() {
    const canvas = document.getElementById('the-canvas');
    const iframeContainer = document.getElementById('iframe-container');

    canvas.style.display = 'block';
    canvas.width = 0;
    canvas.height = 0;

    if (iframeContainer) {
        iframeContainer.innerHTML = '';
    }

    const iframe = window.frameElement;
    if (iframe) {
        iframe.style.height = 'auto';
        iframe.style.maxHeight = 'none';
        if (iframe.parentElement) {
            iframe.parentElement.style.height = 'auto';
        }
    }
}

function LoadOtros(base64Data, IsFactbox, fileType, driveType, driveId) {
    if (fileType === 'image') fileType = 'image/jpg';
    if (fileType === 'word') fileType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    if (fileType === 'excel') fileType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    if (fileType === 'powerpoint') fileType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    // Eliminamos el manejo de PDF aquí
    // if (fileType === 'pdf') fileType = 'application/pdf';
    if (fileType === 'text') fileType = 'text/plain';
    if (fileType === 'csv') fileType = 'text/csv';
    if (fileType === 'xml') fileType = 'application/xml';
    
    const canvas = document.getElementById('the-canvas');
    const ctx = canvas.getContext('2d');
    const iframeContainer = document.getElementById('iframe-container');
    const iframe = window.frameElement;
    
    // Limpiar estado anterior
    clearViewerState();
    
    // Ocultar canvas y limpiar iframe container
    canvas.style.display = 'none';
    if (iframeContainer) iframeContainer.innerHTML = '';

    // Verificar si tenemos driveType y driveId para usar servicios externos
    let iframeUrl = null;
    if (driveType === 'google' && driveId) {
        iframeUrl = `https://drive.google.com/file/d/${driveId}/preview`;
    } else if (driveType === 'dropbox' && driveId) {
        iframeUrl = `https://dl.dropboxusercontent.com/s/${driveId}?raw=1`;
    } else if (driveType === 'onedrive' && driveId) {
        iframeUrl = driveId;
    }
    if (fileType.startsWith('image/'))  iframeUrl = null;
    // Si tenemos URL de drive, usar iframe externo
    if (iframeUrl) {
        const externalIframe = document.createElement('iframe');
        externalIframe.src = iframeUrl;
        externalIframe.width = '100%';
        externalIframe.style.width = '100%';
        externalIframe.style.boxSizing = 'border-box';
        externalIframe.style.height = '1020px';
        externalIframe.style.maxHeight = '1020px';

        // La altura la controla el CSS (1020px)
        externalIframe.style.border = 'none';
        iframeContainer.appendChild(externalIframe);

        if (iframe) {
            iframe.style.height = '1020px';
            iframe.style.maxHeight = '1020px';
            if (iframe.parentElement) {
                iframe.parentElement.style.height = '1020px';
                iframe.parentElement.style.maxHeight = '1020px';
            }
        }
        return;
    }

    // Si no hay drive, procesar con base64
    // Limpiar el base64
    base64Data = base64Data.replace(/\s/g, '').replace(/^data:[^;]+;base64,/, '');

    let byteArray;
    try {
        const byteCharacters = atob(base64Data);
        const byteNumbers = new Array(byteCharacters.length);
        for (let i = 0; i < byteCharacters.length; i++) {
            byteNumbers[i] = byteCharacters.charCodeAt(i);
        }
        byteArray = new Uint8Array(byteNumbers);
    } catch (error) {
        alert("El archivo no pudo ser decodificado. ¿Está seguro de que el base64 está bien formado?");
        return;
    }

    const blob = new Blob([byteArray], { type: fileType });
    const blobUrl = URL.createObjectURL(blob);

    if (fileType.startsWith('image/')) {
        // Mostrar imágenes en canvas
        const image = new Image();
        image.onload = function () {
            canvas.width = 357;
            canvas.height = 505;
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
            canvas.style.display = 'block';
            
            // Ajustar tamaño del frame para imágenes
            if (iframe) {
                iframe.style.height = '1020px';
                iframe.style.maxHeight = '1020px';
                if (iframe.parentElement) {
                    iframe.parentElement.style.height = '1020px';
                    iframe.parentElement.style.maxHeight = '1020px';
                }
            }
        };
        image.onerror = function () {
            alert('Error al cargar la imagen.');
        };
        image.src = blobUrl;
    } else if (fileType === 'text/plain' || fileType === 'text/csv' || fileType === 'application/xml') {
        // Mostrar archivos de texto en iframe
        const textIframe = document.createElement('iframe');
        textIframe.src = blobUrl;
        textIframe.width = '100%';
        // La altura la controla el CSS (1020px)
        textIframe.style.border = 'none';
        iframeContainer.appendChild(textIframe);
        
        // Ajustar tamaño del frame para archivos de texto
        if (iframe) {
            iframe.style.height = '1020px';
            iframe.style.maxHeight = '1020px';
            if (iframe.parentElement) {
                iframe.parentElement.style.height = '1020px';
                iframe.parentElement.style.maxHeight = '1020px';
            }
        }
    } else {
        // Para archivos Word, Excel, PowerPoint y otros que no se pueden mostrar directamente
        // Mostrar un mensaje con opciones de descarga y apertura
        const messageDiv = document.createElement('div');
        messageDiv.style.cssText = `
            text-align: center;
            padding: 50px;
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
            border: 2px dashed #ccc;
            border-radius: 10px;
            margin: 20px;
        `;
        
        const icon = document.createElement('div');
        icon.innerHTML = '📄';
        icon.style.fontSize = '48px';
        icon.style.marginBottom = '20px';
        
        const title = document.createElement('h3');
        title.textContent = 'Archivo Word detectado';
        title.style.marginBottom = '10px';
        
        const description = document.createElement('p');
        description.textContent = 'Los archivos Word no se pueden previsualizar directamente en el navegador. Puedes abrirlos con tu aplicación predeterminada o descargarlos.';
        description.style.marginBottom = '20px';
        description.style.color = '#666';
        
        const buttonContainer = document.createElement('div');
        buttonContainer.style.cssText = `
            display: flex;
            gap: 10px;
            justify-content: center;
            flex-wrap: wrap;
        `;
        
        const openBtn = document.createElement('button');
        openBtn.textContent = 'Abrir con aplicación';
        openBtn.style.cssText = `
            background-color: #28a745;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
        `;
        openBtn.onclick = function() {
            // Intentar abrir con la aplicación predeterminada del sistema
            const link = document.createElement('a');
            link.href = blobUrl;
            link.target = '_blank';
            link.rel = 'noopener noreferrer';
            // No usar download para que el navegador intente abrir con la aplicación
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        };
        
        const downloadBtn = document.createElement('button');
        downloadBtn.textContent = 'Descargar archivo';
        downloadBtn.style.cssText = `
            background-color: #007bff;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
        `;
        downloadBtn.onclick = function() {
            // Forzar la descarga del archivo
            const link = document.createElement('a');
            link.href = blobUrl;
            link.download = 'archivo.' + getFileExtension(fileType);
            link.style.display = 'none';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        };
        
        buttonContainer.appendChild(openBtn);
        buttonContainer.appendChild(downloadBtn);
        
        messageDiv.appendChild(icon);
        messageDiv.appendChild(title);
        messageDiv.appendChild(description);
        messageDiv.appendChild(buttonContainer);
        
        iframeContainer.appendChild(messageDiv);
        
        // Ajustar tamaño del frame para archivos Word/Excel (más altura para mostrar botones)
        if (iframe) {
            iframe.style.height = '1020px';
            if (iframe.parentElement) {
                iframe.parentElement.style.height = '1020px';
            }
        }
    }
}

function getFileExtension(mimeType) {
    const extensions = {
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'docx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'xlsx',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation': 'pptx',
        'application/pdf': 'pdf',
        'text/plain': 'txt',
        'text/csv': 'csv',
        'application/xml': 'xml',
        'image/jpg': 'jpg',
        'image/jpeg': 'jpg',
        'image/png': 'png',
        'image/gif': 'gif'
    };
    return extensions[mimeType] || 'bin';
}
