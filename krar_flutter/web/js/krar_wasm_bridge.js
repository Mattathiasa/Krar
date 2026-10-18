import init from '../pkg/krar_engine.js';

let audioContext = null;
let audioWorkletNode = null;
let analyser = null;
let waveform = null;
let isStarted = false;

export async function initAudio() {
  try {
    // The worklet compiles its own copy of the engine from here; the glue
    // fetches the wasm relative to this module, so no plumbing is needed.
    // This warms the main-thread copy so the first pluck is not late.
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

    // No forced rate: the engine is built inside the worklet at that
    // worklet's own sampleRate, so pitch stays correct on hardware that
    // will not do 48 kHz.
    audioContext = new (window.AudioContext || window.webkitAudioContext)();

    await audioContext.audioWorklet.addModule('js/audio_processor.js');

    audioWorkletNode = new AudioWorkletNode(audioContext, 'krar-processor', {
      numberOfInputs: 0,
      numberOfOutputs: 1,
      outputChannelCount: [2],
      processorOptions: { voices },
    });

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
  analyser = null;
  isStarted = false;
  console.log('Audio stopped');
}

export function isAudioStarted() {
  return isStarted;
}

function post(msg) {
  if (audioWorkletNode) audioWorkletNode.port.postMessage(msg);
}

// Control messages into the worklet. The engine lives there; these are the
// only way the main thread talks to it.
export function pluckVoice(string, velocity) {
  post({ type: 'pluck', string, velocity });
}

export function strikeVoice(string, velocity) {
  post({ type: 'strike', string, velocity });
}

export function releaseVoice(string) {
  post({ type: 'release', string });
}

export function setVoiceFrequency(string, frequency) {
  post({ type: 'setFrequency', string, frequency });
}

export function setMasterVolume(volume) {
  post({ type: 'setVolume', volume });
}

export function setReverb(amount) {
  post({ type: 'setReverb', amount });
}

// Browsers keep an AudioContext suspended until a user gesture.
export async function resumeAudio() {
  if (audioContext && audioContext.state === 'suspended') {
    await audioContext.resume();
  }
}

// Latest output samples, for the on-screen oscilloscope. The AnalyserNode
// sits on the main thread, so this stays a cheap synchronous read.
export function getWaveform() {
  if (!analyser) return null;
  analyser.getFloatTimeDomainData(waveform);
  return waveform;
}

window.initAudio = initAudio;
window.startAudio = startAudio;
window.stopAudio = stopAudio;
window.isAudioStarted = isAudioStarted;
window.pluckVoice = pluckVoice;
window.strikeVoice = strikeVoice;
window.releaseVoice = releaseVoice;
window.setVoiceFrequency = setVoiceFrequency;
window.setMasterVolume = setMasterVolume;
window.setReverb = setReverb;
window.resumeAudio = resumeAudio;
window.getWaveform = getWaveform;
