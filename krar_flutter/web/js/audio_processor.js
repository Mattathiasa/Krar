// Runs the WASM string engine on the audio thread, so a busy UI can no
// longer interrupt the sound. The main thread only sends control messages
// and hands over the engine class (already initialised by the bridge, which
// is the one place that can fetch the wasm); it never waits for a buffer.

let engine = null;
let EngineClass = null;
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
    EngineClass = processorOptions.engine;
    const voices = processorOptions.voices ?? 0;

    if (typeof EngineClass !== 'function' || !voices) {
      throw new Error('krar-processor needs processorOptions.engine and processorOptions.voices');
    }

    // Rust `new` is a static factory, not a wasm-bindgen constructor.
    // `sampleRate` is this worklet's own rate, so the delay lines are cut
    // for the hardware we actually got, whatever it is.
    engine = EngineClass.new(sampleRate, voices);
    if (engine.num_strings() !== voices) {
      throw new Error(`engine came up with ${engine.num_strings()} voices, expected ${voices}`);
    }

    this.port.onmessage = (event) => handleMessage(event.data);

    for (const msg of pending) handleMessage(msg);
    pending = [];
  }

  process(_inputs, outputs) {
    const output = outputs[0];
    const block = engine.get_audio_buffer();
    for (let channel = 0; channel < output.length; channel++) {
      output[channel].set(block);
    }
    return true;
  }
}

registerProcessor('krar-processor', KrarProcessor);
