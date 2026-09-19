import 'dart:js_interop';
import 'package:web/web.dart' as web;

extension type KrarEngineJS._(JSObject _) implements JSObject {
  external factory KrarEngineJS(int sampleRate, int numStrings);

  external void pluck(int stringId, double velocity);
  external void release(int stringId);
  external void setScale(int scaleType);
  external JSArray getAudioBuffer();
  external double getStringFrequency(int stringId);
  external void setStringFrequency(int stringId, double frequency);
  external void setMasterVolume(double volume);
  external double getMasterVolume();
  external void setReverb(double amount);
  external double getReverb();
  external int numStrings();
  external JSArray getStringConfig(int stringId);
}

Future<void> initAudioJS() async {
  final fn = web.window['initAudio'] as JSFunction?;
  if (fn != null) {
    final promise = fn.callAsFunction() as JSPromise<JSAny?>?;
    await promise?.toDart;
  }
}

Future<void> startAudioJS() async {
  final fn = web.window['startAudio'] as JSFunction?;
  if (fn != null) {
    final promise = fn.callAsFunction() as JSPromise<JSAny?>?;
    await promise?.toDart;
  }
}

Future<void> stopAudioJS() async {
  final fn = web.window['stopAudio'] as JSFunction?;
  if (fn != null) {
    final promise = fn.callAsFunction() as JSPromise<JSAny?>?;
    await promise?.toDart;
  }
}

bool isAudioStartedJS() {
  final fn = web.window['isAudioStarted'] as JSFunction?;
  if (fn != null) {
    final result = fn.callAsFunction() as JSBoolean?;
    return result?.toDart ?? false;
  }
  return false;
}
