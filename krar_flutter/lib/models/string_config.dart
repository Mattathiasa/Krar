class StringConfig {
  final int id;
  final String name;
  final double frequency;

  const StringConfig({
    required this.id,
    required this.name,
    required this.frequency,
  });

  static const begenaStrings = [
    StringConfig(id: 0, name: 'Db2', frequency: 69.0),
    StringConfig(id: 1, name: 'Ab2', frequency: 104.0),
    StringConfig(id: 2, name: 'Eb3', frequency: 156.0),
    StringConfig(id: 3, name: 'Bb3', frequency: 233.0),
    StringConfig(id: 4, name: 'F4', frequency: 349.0),
  ];
}
