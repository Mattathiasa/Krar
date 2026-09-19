class StringConfig {
  final int id;
  final String name;
  final double frequency;
  final double tension;
  final double length;
  final double mass;
  final double damping;

  const StringConfig({
    required this.id,
    required this.name,
    required this.frequency,
    this.tension = 1.0,
    this.length = 1.0,
    this.mass = 0.01,
    this.damping = 0.001,
  });

  static const begenaStrings = [
    StringConfig(id: 0, name: 'Db2', frequency: 69.0, tension: 0.8, length: 0.9, mass: 0.012, damping: 0.0015),
    StringConfig(id: 1, name: 'Ab2', frequency: 104.0, tension: 0.8, length: 0.9, mass: 0.012, damping: 0.0015),
    StringConfig(id: 2, name: 'Eb3', frequency: 156.0, tension: 0.8, length: 0.9, mass: 0.012, damping: 0.0015),
    StringConfig(id: 3, name: 'Bb3', frequency: 233.0, tension: 0.8, length: 0.9, mass: 0.012, damping: 0.0015),
    StringConfig(id: 4, name: 'F4', frequency: 349.0, tension: 0.8, length: 0.9, mass: 0.012, damping: 0.0015),
  ];
}
