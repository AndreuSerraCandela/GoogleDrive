var pdfDoc = null,
    pdfDocPrint = null,
    pageNum = 1,
    pageRendering = false,
    pageNumPending = null,
    IsFirstLoad = true;

function InitializeControl(controlId) {
    var controlAddIn = document.getElementById(controlId);
    controlAddIn.innerHTML =
    '<div id="pdf-contents">'+
        '<div id="pdf-meta">'+
            '<div id="pdf-buttons">'+
                '<button id="prev" class="button-style"><i class="fas fa-arrow-left"></i></button>'+
                '<button id="next"class="button-style"><i class="fas fa-arrow-right"></i></button>'+
                '<button id="pdf-view" class="button-style"><i class="fas fa-search-plus"></i></button>'+
                '<button id="Download" class="button-style"><i class="fas fa-cloud-download-alt"></i></i></button>'+
                '<button id="Imprimir" class="button-style"><i class="fas fa-print"></i></i></button>'+
                '<button id="Anterior" class="button-style"><i class="fas fa-fast-backward"></i></i></button>'+
                '<button id="Siguiente" class="button-style"><i class="fas fa-fast-forward"></i></i></button>'+           
                '<span id="page-count-container">'+
                '<span id="page_num"></span> / '+
                '<span id="page_count"></span></span>'+
            '</div>'+
        '</div>'+
    '<canvas id="the-canvas"></canvas>'+
    '<div id="iframe-container"></div>'+
        '<div id="file-count-content">'+
            '<span id="file-count-container">Arch: '+
            '<span id="file_num"></span> / '+
            '<span id="file_count"></span></span>'+
        '</div>'+
    '</div>';
}

function SetVisible(IsVisible) {
    if (IsVisible){
        document.querySelector("#pdf-contents").style.display = 'block';
    }else{
        document.querySelector("#pdf-contents").style.display = 'none';
    }

}

