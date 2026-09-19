import 'dart:js_interop';
import 'dart:typed_data';

import '../models/qenet.dart';
import '../models/string_config.dart';
import 'audio_bridge.dart';

class KrarEngine {
  KrarEngineJS? _engine;
  bool _isInitialized = false;

  /// Begena strings; voice [previewVoice] is reserved for single notes
  /// (scale degrees, tab playback) so they never retune a string.
  static const int stringCount = 5;
  static const int previewVoice = 5;

  Future<void> initialize() async {
    await waitForBridge();
    await initAudioJS();
    await startAudioJS();
    _engine = getKrarEngineJS();
    if (_engine == null) {
      throw StateError('Audio bridge did not expose its engine');
    }
    for (final s in StringConfig.begenaStrings) {
      _engine!.setStringFrequency(s.id, s.frequency);
    }
    _isInitialized = true;
  }

  /// Call from a user gesture: browsers start the AudioContext suspended.
  Future<void> resume() async {
    if (_isInitialized) await resumeAudioJS();
  }

  void pluck(int stringId, double velocity) {
    if (!_isInitialized) return;
    _engine!.pluck(stringId, velocity);
  }

  /// Plays one note at [frequency] on the preview voice.
  void playFrequency(double frequency, {double velocity = 0.8}) {
    if (!_isInitialized) return;
    _engine!.setStringFrequency(previewVoice, frequency);
    _engine!.pluck(previewVoice, velocity);
  }

  void release(int stringId) {
    if (!_isInitialized) return;
    _engine!.release(stringId);
  }

  void setScale(ScaleType scaleType) {
    if (!_isInitialized) return;
    _engine!.setScale(scaleType.index);
  }

  /// Output samples for the oscilloscope. Empty before audio starts.
  Float32List waveform() => _isInitialized ? (getWaveformJS()?.toDart ?? Float32List(0)) : Float32List(0);

  double getStringFrequency(int stringId) {
    if (!_isInitialized) return 0.0;
    return _engine!.getStringFrequency(stringId);
  }

  void setStringFrequency(int stringId, double frequency) {
    if (!_isInitialized) return;
    _engine!.setStringFrequency(stringId, frequency);
  }

  void setMasterVolume(double volume) {
    if (!_isInitialized) return;
    _engine!.setMasterVolume(volume);
  }

  double getMasterVolume() => _isInitialized ? _engine!.getMasterVolume() : 0.0;

  void setReverb(double amount) {
    if (!_isInitialized) return;
    _engine!.setReverb(amount);
  }

  double getReverb() => _isInitialized ? _engine!.getReverb() : 0.0;

  int get numStrings => stringCount;

  List<double> getStringConfig(int stringId) {
    if (!_isInitialized) return const [];
    return _engine!.getStringConfig(stringId).toDart.toList();
  }

  bool get isInitialized => _isInitialized;

  void dispose() {
    _isInitialized = false;
    _engine = null;
  }
}
