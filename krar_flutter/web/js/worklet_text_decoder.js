// AudioWorkletGlobalScope has no TextDecoder (the Encoding API is exposed
// only to Window and Worker), but the wasm-bindgen glue constructs one at
// module top level to decode error strings. Importing this file before the
// glue guarantees it evaluates first — ES module evaluation order runs
// dependencies in import order — so the glue sees a working TextDecoder.

if (typeof globalThis.TextDecoder === 'undefined') {
  globalThis.TextDecoder = class TextDecoder {
    constructor(label = 'utf-8', options = {}) {
      const normalized = String(label).toLowerCase().replace(/[\s_]/g, '');
      if (normalized !== 'utf8' && normalized !== 'utf-8') {
        throw new RangeError(`The encoding '${label}' is not supported`);
      }
      this.fatal = options.fatal === true;
      this.ignoreBOM = options.ignoreBOM === true;
    }

    decode(input) {
      if (input === undefined || input === null) return '';
      const bytes = input instanceof Uint8Array
        ? input
        : input instanceof ArrayBuffer
          ? new Uint8Array(input)
          : new Uint8Array(input.buffer, input.byteOffset, input.byteLength);
      let out = '';
      let i = 0;
      const n = bytes.length;
      while (i < n) {
        const b0 = bytes[i++];
        if (b0 < 0x80) {
          out += String.fromCharCode(b0);
          continue;
        }
        let cp;
        let cont;
        let min;
        if (b0 >= 0xc2 && b0 < 0xe0) {
          cp = b0 & 0x1f;
          cont = 1;
          min = 0x80;
        } else if (b0 >= 0xe0 && b0 < 0xf0) {
          cp = b0 & 0x0f;
          cont = 2;
          min = 0x800;
        } else if (b0 >= 0xf0 && b0 < 0xf5) {
          cp = b0 & 0x07;
          cont = 3;
          min = 0x10000;
        } else {
          if (this.fatal) throw new TypeError('Invalid UTF-8 sequence');
          out += '�';
          continue;
        }
        let valid = true;
        for (let k = 0; k < cont; k++) {
          const b = bytes[i++];
          if (b === undefined || (b & 0xc0) !== 0x80) {
            valid = false;
            break;
          }
          cp = (cp << 6) | (b & 0x3f);
        }
        if (!valid || cp < min || cp > 0x10ffff || (cp >= 0xd800 && cp <= 0xdfff)) {
          if (this.fatal) throw new TypeError('Invalid UTF-8 sequence');
          out += '�';
          continue;
        }
        if (cp < 0x10000) {
          out += String.fromCharCode(cp);
        } else {
          cp -= 0x10000;
          out += String.fromCharCode(0xd800 + (cp >> 10), 0xdc00 + (cp & 0x3ff));
        }
      }
      return out;
    }
  };
}
