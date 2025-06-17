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
function LoadOtros(PDFDocument,IsFactbox) {
    var image = new Image();
    image.src = 'data:image/jpg;base64,'+PDFDocument;
    PDFDocument = image.src;
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
    PDFDocument=PDFDocument;  
    canvas.height = 505;
    canvas.width = 357;

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
        image.onload = function(){
            ctx.drawImage(image, 0, 0,canvas.width,canvas.height);
          }

            // canvas.appendChild(image);
            // var viewport = canvas;
            

            // pdfcontents.height = viewport.height;
            // pdfcontents.width = viewport.width;
            iframe.style.height = canvas.height + 100 + "px";
            iframe.parentElement.style.height = canvas.height + 100 + "px";
            iframe.style.maxHeight = "2600px";

            // Render PDF page into canvas context
           
            document.getElementById('page_num').textContent = 1;
       


        /**
         * If another page rendering in progress, waits until the rendering is
         * finised. Otherwise, executes rendering immediately.
         */
       
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
        document.getElementById('page_count').textContent = 1;
        
       


  
        

        
    
}



