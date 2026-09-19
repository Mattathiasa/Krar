import 'package:flutter/material.dart';

class TabEditor extends StatefulWidget {
  final Function(int string, int fret) onNoteSelected;
  final int numStrings;

  const TabEditor({
    super.key,
    required this.onNoteSelected,
    this.numStrings = 5,
  });

  @override
  State<TabEditor> createState() => _TabEditorState();
}

class _TabEditorState extends State<TabEditor> {
  final List<List<int>> _tabData = [];
  int _selectedMeasure = 0;
  int _selectedBeat = 0;
  final int _beatsPerMeasure = 4;

  @override
  void initState() {
    super.initState();
    _initializeTab();
  }

  void _initializeTab() {
    for (int i = 0; i < widget.numStrings; i++) {
      _tabData.add(List.filled(16, -1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1511),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFF3B3229),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tab,
                color: Color(0xFFE8B04A),
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              const Text(
                'Tab Editor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.add,
                  color: Colors.white70,
                ),
                onPressed: _addMeasure,
                tooltip: 'Add Measure',
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.white70,
                ),
                onPressed: _clearTab,
                tooltip: 'Clear Tab',
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildTabGrid(),
          const SizedBox(height: 16.0),
          _buildNoteInput(),
        ],
      ),
    );
  }

  Widget _buildTabGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          _buildStringRow(0, 'F4'),
          _buildStringRow(1, 'Bb3'),
          _buildStringRow(2, 'Eb3'),
          _buildStringRow(3, 'Ab2'),
          _buildStringRow(4, 'Db2'),
        ],
      ),
    );
  }

  Widget _buildStringRow(int stringIndex, String stringName) {
    return Row(
      children: [
        SizedBox(
          width: 40.0,
          child: Text(
            stringName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.0,
            ),
          ),
        ),
        ...List.generate(16, (beatIndex) {
          final note = _tabData[stringIndex][beatIndex];
          final isSelected = _selectedMeasure * _beatsPerMeasure + _selectedBeat == beatIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMeasure = beatIndex ~/ _beatsPerMeasure;
                _selectedBeat = beatIndex % _beatsPerMeasure;
              });
            },
            child: Container(
              width: 40.0,
              height: 32.0,
              margin: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE8B04A).withAlpha(50)
                    : const Color(0xFF3B3229),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE8B04A)
                      : const Color(0xFF1A1511),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  note >= 0 ? note.toString() : '-',
                  style: TextStyle(
                    color: note >= 0 ? Colors.white : Colors.white38,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNoteInput() {
    return Row(
      children: [
        const Text(
          'Fret: ',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12.0,
          ),
        ),
        ...List.generate(13, (fretIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: GestureDetector(
              onTap: () {
                _setNote(fretIndex);
              },
              child: Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B3229),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(
                    color: const Color(0xFF1A1511),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    fretIndex.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _setNote(int fret) {
    final beatIndex = _selectedMeasure * _beatsPerMeasure + _selectedBeat;
    setState(() {
      for (int i = 0; i < widget.numStrings; i++) {
        _tabData[i][beatIndex] = -1;
      }
    });

    widget.onNoteSelected(0, fret);

    setState(() {
      _selectedBeat++;
      if (_selectedBeat >= _beatsPerMeasure) {
        _selectedBeat = 0;
        _selectedMeasure++;
      }
    });
  }

  void _addMeasure() {
    for (int i = 0; i < widget.numStrings; i++) {
      _tabData[i].addAll(List.filled(_beatsPerMeasure, -1));
    }
  }

  void _clearTab() {
    for (int i = 0; i < widget.numStrings; i++) {
      for (int j = 0; j < _tabData[i].length; j++) {
        _tabData[i][j] = -1;
      }
    }
  }

  List<List<int>> getTabData() => _tabData;
}
