import 'dart:typed_data';

import '../models/qenet.dart';
import '../models/string_config.dart';
import 'krar_backend.dart';

/// The app's handle on the Rust string engine, whichever platform it runs on.
class KrarEngine {
  KrarEngine({KrarBackend? backend}) : _backend = backend ?? createKrarBackend();

  final KrarBackend _backend;
  bool _isInitialized = false;

  /// Voice layout: the begena strings, one preview voice for single notes
  /// (scale degrees, tab playback) so they never retune a string, then a
  /// pool of piano voices. web/js/krar_wasm_bridge.js uses the same count.
  static const int stringCount = 5;
  static const int previewVoice = 5;
  static const int firstPianoVoice = 6;
  static const int pianoVoiceCount = 8;
  static const int voiceCount = firstPianoVoice + pianoVoiceCount;

  int _nextPianoVoice = 0;

  Future<void> initialize() async {
    await _backend.start(voiceCount);
    for (final s in StringConfig.begenaStrings) {
      _backend.setStringFrequency(s.id, s.frequency);
    }
    _isInitialized = true;
  }

  /// Call from a user gesture: browsers start audio suspended.
  Future<void> resume() async {
    if (_isInitialized) await _backend.resume();
  }

  void pluck(int stringId, double velocity) {
    if (_isInitialized) _backend.pluck(stringId, velocity);
  }

  /// Plays one note at [frequency] on the preview voice.
  void playFrequency(double frequency, {double velocity = 0.8}) {
    if (!_isInitialized) return;
    _backend.setStringFrequency(previewVoice, frequency);
    _backend.pluck(previewVoice, velocity);
  }

  /// Strikes a piano note at [frequency], taking the next voice in the pool
  /// so up to [pianoVoiceCount] notes ring at once.
  void playPiano(double frequency, {double velocity = 0.8}) {
    if (!_isInitialized) return;
    final voice = firstPianoVoice + _nextPianoVoice;
    _nextPianoVoice = (_nextPianoVoice + 1) % pianoVoiceCount;
    _backend.setStringFrequency(voice, frequency);
    _backend.strike(voice, velocity);
  }

  void release(int stringId) {
    if (_isInitialized) _backend.release(stringId);
  }

  void setScale(ScaleType scaleType) {
    if (_isInitialized) _backend.setScale(scaleType.index);
  }

  /// Output samples for the oscilloscope. Empty before audio starts.
  Float32List waveform() => _isInitialized ? _backend.waveform() : Float32List(0);

  double getStringFrequency(int stringId) => _isInitialized ? _backend.getStringFrequency(stringId) : 0.0;

  void setStringFrequency(int stringId, double frequency) {
    if (_isInitialized) _backend.setStringFrequency(stringId, frequency);
  }

  void setMasterVolume(double volume) {
    if (_isInitialized) _backend.setMasterVolume(volume);
  }

  double getMasterVolume() => _isInitialized ? _backend.getMasterVolume() : 0.0;

  void setReverb(double amount) {
    if (_isInitialized) _backend.setReverb(amount);
  }

  double getReverb() => _isInitialized ? _backend.getReverb() : 0.0;

  int get numStrings => stringCount;

  List<double> getStringConfig(int stringId) => _isInitialized ? _backend.stringConfig(stringId) : const [];

  bool get isInitialized => _isInitialized;

  void dispose() {
    _isInitialized = false;
  }
}
