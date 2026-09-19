import 'dart:js_interop';

@JS('KrarEngine')
class KrarEngineJS {
  external factory KrarEngineJS(int sampleRate, int numStrings);

  external void pluck(int stringId, double velocity);
  external void release(int stringId);
  external void setScale(int scaleType);
  external Float32List getAudioBuffer();
  external double getStringFrequency(int stringId);
  external void setStringFrequency(int stringId, double frequency);
}

@JS('initAudio')
external PromiseJSObject<void> initAudioJS();

@JS('startAudio')
external PromiseJSObject<void> startAudioJS();

@JS('stopAudio')
external PromiseJSObject<void> stopAudioJS();
