import 'dart:typed_data';

export 'backends/unsupported_backend.dart'
    if (dart.library.js_interop) 'backends/web_backend.dart'
    if (dart.library.ffi) 'backends/native_backend.dart';

/// One platform's route to the Rust string engine: WASM plus an AudioWorklet
/// on the web, a native library rendering to CoreAudio on iOS.
abstract class KrarBackend {
  /// Loads the engine and starts audio output with [voices] strings.
  Future<void> start(int voices);

  /// Called from user gestures; browsers keep audio suspended until one.
  Future<void> resume();

  void pluck(int string, double velocity);

  /// Sounds a voice with a piano hammer instead of a pluck.
  void strike(int string, double velocity);
  void release(int string);
  void setScale(int scaleIndex);
  void setStringFrequency(int string, double frequency);
  double getStringFrequency(int string);
  void setMasterVolume(double volume);
  double getMasterVolume();
  void setReverb(double amount);
  double getReverb();

  /// [frequency, velocity, isPlucked, decay] for one string.
  List<double> stringConfig(int string);

  /// The most recent output samples, oldest first.
  Float32List waveform();
}
