import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// The wasm-bindgen `KrarEngine` class. Rust exports snake_case names, so each
/// member maps to its real export with `@JS`.
extension type KrarEngineJS._(JSObject _) implements JSObject {
  external void pluck(int stringId, double velocity);
  external void release(int stringId);
  @JS('set_scale')
  external void setScale(int scaleType);
  @JS('get_audio_buffer')
  external JSFloat32Array getAudioBuffer();
  @JS('get_string_frequency')
  external double getStringFrequency(int stringId);
  @JS('set_string_frequency')
  external void setStringFrequency(int stringId, double frequency);
  @JS('set_master_volume')
  external void setMasterVolume(double volume);
  @JS('get_master_volume')
  external double getMasterVolume();
  @JS('set_reverb')
  external void setReverb(double amount);
  @JS('get_reverb')
  external double getReverb();
  @JS('num_strings')
  external int numStrings();
  @JS('get_string_config')
  external JSFloat32Array getStringConfig(int stringId);
}

JSFunction? _bridgeFn(String name) => web.window[name] as JSFunction?;

/// The bridge is an ES module loaded next to Flutter's bootstrap, so it may
/// not have registered its globals yet when Dart starts.
Future<void> waitForBridge({Duration timeout = const Duration(seconds: 5)}) async {
  final deadline = DateTime.now().add(timeout);
  while (_bridgeFn('initAudio') == null) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('krar_wasm_bridge.js did not load');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

Future<void> _callAsync(String name) async {
  final fn = _bridgeFn(name);
  if (fn == null) return;
  final promise = fn.callAsFunction() as JSPromise<JSAny?>?;
  await promise?.toDart;
}

Future<void> initAudioJS() => _callAsync('initAudio');

Future<void> startAudioJS() => _callAsync('startAudio');

Future<void> stopAudioJS() => _callAsync('stopAudio');

Future<void> resumeAudioJS() => _callAsync('resumeAudio');

bool isAudioStartedJS() {
  final result = _bridgeFn('isAudioStarted')?.callAsFunction() as JSBoolean?;
  return result?.toDart ?? false;
}

/// The engine instance that feeds the AudioWorklet.
KrarEngineJS? getKrarEngineJS() => _bridgeFn('getKrarEngine')?.callAsFunction() as KrarEngineJS?;

/// Latest output samples from the AnalyserNode, or null before audio starts.
JSFloat32Array? getWaveformJS() => _bridgeFn('getWaveform')?.callAsFunction() as JSFloat32Array?;
