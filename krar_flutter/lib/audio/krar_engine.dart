import 'dart:js_interop';
import 'audio_bridge.dart';
import '../widgets/scale_selector.dart';

class KrarEngine {
  KrarEngineJS? _engine;
  bool _isInitialized = false;
  final int _sampleRate = 48000;
  final int _numStrings = 5;

  Future<void> initialize() async {
    try {
      await initAudioJS();
      await startAudioJS();
      _engine = KrarEngineJS(_sampleRate, _numStrings);
      _isInitialized = true;
    } catch (e) {
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
    final jsArray = _engine!.getAudioBuffer();
    final dartList = <double>[];
    for (var i = 0; i < jsArray.length; i++) {
      dartList.add((jsArray[i] as JSNumber).toDartDouble);
    }
    return dartList;
  }

  double getStringFrequency(int stringId) {
    if (!_isInitialized || _engine == null) return 0.0;
    return _engine!.getStringFrequency(stringId);
  }

  void setStringFrequency(int stringId, double frequency) {
    if (!_isInitialized || _engine == null) return;
    _engine!.setStringFrequency(stringId, frequency);
  }

  void setMasterVolume(double volume) {
    if (!_isInitialized || _engine == null) return;
    _engine!.setMasterVolume(volume);
  }

  double getMasterVolume() {
    if (!_isInitialized || _engine == null) return 0.0;
    return _engine!.getMasterVolume();
  }

  void setReverb(double amount) {
    if (!_isInitialized || _engine == null) return;
    _engine!.setReverb(amount);
  }

  double getReverb() {
    if (!_isInitialized || _engine == null) return 0.0;
    return _engine!.getReverb();
  }

  int get numStrings {
    if (!_isInitialized || _engine == null) return 0;
    return _engine!.numStrings();
  }

  List<double> getStringConfig(int stringId) {
    if (!_isInitialized || _engine == null) return [];
    final jsArray = _engine!.getStringConfig(stringId);
    final dartList = <double>[];
    for (var i = 0; i < jsArray.length; i++) {
      dartList.add((jsArray[i] as JSNumber).toDartDouble);
    }
    return dartList;
  }

  bool get isInitialized => _isInitialized;

  void dispose() {
    _isInitialized = false;
    _engine = null;
  }
}
