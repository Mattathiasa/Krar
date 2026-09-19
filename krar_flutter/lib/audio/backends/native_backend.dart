import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../krar_backend.dart';

KrarBackend createKrarBackend() => _NativeBackend();

typedef _StartC = Int32 Function(Uint32);
typedef _StartDart = int Function(int);
typedef _U32F32C = Void Function(Uint32, Float);
typedef _U32F32Dart = void Function(int, double);
typedef _U32C = Void Function(Uint32);
typedef _U32Dart = void Function(int);
typedef _F32C = Void Function(Float);
typedef _F32Dart = void Function(double);
typedef _GetF32C = Float Function();
typedef _GetF32Dart = double Function();
typedef _U32GetF32C = Float Function(Uint32);
typedef _U32GetF32Dart = double Function(int);
typedef _ConfigC = Void Function(Uint32, Pointer<Float>);
typedef _ConfigDart = void Function(int, Pointer<Float>);
typedef _WaveC = Uint32 Function(Pointer<Float>, Uint32);
typedef _WaveDart = int Function(Pointer<Float>, int);

/// Calls the Rust engine's C ABI (krar_engine/src/native.rs) in the
/// KrarEngine framework. The engine renders to CoreAudio on its own thread.
class _NativeBackend implements KrarBackend {
  static const _waveLen = 1024;

  late final _U32F32Dart _pluck;
  late final _U32F32Dart _strike;
  late final _U32Dart _release;
  late final _U32Dart _setScale;
  late final _U32F32Dart _setFrequency;
  late final _U32GetF32Dart _getFrequency;
  late final _F32Dart _setVolume;
  late final _GetF32Dart _getVolume;
  late final _F32Dart _setReverb;
  late final _GetF32Dart _getReverb;
  late final _ConfigDart _config;
  late final _WaveDart _copyWave;

  bool _ready = false;
  Pointer<Float>? _wave;
  Pointer<Float>? _cfg;

  @override
  Future<void> start(int voices) async {
    if (_ready) return;
    if (!Platform.isIOS) throw UnsupportedError('The native Krar engine is built for iOS only');
    final lib = DynamicLibrary.open('KrarEngine.framework/KrarEngine');

    _pluck = lib.lookupFunction<_U32F32C, _U32F32Dart>('krar_pluck');
    _strike = lib.lookupFunction<_U32F32C, _U32F32Dart>('krar_strike');
    _release = lib.lookupFunction<_U32C, _U32Dart>('krar_release');
    _setScale = lib.lookupFunction<_U32C, _U32Dart>('krar_set_scale');
    _setFrequency = lib.lookupFunction<_U32F32C, _U32F32Dart>('krar_set_string_frequency');
    _getFrequency = lib.lookupFunction<_U32GetF32C, _U32GetF32Dart>('krar_get_string_frequency');
    _setVolume = lib.lookupFunction<_F32C, _F32Dart>('krar_set_master_volume');
    _getVolume = lib.lookupFunction<_GetF32C, _GetF32Dart>('krar_get_master_volume');
    _setReverb = lib.lookupFunction<_F32C, _F32Dart>('krar_set_reverb');
    _getReverb = lib.lookupFunction<_GetF32C, _GetF32Dart>('krar_get_reverb');
    _config = lib.lookupFunction<_ConfigC, _ConfigDart>('krar_string_config');
    _copyWave = lib.lookupFunction<_WaveC, _WaveDart>('krar_copy_waveform');

    final code = lib.lookupFunction<_StartC, _StartDart>('krar_start')(voices);
    if (code != 0) throw StateError('krar_start failed with code $code');

    _wave = calloc<Float>(_waveLen);
    _cfg = calloc<Float>(4);
    _ready = true;
  }

  @override
  Future<void> resume() async {}

  @override
  void pluck(int string, double velocity) {
    if (_ready) _pluck(string, velocity);
  }

  @override
  void strike(int string, double velocity) {
    if (_ready) _strike(string, velocity);
  }

  @override
  void release(int string) {
    if (_ready) _release(string);
  }

  @override
  void setScale(int scaleIndex) {
    if (_ready) _setScale(scaleIndex);
  }

  @override
  void setStringFrequency(int string, double frequency) {
    if (_ready) _setFrequency(string, frequency);
  }

  @override
  double getStringFrequency(int string) => _ready ? _getFrequency(string) : 0;

  @override
  void setMasterVolume(double volume) {
    if (_ready) _setVolume(volume);
  }

  @override
  double getMasterVolume() => _ready ? _getVolume() : 0;

  @override
  void setReverb(double amount) {
    if (_ready) _setReverb(amount);
  }

  @override
  double getReverb() => _ready ? _getReverb() : 0;

  @override
  List<double> stringConfig(int string) {
    if (!_ready) return const [];
    _config(string, _cfg!);
    return _cfg!.asTypedList(4).toList();
  }

  @override
  Float32List waveform() {
    if (!_ready) return Float32List(0);
    final n = _copyWave(_wave!, _waveLen);
    return Float32List.fromList(_wave!.asTypedList(n));
  }
}
