import 'dart:math';

/// Equal-tempered piano keys, by MIDI note number (60 = middle C).
class PianoKey {
  const PianoKey(this.midi);

  final int midi;

  static const _names = ['C', 'C♯', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B'];

  bool get isBlack => const {1, 3, 6, 8, 10}.contains(midi % 12);

  String get name => '${_names[midi % 12]}${midi ~/ 12 - 1}';

  /// A4 = 440 Hz.
  double get frequency => 440.0 * pow(2, (midi - 69) / 12).toDouble();
}

/// The qenet on the Piano page are built on middle C.
const int kQenetRootMidi = 60;
