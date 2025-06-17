//var controlAddIn = document.getElementById('controlAddIn');
var canvas = window.frameElement;// document.createElement("CANVAS");
canvas.width = 500;
canvas.height = 500;
canvas.id = "canvas";

Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnControlAddInReady', null);
