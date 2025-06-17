var __ViewerFrame;
var __ViewerOrigin;
// mini-jQuery
var $ = function (id) { return document.getElementById(id); };

// Caché
$set = $('set');
$read = $('read');
$delete = $('delete');
$logs = $('logs');

// Logs en textarea
var log = function (log) { $logs.value = log + '\n' + $logs.value; }

function InitializeControl(url) {
    __ViewerOrigin = getViewerOrigin(url);
    window.addEventListener("message", onMessage, false);
    window.addEventListener("click",OnClick,false);
    //controlAddIn.innerHTML = '<iframe id="viewer" style="border-style: none; margin: 0px; padding: 0px; height: 100%; width: 100%" allowFullScreen"></iframe>'
    controlAddIn.innerHTML='<iframe id="viewer" style="border-style: none; margin: 0px; padding: 0px; height: 100%; width: 100%" allowFullScreen></iframe>'
    __ViewerFrame = document.getElementById('viewer');
    __ViewerFrame.src = url;
   
    
}

function getViewerOrigin(url) {
    if (isIE()) {
        var l = document.createElement("a");
        l.href = url;
        return (l.protocol + "//" + l.hostname);
    } else {
        return (new URL(url)).origin;
    }
}

function isIE() {
    ua = navigator.userAgent;
    /* MSIE used to detect old browsers and Trident used to newer ones*/
    var is_ie = ua.indexOf("MSIE ") > -1 || ua.indexOf("Trident/") > -1;
    
    return is_ie; 
  }

function onMessage(event) {
    if (event.origin !== __ViewerOrigin) {
        console.log('Blocked invalid cross-domain call');
        return;
    }

    var data = event.data;

    if (typeof(window[data.func]) == "function") {
        window[data.func].call(null, data.message);
    }
}

function pdfViewerReady(message) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnPdfViewerReady', null);

}
function OnClick(message) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("Click", null);
}