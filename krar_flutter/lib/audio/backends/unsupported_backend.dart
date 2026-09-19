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
  void setScale(int scaleIndex) {}

  @override
  void setStringFrequency(int string, double frequency) {}

  @override
  double getStringFrequency(int string) => 0;

  @override
  void setMasterVolume(double volume) {}

  @override
  double getMasterVolume() => 0;

  @override
  void setReverb(double amount) {}

  @override
  double getReverb() => 0;

  @override
  List<double> stringConfig(int string) => const [];

  @override
  Float32List waveform() => Float32List(0);
}
