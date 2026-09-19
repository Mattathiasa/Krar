import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'audio_bridge.dart';
import '../widgets/scale_selector.dart';

class KrarEngine {
  KrarEngineJS? _engine;
  bool _isInitialized = false;
  int _sampleRate = 48000;
  int _numStrings = 5;

  Future<void> initialize() async {
    try {
      await initAudioJS().toDart;
      _engine = KrarEngineJS(_sampleRate, _numStrings);
      _isInitialized = true;
      print('Krar engine initialized successfully');
    } catch (e) {
      print('Failed to initialize Krar engine: $e');
      rethrow;
    }
  }

  void pluck(int stringId, double velocity) {
    if (!_isInitialized || _engine == null) return;
    _engine!.pluck(stringId, velocity);
  }

  void release(int stringId) {
    if (!_isInitialized || _engine == null) return;
    _engine!.release(stringId);
  }

  void setScale(ScaleType scaleType) {
    if (!_isInitialized || _engine == null) return;
    _engine!.setScale(scaleType.index);
  }

  List<double> getAudioBuffer() {
    if (!_isInitialized || _engine == null) return [];
    return _engine!.getAudioBuffer().toList();
  }

  double getStringFrequency(int stringId) {
    if (!_isInitialized || _engine == null) return 0.0;
    return _engine!.getStringFrequency(stringId);
  }

  void setStringFrequency(int stringId, double frequency) {
    if (!_isInitialized || _engine == null) return;
    _engine!.setStringFrequency(stringId, frequency);
  }

  void dispose() {
    _isInitialized = false;
    _engine = null;
  }
}
