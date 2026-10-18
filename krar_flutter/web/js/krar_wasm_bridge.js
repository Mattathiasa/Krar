import init, { KrarEngine } from '../pkg/krar_engine.js';

let engine = null;
let audioContext = null;
let audioWorkletNode = null;
let analyser = null;
let waveform = null;
let isStarted = false;

export async function initAudio() {
  try {
    await init();
    console.log('WASM module initialized');
  } catch (error) {
    console.error('Failed to initialize WASM:', error);
    throw error;
  }
}

// voices: the engine's voice count, owned by Dart (KrarEngine.voiceCount).
export async function startAudio(voices) {
  try {
    if (isStarted) return;

    // No forced rate: whatever the device gives us, the engine is built to
    // match, so pitch stays correct on hardware that won't do 48 kHz.
    audioContext = new (window.AudioContext || window.webkitAudioContext)();

    await audioContext.audioWorklet.addModule('js/audio_processor.js');

    audioWorkletNode = new AudioWorkletNode(audioContext, 'krar-processor', {
      numberOfInputs: 0,
      numberOfOutputs: 1,
      outputChannelCount: [2],
    });

    // Rust `new` is a static factory, not a wasm-bindgen constructor.
    engine = KrarEngine.new(audioContext.sampleRate, voices);
    if (engine.num_strings() !== voices) {
      throw new Error(`engine created ${engine.num_strings()} voices, expected ${voices}`);
    }

    audioWorkletNode.port.onmessage = (event) => {
      if (event.data.type === 'getBuffer') {
        const buffer = engine.get_audio_buffer();
        audioWorkletNode.port.postMessage({
          type: 'buffer',
          buffer: buffer,
        });
      }
    };

    analyser = audioContext.createAnalyser();
    analyser.fftSize = 1024;
    waveform = new Float32Array(analyser.fftSize);
    audioWorkletNode.connect(analyser);
    analyser.connect(audioContext.destination);
    isStarted = true;
    console.log('Audio started');
  } catch (error) {
    console.error('Failed to start audio:', error);
    throw error;
  }
}

export async function stopAudio() {
  if (audioWorkletNode) {
    audioWorkletNode.disconnect();
    audioWorkletNode = null;
  }
  if (audioContext) {
    await audioContext.close();
    audioContext = null;
  }
  engine = null;
  analyser = null;
  isStarted = false;
  console.log('Audio stopped');
}

export function isAudioStarted() {
  return isStarted;
}

// The engine that feeds the worklet. Dart must pluck this instance, not a new one.
export function getKrarEngine() {
  return engine;
}

// Browsers keep an AudioContext suspended until a user gesture.
export async function resumeAudio() {
  if (audioContext && audioContext.state === 'suspended') {
    await audioContext.resume();
  }
}

// Latest output samples, for the on-screen oscilloscope.
export function getWaveform() {
  if (!analyser) return null;
  analyser.getFloatTimeDomainData(waveform);
  return waveform;
}

window.KrarEngine = KrarEngine;
window.initAudio = initAudio;
window.startAudio = startAudio;
window.stopAudio = stopAudio;
window.isAudioStarted = isAudioStarted;
window.getKrarEngine = getKrarEngine;
window.resumeAudio = resumeAudio;
window.getWaveform = getWaveform;
