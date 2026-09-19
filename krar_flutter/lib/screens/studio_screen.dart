import 'package:flutter/material.dart';
import '../widgets/string_canvas.dart';
import '../widgets/scale_selector.dart';
import '../widgets/scale_visualizer.dart';
import '../audio/krar_engine.dart';
import 'tab_editor_screen.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  late KrarEngine _engine;
  bool _isInitialized = false;
  double _volume = 0.8;
  double _reverb = 0.2;
  ScaleType _currentScale = ScaleType.tizitaMinor;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    _engine = KrarEngine();
    await _engine.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        title: const Text(
          'Krar & Begena Studio',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tab),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TabEditorScreen(engine: _engine),
                ),
              );
            },
            tooltip: 'Tab Editor',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
      body: _isInitialized
          ? Column(
              children: [
                ScaleSelector(
                  onScaleChanged: (scaleType) {
                    setState(() {
                      _currentScale = scaleType;
                    });
                    _engine.setScale(scaleType);
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        StringCanvas(
                          engine: _engine,
                          numStrings: 5,
                        ),
                        ScaleVisualizer(
                          currentScale: _currentScale,
                          rootFrequency: 130.81,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildControlPanel(),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFE94560),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Initializing Audio Engine...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(
          top: BorderSide(
            color: Color(0xFF0F3460),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.volume_down,
                color: Colors.white70,
                size: 20.0,
              ),
              Expanded(
                child: Slider(
                  value: _volume,
                  onChanged: (value) {
                    setState(() {
                      _volume = value;
                    });
                    _engine.setMasterVolume(value);
                  },
                  activeColor: const Color(0xFFE94560),
                  inactiveColor: const Color(0xFF0F3460),
                ),
              ),
              const Icon(
                Icons.volume_up,
                color: Colors.white70,
                size: 20.0,
              ),
              const SizedBox(width: 16.0),
              const Icon(
                Icons.water_drop,
                color: Colors.white70,
                size: 20.0,
              ),
              Expanded(
                child: Slider(
                  value: _reverb,
                  onChanged: (value) {
                    setState(() {
                      _reverb = value;
                    });
                    _engine.setReverb(value);
                  },
                  activeColor: const Color(0xFF533483),
                  inactiveColor: const Color(0xFF0F3460),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoChip('Strings', '${_engine.numStrings}'),
              _buildInfoChip('Sample Rate', '48kHz'),
              _buildInfoChip('Latency', '~2.7ms'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 6.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withAlpha(150),
              fontSize: 11.0,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Krar & Begena Studio',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Microtonal Acoustic Synthesizer',
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 14.0,
              ),
            ),
            const SizedBox(height: 16.0),
            _buildInfoRow('Audio Engine', 'Karplus-Strong WASM'),
            _buildInfoRow('Scale System', 'Ethiopian Microtonal'),
            _buildInfoRow('Strings', '5-string Begena'),
            _buildInfoRow('Sample Rate', '48kHz'),
            _buildInfoRow('Latency', '~2.7ms'),
            const SizedBox(height: 16.0),
            Text(
              'Built with Flutter Web + Rust WASM',
              style: TextStyle(
                color: Colors.white.withAlpha(100),
                fontSize: 12.0,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFE94560)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(150),
              fontSize: 12.0,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
