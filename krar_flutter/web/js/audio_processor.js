// Runs the WASM string engine on the audio thread, so a busy UI can no
// longer interrupt the sound. The main thread only sends control messages
// (and the voice count at construction); it never waits for a buffer.

import init, { KrarEngine } from '../pkg/krar_engine.js';

let engine = null;
let pending = [];

function handleMessage(msg) {
  if (!engine) {
    pending.push(msg);
    return;
  }
  switch (msg.type) {
    case 'pluck':
      engine.pluck(msg.string, msg.velocity);
      break;
    case 'strike':
      engine.strike(msg.string, msg.velocity);
      break;
    case 'release':
      engine.release(msg.string);
      break;
    case 'setFrequency':
      engine.set_string_frequency(msg.string, msg.frequency);
      break;
    case 'setVolume':
      engine.set_master_volume(msg.volume);
      break;
    case 'setReverb':
      engine.set_reverb(msg.amount);
      break;
  }
}

class KrarProcessor extends AudioWorkletProcessor {
  constructor(options) {
    super();
    const processorOptions = options?.processorOptions ?? {};
    const voices = processorOptions.voices ?? 0;

    if (!voices) {
      throw new Error('krar-processor needs processorOptions.voices');
    }

    this.port.onmessage = (event) => handleMessage(event.data);
    this._ready = this._setup(voices);
  }

  async _setup(voices) {
    await init();
    // Rust `new` is a static factory, not a wasm-bindgen constructor.
    // `sampleRate` is this worklet's own rate, so the delay lines are cut
    // for the hardware we actually got, whatever it is.
    engine = KrarEngine.new(sampleRate, voices);
    if (engine.num_strings() !== voices) {
      throw new Error(
        `engine came up with ${engine.num_strings()} voices, expected ${voices}`,
      );
    }
    const queued = pending;
    pending = [];
    for (const msg of queued) handleMessage(msg);
  }

  process(_inputs, outputs) {
    const output = outputs[0];
    if (!engine) {
      // Still compiling the wasm; output silence until it is ready.
      for (let channel = 0; channel < output.length; channel++) {
        output[channel].fill(0);
      }
      return true;
    }
    const block = engine.get_audio_buffer();
    for (let channel = 0; channel < output.length; channel++) {
      output[channel].set(block);
    }
    return true;
  }
}

registerProcessor('krar-processor', KrarProcessor);
