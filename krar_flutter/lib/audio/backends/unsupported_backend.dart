import 'dart:typed_data';

import '../krar_backend.dart';

KrarBackend createKrarBackend() => _UnsupportedBackend();

class _UnsupportedBackend implements KrarBackend {
  @override
  Future<void> start(int voices) async => throw UnsupportedError('No Krar audio backend on this platform');

  @override
  Future<void> resume() async {}

  @override
  void pluck(int string, double velocity) {}

  @override
  void strike(int string, double velocity) {}

  @override
  void release(int string) {}

  @override
  void setStringFrequency(int string, double frequency) {}

  @override
  void setMasterVolume(double volume) {}

  @override
  void setReverb(double amount) {}

  @override
  Float32List waveform() => Float32List(0);
}