function Ficheros(NumerodeFicheros){
    document.getElementById('file_count').textContent = NumerodeFicheros;
}
function Fichero(Numero){
    document.getElementById('file_num').textContent = Numero;
}
function LoadPDF(PDFDocument,IsFactbox){
    
    var canvas = document.getElementById('the-canvas'),
    pdfcontents = document.getElementById('pdf-contents'),
    ctx = canvas.getContext('2d'),
    iframe = window.frameElement,
    factboxarea = window.frameElement.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement,
    scale = 1.3;


    pageRendering = false;
    pageNum = 1;
    pageNumPending = null;

    pdfDocPrint = PDFDocument;
    PDFDocument = atob(PDFDocument);
    

    if (IsFactbox) {
        if (factboxarea.className = "ms-nav-layout-factbox-content-area ms-nav-scrollable"){
            factboxarea.style.paddingLeft = "5px";
            factboxarea.style.paddingRight = "0px";
            factboxarea.style.overflowY = "scroll";
        }
        scale = 0.6;
        }else{
            document.querySelector("#pdf-view").style.display = 'none';
            document.querySelector("#Download").style.display = 'none';
            document.querySelector("#Imprimir").style.display = 'none';
            document.querySelector("#Anterior").style.display = 'none';
            document.querySelector("#Siguiente").style.display = 'none';
        }
    

    requestAnimationFrame(() => {
        
        /**
         * Get page info from document, resize canvas accordingly, and render page.
         * @param num Page number.
         */
        function renderPage(num) {
            pageRendering = true;
            // Using promise to fetch the page
            pdfDoc.getPage(num).then(function(page) {
            var viewport = page.getViewport({scale: scale});
            canvas.height = viewport.height;
            canvas.width = viewport.width;

            pdfcontents.height = viewport.height;
            pdfcontents.width = viewport.width;
            iframe.style.height = viewport.height + 100 + "px";
            iframe.parentElement.style.height = viewport.height + 100 + "px";
            iframe.style.maxHeight = "2600px";

            // Render PDF page into canvas context
            var renderContext = {
                canvasContext: ctx,
                viewport: viewport
            };
            var renderTask = page.render(renderContext);
        
            // Wait for rendering to finish
            renderTask.promise.then(function() {
                pageRendering = false;
                if (pageNumPending !== null) {
                // New page rendering is pending
                renderPage(pageNumPending);
                pageNumPending = null;
                }
            });
            });
        
            // Update page counters
            document.getElementById('page_num').textContent = num;
        }


        /**
         * If another page rendering in progress, waits until the rendering is
         * finised. Otherwise, executes rendering immediately.
         */
        function queueRenderPage(num) {
            if (pageRendering) {
            pageNumPending = num;
            } else {
            renderPage(num);
            }
        }

        /**
         * Displays previous page.
         */
        function onPrevPage() {
            if (pageNum <= 1) {
            return;
            }
            pageNum--;
            queueRenderPage(pageNum);
        }
        if (IsFirstLoad){
            document.getElementById('prev').addEventListener('click', onPrevPage);
        }

        /**
         * Displays next page.
         */
        function onNextPage() {
            if (pageNum >= pdfDoc.numPages) {
            return;
            }
            pageNum++;
            queueRenderPage(pageNum);
        }
        if (IsFirstLoad){
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
                const blob = new Blob([view], {type: "application/pdf"});
                const url = URL.createObjectURL(blob);
                const iframe = document.createElement('iframe');
                iframe.style.display = 'none';
                iframe.src = url;
                document.body.appendChild(iframe);
                iframe.contentWindow.print();
                
            
        }
        if (IsFirstLoad){
            document.getElementById('Imprimir').addEventListener('click', OnPrintDiv);
        }

        /**
         * Displays full page.
         */
        function onView() {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('onView');
        }
        if (IsFirstLoad){
            document.getElementById('pdf-view').addEventListener('click', onView);
        }
        function onSiguiente() {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('onSiguiente');
        }
        if (IsFirstLoad){
            document.getElementById('Siguiente').addEventListener('click', onSiguiente);
        }
        function onAnterior() {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('onAnterior');
        }
        if (IsFirstLoad){
            document.getElementById('Anterior').addEventListener('click', onAnterior);
        }
        function onDownload() {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('onDownload');
        }
        if (IsFirstLoad){
            document.getElementById('Download').addEventListener('click', onDownload);
        }

        IsFirstLoad = false;

        /**
         * Asynchronously downloads PDF.
         */
        pdfjsLib.getDocument({data: PDFDocument}).promise.then(function(pdfDoc_) {
            pdfDoc = pdfDoc_;
            document.getElementById('page_count').textContent = pdfDoc.numPages;
        
            // Initial/first page rendering
            renderPage(pageNum);
        });


    });
}
function LoadOtros(base64Data, IsFactbox, fileType) {
    if (fileType == 'image') fileType = 'image/jpg';
    if (fileType == 'word') fileType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    if (fileType == 'excel') fileType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    if (fileType == 'powerpoint') fileType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    if (fileType == 'pdf') fileType = 'application/pdf';
    if (fileType == 'text') fileType = 'text/plain';
    if (fileType == 'csv') fileType = 'text/csv';
    if (fileType == 'xml') fileType = 'application/xml';
    
    const canvas = document.getElementById('the-canvas');
    const ctx = canvas.getContext('2d');
    const iframeContainer = document.getElementById('iframe-container');
    
    // Ocultar canvas y limpiar iframe container
    canvas.style.display = 'none';
    if (iframeContainer) iframeContainer.innerHTML = '';

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
        };
        image.onerror = function () {
            alert('Error al cargar la imagen.');
        };
        image.src = blobUrl;
    } else if (fileType === 'application/pdf') {
        // Mostrar PDFs en iframe
        const iframe = document.createElement('iframe');
        iframe.src = blobUrl;
        iframe.width = '100%';
        iframe.height = '600px';
        iframe.style.border = 'none';
        iframeContainer.appendChild(iframe);
    } else if (fileType === 'text/plain' || fileType === 'text/csv' || fileType === 'application/xml') {
        // Mostrar archivos de texto en iframe
        const iframe = document.createElement('iframe');
        iframe.src = blobUrl;
        iframe.width = '100%';
        iframe.height = '600px';
        iframe.style.border = 'none';
        iframeContainer.appendChild(iframe);
    } else {
        // Para archivos Word, Excel, PowerPoint y otros que no se pueden mostrar directamente
        // Mostrar un mensaje con opción de descarga
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
        title.textContent = 'Archivo no se puede previsualizar';
        title.style.marginBottom = '10px';
        
        const description = document.createElement('p');
        description.textContent = 'Este tipo de archivo no se puede mostrar directamente en el navegador.';
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
        downloadBtn.onclick = function() {
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
    }
}

// Función auxiliar para obtener la extensión del archivo
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

       


  
        

        
    




