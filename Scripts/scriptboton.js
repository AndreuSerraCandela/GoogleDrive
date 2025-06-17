var __ViewerFrame;
var ctx
function Init() {
    var controlAddIn = document.getElementById('controlAddIn');
    var canvas =  document.createElement("CANVAS");
    controlAddIn.innerHTML = '<iframe id="CANVAS" style="border-style: none; margin: 0px; padding: 0px; height: 100%; width: 100%" allowFullScreen></iframe>'
    __ViewerFrame = document.getElementById('CANVAS');
    document.body.appendChild(canvas);
    ctx = canvas.getContext("2d");
    
}
function BotonReady(message) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnBotonReady', null);
}
function drawPaddle() {
    ctx.beginPath();
    ctx.rect(paddleX, canvas.height-paddleHeight, paddleWidth, paddleHeight);
    //ctx.fillStyle = "#0095DD";
    ctx.fillStyle = "#000000";
    ctx.fill();
    ctx.closePath();
  }
  function drawBricks() {
          ctx.beginPath();
          ctx.rect(1, 1, 100, 100);
          ctx.fillStyle = "#0095DD";
          //ctx.fillStyle = "#000000";
          ctx.fill();
          //ctx.fillText("ubicacion", 2, 20);
          ctx.closePath();
        }
        function drawLives() {
          ctx.font = "16px Arial";
          //ctx.fillStyle = "#0095DD";
          ctx.fillStyle = "#000000";
          ctx.fillText("Ubicación", 15, 20);
        }
        function drawLives2() {
          ctx.font = "16px Arial";
          //ctx.fillStyle = "#0095DD";
          ctx.fillStyle = "#000000";
          ctx.fillText("W-100-D", 15, 40);
        }
  
  function draw() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    drawBricks();
    drawLives();
    drawLives2();
    }
  
//  draw();
  
  
//  var canvas = controlAddIn.appendChild(canvas);
//  Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnControlAddInReady', null);

