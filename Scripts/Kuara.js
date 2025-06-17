var __ViewerFrame;
var __ViewerOrigin;
var controlAddIn
function InitializeControl(url) {
    __ViewerOrigin = getViewerOrigin(url);
    window.addEventListener("message", onMessage);
    controlAddIn = document.getElementById('controlAddIn');
    controlAddIn.innerHTML = '<iframe id="viewer" style="border-style: none; margin: 0px; padding: 0px; height: 100%; width: 100%" allowFullScreen></iframe>'
    __ViewerFrame = document.getElementById('viewer');
    __ViewerFrame.addEventListener("load",ViewerReady);
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

function ViewerReady(message) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnViewerReady', null);
}

function LoadDocument(data,textdata) {
    //var x = document.getElementById("viewer").contentWindow; 
   data=JSON.parse(textdata);
    console.dir(JSON.stringify(data));
    //x.postMessage(data, '*'); 
    __ViewerFrame.contentWindow.postMessage(data, "*");
}
function Ampliar(){
    var x=window.top.document.getElementsByClassName("designer-client-frame")[0].contentWindow.document.body.getElementsByClassName("ms-nav-cardpartform ms-nav-noCommandBar control-addin-form vertical-stretch")[1];
    console.log(x);
    x.style.width="100%";
    x.style.height="100%";
    x=x.children[0];
    x.style.height="100%";
}