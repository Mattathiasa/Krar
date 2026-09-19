import init, { KrarEngine } from '../pkg/krar_engine.js';

let engine = null;
let audioContext = null;
let audioWorkletNode = null;
let analyser = null;
let waveform = null;

// 5 begena strings, one preview voice for scale degrees and tab playback,
// and 8 piano voices. Matches KrarEngine.voiceCount in Dart.
const NUM_VOICES = 14;
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

export async function startAudio() {
  try {
    if (isStarted) return;

    audioContext = new (window.AudioContext || window.webkitAudioContext)({
      sampleRate: 48000,
    });

    await audioContext.audioWorklet.addModule('js/audio_processor.js');

    audioWorkletNode = new AudioWorkletNode(audioContext, 'krar-processor', {
      numberOfInputs: 0,
      numberOfOutputs: 1,
      outputChannelCount: [2],
    });

    // Rust `new` is a static factory, not a wasm-bindgen constructor.
    engine = KrarEngine.new(48000, NUM_VOICES);

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
