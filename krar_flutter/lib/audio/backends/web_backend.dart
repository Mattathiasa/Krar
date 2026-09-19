import 'dart:js_interop';
import 'dart:typed_data';

import '../krar_backend.dart';
import 'web_bridge.dart';

KrarBackend createKrarBackend() => _WebBackend();

/// Drives the WASM engine that web/js/krar_wasm_bridge.js feeds to an AudioWorklet.
class _WebBackend implements KrarBackend {
  KrarEngineJS? _engine;

  @override
  Future<void> start(int voices) async {
    // The bridge creates its engine with a fixed voice count (NUM_VOICES).
    await waitForBridge();
    await initAudioJS();
    await startAudioJS();
    _engine = getKrarEngineJS();
    if (_engine == null) throw StateError('Audio bridge did not expose its engine');
  }

  @override
  Future<void> resume() => resumeAudioJS();

  @override
  void pluck(int string, double velocity) => _engine?.pluck(string, velocity);

  @override
  void strike(int string, double velocity) => _engine?.strike(string, velocity);

  @override
  void release(int string) => _engine?.release(string);

  @override
  void setScale(int scaleIndex) => _engine?.setScale(scaleIndex);

  @override
  void setStringFrequency(int string, double frequency) => _engine?.setStringFrequency(string, frequency);

  @override
  double getStringFrequency(int string) => _engine?.getStringFrequency(string) ?? 0;

  @override
  void setMasterVolume(double volume) => _engine?.setMasterVolume(volume);

  @override
  double getMasterVolume() => _engine?.getMasterVolume() ?? 0;

  @override
  void setReverb(double amount) => _engine?.setReverb(amount);

  @override
  double getReverb() => _engine?.getReverb() ?? 0;

  @override
  List<double> stringConfig(int string) => _engine?.getStringConfig(string).toDart.toList() ?? const [];

  @override
  Float32List waveform() => getWaveformJS()?.toDart ?? Float32List(0);
}
