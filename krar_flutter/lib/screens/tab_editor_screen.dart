import 'package:flutter/material.dart';
import '../widgets/tab_editor.dart';
import '../audio/krar_engine.dart';

class TabEditorScreen extends StatefulWidget {
  final KrarEngine engine;

  const TabEditorScreen({
    super.key,
    required this.engine,
  });

  @override
  State<TabEditorScreen> createState() => _TabEditorScreenState();
}

class _TabEditorScreenState extends State<TabEditorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        title: const Text(
          'Tab Editor',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TabEditor(
              onNoteSelected: (string, fret) {
                _playNote(string, fret);
              },
              numStrings: 5,
            ),
            const SizedBox(height: 16.0),
            _buildPlaybackControls(),
          ],
        ),
      ),
    );
  }

  void _playNote(int string, int fret) {
    final frequencies = [
      69.0,
      104.0,
      156.0,
      233.0,
      349.0,
    ];

    if (string >= 0 && string < frequencies.length) {
      widget.engine.pluck(string, 0.8);
    }
  }

  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFF0F3460),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(
              Icons.skip_previous,
              color: Colors.white70,
            ),
            onPressed: () {},
            tooltip: 'Previous',
          ),
          IconButton(
            icon: const Icon(
              Icons.play_arrow,
              color: Color(0xFFE94560),
              size: 32.0,
            ),
            onPressed: () {},
            tooltip: 'Play',
          ),
          IconButton(
            icon: const Icon(
              Icons.stop,
              color: Colors.white70,
            ),
            onPressed: () {},
            tooltip: 'Stop',
          ),
          IconButton(
            icon: const Icon(
              Icons.skip_next,
              color: Colors.white70,
            ),
            onPressed: () {},
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }
}
