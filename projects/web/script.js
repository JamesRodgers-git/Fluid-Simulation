'use strict'; // are we still using this?

const canvas = document.getElementsByTagName('canvas')[0];
resizeCanvas();

const gl = getWebGLContext(canvas);

if (!gl) {
    alert('You need a browser with webgl2 enabled');
    throw new Error("no webgl2");
}

if (!('WebAssembly' in window)) {
    alert('You need a browser with wasm support enabled');
    throw new Error("no webassembly");
}

const utf8decoder = new TextDecoder();
let wasmMemory = null;
let exports = {};

const webgl = {
    glViewport: () => {  },
};

const imports = {
    // Here we provide functions that can be used on the Zig side
    env: {
        ...webgl,
        wasmConsoleLog,
        // getScale,
        // getWidth,
        // getHeight,
    },
};

startWasm();

function getWebGLContext (canvas) {
    // colorSpace: "display-p3", desynchronized: false, powerPreference: "high-performance", 
    const params = { alpha: false, depth: false, stencil: false, antialias: false, preserveDrawingBuffer: false };
    let gl = canvas.getContext('webgl2', params);
    return gl;
}

function startWasm () {
    WebAssembly.instantiateStreaming(fetch("/bin/fluid.wasm"), imports).then((obj) => {
        exports = obj.instance.exports;
        wasmMemory = obj.instance.exports.memory;

        // const tbl = obj.instance.exports.tbl;
        // console.log(obj);
        exports.init();
        update();
    });
}

function update () {
    exports.update();

    gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
    gl.clearColor(1.0, 0.0, 0.0, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT);

    exports.draw();

    requestAnimationFrame(update);
}

// function getWebGLExtensions () {
//     let supportLinearFiltering;

//     gl.getExtension('EXT_color_buffer_float');
//     supportLinearFiltering = gl.getExtension('OES_texture_float_linear');

//     // gl.clearColor(0.0, 0.0, 0.0, 1.0);

//     // let formatRGBA;
//     // let formatRG;
//     // let formatR;

//     // formatRGBA = getSupportedFormat(gl, gl.RGBA16F, gl.RGBA, gl.HALF_FLOAT);
//     // formatRG = getSupportedFormat(gl, gl.RG16F, gl.RG, gl.HALF_FLOAT);
//     // formatR = getSupportedFormat(gl, gl.R16F, gl.RED, gl.HALF_FLOAT);
// }

function resizeCanvas () {
    let width = scaleByPixelRatio(canvas.clientWidth);
    let height = scaleByPixelRatio(canvas.clientHeight);
    if (canvas.width != width || canvas.height != height) {
        canvas.width = width;
        canvas.height = height;
        return true;
    }
    return false;
}

// I think this can be simplified
function scaleByPixelRatio (input) {
    let pixelRatio = window.devicePixelRatio || 1;
    return Math.floor(input * pixelRatio);
}

// external functions

function wasmConsoleLog (ptr, len) {
    var textLog = utf8decoder.decode(new Uint8Array(wasmMemory.buffer, ptr, len));
    console.log(textLog);
};

// const getScale = () => {
//     return window.devicePixelRatio;
// };

// const getWidth = () => {
//     return window.innerWidth;
// };

// const getHeight = () => {
//     return window.innerHeight;
// };

// webgl external functions