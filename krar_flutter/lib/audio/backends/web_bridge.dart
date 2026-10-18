import 'dart:js_interop';
import 'package:web/web.dart' as web;

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

Future<void> _callAsyncInt(String name, int arg) async {
  final fn = _bridgeFn(name);
  if (fn == null) return;
  final promise = fn.callAsFunction(null, arg.toJS) as JSPromise<JSAny?>?;
  await promise?.toDart;
}

void _post2(String name, int a, double b) {
  _bridgeFn(name)?.callAsFunction(null, a.toJS, b.toJS);
}

void _post1(String name, int a) {
  _bridgeFn(name)?.callAsFunction(null, a.toJS);
}

void _postDouble(String name, double v) {
  _bridgeFn(name)?.callAsFunction(null, v.toJS);
}

Future<void> initAudioJS() => _callAsync('initAudio');

/// [voices] is the engine's voice count (KrarEngine.voiceCount in Dart).
Future<void> startAudioJS(int voices) => _callAsyncInt('startAudio', voices);

Future<void> stopAudioJS() => _callAsync('stopAudio');

Future<void> resumeAudioJS() => _callAsync('resumeAudio');

bool isAudioStartedJS() {
  final result = _bridgeFn('isAudioStarted')?.callAsFunction() as JSBoolean?;
  return result?.toDart ?? false;
}

// The engine lives inside the AudioWorklet; these post control messages to it.

void pluckVoiceJS(int string, double velocity) => _post2('pluckVoice', string, velocity);

void strikeVoiceJS(int string, double velocity) => _post2('strikeVoice', string, velocity);

void releaseVoiceJS(int string) => _post1('releaseVoice', string);

void setVoiceFrequencyJS(int string, double frequency) => _post2('setVoiceFrequency', string, frequency);

void setMasterVolumeJS(double volume) => _postDouble('setMasterVolume', volume);

void setReverbJS(double amount) => _postDouble('setReverb', amount);

/// Latest output samples from the AnalyserNode, or null before audio starts.
JSFloat32Array? getWaveformJS() => _bridgeFn('getWaveform')?.callAsFunction() as JSFloat32Array?;
