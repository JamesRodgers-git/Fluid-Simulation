'use strict'; // are we still using this?

let utf8decoder = new TextDecoder();
let wasmMemory = null;

const imports = {
    // Here we provide functions that can be used on the Zig side
    env: {
        // ...webgl,
        wasmConsoleLog,
        // getScale,
        // getWidth,
        // getHeight,
    },
};

function startWasm () {
    WebAssembly.instantiateStreaming(fetch("/bin/fluid.wasm"), imports).then((obj) => {
        wasmMemory = obj.instance.exports.memory;

        // const tbl = obj.instance.exports.tbl;
        // console.log(obj);
        obj.instance.exports.init();
    });
}

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