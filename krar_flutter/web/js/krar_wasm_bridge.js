import init, { KrarEngine } from '../pkg/krar_engine.js';

let engine = null;
let audioContext = null;
let audioWorkletNode = null;
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

    engine = new KrarEngine(48000, 5);

    audioWorkletNode.port.onmessage = (event) => {
      if (event.data.type === 'getBuffer') {
        const buffer = engine.get_audio_buffer();
        audioWorkletNode.port.postMessage({
          type: 'buffer',
          buffer: buffer,
        });
      }
    };

    audioWorkletNode.connect(audioContext.destination);
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
  isStarted = false;
  console.log('Audio stopped');
}

export function isAudioStarted() {
  return isStarted;
}

window.KrarEngine = KrarEngine;
window.initAudio = initAudio;
window.startAudio = startAudio;
window.stopAudio = stopAudio;
window.isAudioStarted = isAudioStarted;
