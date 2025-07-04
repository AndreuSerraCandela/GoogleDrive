var pdfDoc = null,
    pdfDocPrint = null,
    pageNum = 1,
    pageRendering = false,
    pageNumPending = null,
    IsFirstLoad = true;

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
        '<span id="page_num"></span> / ' +
        '<span id="page_count"></span></span>' +
        '</div>' +
        '</div>' +
        '<canvas id="the-canvas"></canvas>' +
        '<div id="iframe-container"></div>' +
        '<div id="file-count-content">' +
        '<span id="file-count-container">Arch: ' +
        '<span id="file_num"></span> / ' +
        '<span id="file_count"></span></span>' +
        '</div>' +
        '</div>';
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
                iframe.style.height = viewport.height + 100 + "px";
                iframe.parentElement.style.height = viewport.height + 100 + "px";
                iframe.style.maxHeight = "2600px";

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
            document.getElementById('page_count').textContent = pdfDoc.numPages;
            renderPage(pageNum);
        });
    });
}
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
    if (fileType === 'excel') fileType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    if (fileType === 'powerpoint') fileType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    if (fileType === 'text') fileType = 'text/plain';
    if (fileType === 'csv') fileType = 'text/csv';
    if (fileType === 'xml') fileType = 'application/xml';
    document.getElementById('Imprimir').style.display = 'none';
    


    const canvas = document.getElementById('the-canvas');
    const ctx = canvas.getContext('2d');
    const iframeContainer = document.getElementById('iframe-container');
    const iframeRef = window.frameElement;

    clearViewerState();
    canvas.style.display = 'none';
    if (iframeContainer) iframeContainer.innerHTML = '';

    let iframeUrl = null;

    if (driveType === 'google' && driveId) {
        iframeUrl = `https://drive.google.com/file/d/${driveId}/preview`;
    } else if (driveType === 'dropbox' && driveId) {
        iframeUrl = `https://dl.dropboxusercontent.com/s/${driveId}?raw=1`;
    } else if (driveType === 'onedrive' && driveId) {
        iframeUrl = driveId;
    }

    if (iframeUrl) {
        const iframe = document.createElement('iframe');
        iframe.src = iframeUrl;
        iframe.width = '100%';
        iframe.height = '700px';
        iframe.style.border = 'none';
        iframeContainer.appendChild(iframe);

        if (iframeRef) {
            iframeRef.style.height = '720px';
            if (iframeRef.parentElement) iframeRef.parentElement.style.height = '720px';
        }
        return;
    }

    base64Data = base64Data.replace(/\s/g, '').replace(/^data:[^;]+;base64,/, '');

    let byteArray;
    try {
        const byteCharacters = atob(base64Data);
        byteArray = new Uint8Array(byteCharacters.length);
        for (let i = 0; i < byteCharacters.length; i++) {
            byteArray[i] = byteCharacters.charCodeAt(i);
        }
    } catch (error) {
        alert("El archivo no pudo ser decodificado. ¿Está seguro de que el base64 está bien formado?");
        return;
    }

    const blob = new Blob([byteArray], { type: fileType });
    const blobUrl = URL.createObjectURL(blob);

    if (fileType.startsWith('image/')) {
        const image = new Image();
        image.onload = function () {
            canvas.width = 357;
            canvas.height = 505;
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
            canvas.style.display = 'block';

            if (iframeRef) {
                iframeRef.style.height = (canvas.height + 100) + "px";
                if (iframeRef.parentElement) iframeRef.parentElement.style.height = (canvas.height + 100) + "px";
            }
        };
        image.onerror = () => alert('Error al cargar la imagen.');
        image.src = blobUrl;
    } else if (['text/plain', 'text/csv', 'application/xml'].includes(fileType)) {
        const textIframe = document.createElement('iframe');
        textIframe.src = blobUrl;
        textIframe.width = '100%';
        textIframe.height = '600px';
        textIframe.style.border = 'none';
        iframeContainer.appendChild(textIframe);

        if (iframeRef) {
            iframeRef.style.height = '700px';
            if (iframeRef.parentElement) iframeRef.parentElement.style.height = '700px';
        }
    } else {
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
        title.textContent = 'Archivo descargable';
        title.style.marginBottom = '10px';

        const description = document.createElement('p');
        description.textContent = 'Este archivo no se puede previsualizar, pero puedes descargarlo.';
        description.style.marginBottom = '20px';
        description.style.color = '#666';

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
        downloadBtn.onclick = function () {
            const link = document.createElement('a');
            link.href = blobUrl;
            link.download = 'archivo.' + getFileExtension(fileType);
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        };

        messageDiv.appendChild(icon);
        messageDiv.appendChild(title);
        messageDiv.appendChild(description);
        messageDiv.appendChild(downloadBtn);
        iframeContainer.appendChild(messageDiv);

        if (iframeRef) {
            iframeRef.style.height = '500px';
            if (iframeRef.parentElement) iframeRef.parentElement.style.height = '500px';
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
