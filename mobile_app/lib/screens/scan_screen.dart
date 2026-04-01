import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isBusy = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    // Add observer to handle app lifecycle changes (e.g., backgrounding the app)
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    // CRITICAL FIX: Dispose controller and remove observer to prevent memory leaks/crashes
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFocusMode(
        FocusMode.auto,
      ); // Key fix for "holding too long"
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null || !_controller!.value.isInitialized || _isBusy) {
      return;
    }
    setState(() => _isBusy = true);

    try {
      final image = await _controller!.takePicture();
      await _controller!.pausePreview();
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;

      // Use the new Image-based AI Pipeline backend
      final result = await ApiService.analyzeLabelImage(image.path, userId);
      print("DEBUG: API Result: $result");

      if (!mounted) return;

      List<Map<String, dynamic>> dangerItems = [];

      final totalScore = (result['real_score'] ?? 0).toDouble();
      final riskLevel = result['real_risk_level'] ?? 'Safe';
      final aiInsight = result['ai_insight'] ?? '';
      final personalWarnings = result['personal_warnings'] ?? '';

      final matched = result['matched_ingredients'] as List<dynamic>? ?? [];
      for (var item in matched) {
        dangerItems.add({
          'name': item['original_name'],
          'reason': item['canonical_name'] == 'Unverified'
              ? 'Unknown Ingredient'
              : item['canonical_name'],
          'hazard_level': item['canonical_name'] == 'Unverified'
              ? 'Unknown'
              : 'Warning',
          'score': item['confidence_score'],
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            score: totalScore.clamp(0, 100).toDouble(),
            riskLevel: riskLevel,
            dangerItems: dangerItems,
            aiInsight: aiInsight,
            personalWarnings: personalWarnings,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
        _controller?.resumePreview();
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Added safety check for initialization state
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  setState(() => _isFlashOn = !_isFlashOn);
                  _controller!.setFlashMode(
                    _isFlashOn ? FlashMode.torch : FlashMode.off,
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: FloatingActionButton.large(
                backgroundColor: Colors.white,
                onPressed: _isBusy
                    ? null
                    : _captureAndAnalyze, // Prevent double-taps
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.black,
                  size: 40,
                ),
              ),
            ),
          ),
          if (_isBusy)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.greenAccent),
                    SizedBox(height: 16),
                    Text(
                      "Analyzing Ingredients...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
