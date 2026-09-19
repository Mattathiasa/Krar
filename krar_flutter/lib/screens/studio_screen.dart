import 'package:flutter/material.dart';
import '../widgets/string_canvas.dart';
import '../widgets/scale_selector.dart';
import '../audio/krar_engine.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  late KrarEngine _engine;
  bool _isInitialized = false;

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
      appBar: AppBar(
        title: const Text('Krar & Begena Studio'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isInitialized
          ? Column(
              children: [
                ScaleSelector(
                  onScaleChanged: (scaleType) {
                    _engine.setScale(scaleType);
                  },
                ),
                Expanded(
                  child: StringCanvas(
                    engine: _engine,
                    numStrings: 5,
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
