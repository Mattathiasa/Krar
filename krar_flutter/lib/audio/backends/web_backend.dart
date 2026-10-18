import 'dart:js_interop';
import 'dart:typed_data';

import '../krar_backend.dart';
import 'web_bridge.dart';

KrarBackend createKrarBackend() => _WebBackend();

/// Drives the WASM engine that lives inside the AudioWorklet (see
/// web/js/krar_wasm_bridge.js). Every call is a control message posted to
/// the worklet; the engine itself never runs on the main thread.
class _WebBackend implements KrarBackend {
  @override
  Future<void> start(int voices) async {
    await waitForBridge();
    await initAudioJS();
    await startAudioJS(voices);
  }

  @override
  Future<void> resume() => resumeAudioJS();

  @override
  void pluck(int string, double velocity) => pluckVoiceJS(string, velocity);

  @override
  void strike(int string, double velocity) => strikeVoiceJS(string, velocity);

  @override
  void release(int string) => releaseVoiceJS(string);

  @override
  void setStringFrequency(int string, double frequency) => setVoiceFrequencyJS(string, frequency);

  @override
  void setMasterVolume(double volume) => setMasterVolumeJS(volume);

  @override
  void setReverb(double amount) => setReverbJS(amount);

  @override
  Float32List waveform() => getWaveformJS()?.toDart ?? Float32List(0);
}
