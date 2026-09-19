class EthiopianScale {
  final String name;
  final List<double> centsFromRoot;
  final List<double> intervals;

  const EthiopianScale({
    required this.name,
    required this.centsFromRoot,
    required this.intervals,
  });

  static const tizitaMinor = EthiopianScale(
    name: 'Tizita Minor',
    centsFromRoot: [0, 282, 386, 520, 678, 884, 1018, 1136],
    intervals: [1.0, 1.189, 1.261, 1.337, 1.417, 1.500, 1.587, 1.682],
  );

  static const tizitaMajor = EthiopianScale(
    name: 'Tizita Major',
    centsFromRoot: [0, 282, 386, 520, 678, 884, 1018, 1136],
    intervals: [1.0, 1.189, 1.261, 1.337, 1.417, 1.500, 1.587, 1.682],
  );

  static const ambassel = EthiopianScale(
    name: 'Ambassel',
    centsFromRoot: [0, 182, 316, 520, 678, 812, 1018, 1136],
    intervals: [1.0, 1.107, 1.199, 1.337, 1.417, 1.500, 1.587, 1.682],
  );

  static const bati = EthiopianScale(
    name: 'Bati',
    centsFromRoot: [0, 182, 316, 498, 678, 884, 1018, 1136],
    intervals: [1.0, 1.107, 1.199, 1.337, 1.417, 1.500, 1.587, 1.682],
  );

  static const List<EthiopianScale> allScales = [
    tizitaMinor,
    tizitaMajor,
    ambassel,
    bati,
  ];

  double getFrequencyFromRoot(double rootFreq, int degree) {
    if (degree < 0 || degree >= intervals.length) return rootFreq;
    return rootFreq * intervals[degree];
  }

  double getCents(int degree) {
    if (degree < 0 || degree >= centsFromRoot.length) return 0.0;
    return centsFromRoot[degree];
  }
}
