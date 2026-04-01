import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'result_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final String imagePath;
  const AnalysisScreen({super.key, required this.imagePath});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _startAiAnalysis();
  }

  Future<void> _startAiAnalysis() async {
    try {
      // 1. Prepare the image request to your Django backend
      // Use 'http://10.0.2.2:8000/scanner/analyze/' if on Android Emulator
      // Use 'http://127.0.0.1:8000/scanner/analyze/' if on Chrome
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/api/analyze/'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', widget.imagePath),
      );

      // 2. Send the image and wait for PaddleOCR & Sentence Transformer results
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var results = json.decode(response.body);

        if (mounted) {
          // 3. Move to the Result Screen with the real dataset matches
          final totalScore = (results['score'] ?? 0).toDouble();
          final riskLevel = results['risk_level'] ?? "Unknown";
          final aiInsight = results['ai_insight'] ?? '';
          final personalWarnings = results['personal_warnings'] ?? '';

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                score: totalScore.clamp(0, 100).toDouble(),
                riskLevel: riskLevel,
                dangerItems: List<Map<String, dynamic>>.from(
                  results['danger_items'] ?? [],
                ),
                aiInsight: aiInsight,
                personalWarnings: personalWarnings,
              ),
            ),
          );
        }
      } else {
        setState(() => _isError = true);
      }
    } catch (e) {
      debugPrint("Analysis Error: $e");
      if (mounted) setState(() => _isError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isError) ...[
                // THE LOADING UI
                const CircularProgressIndicator(
                  color: Color(0xFF00C897),
                  strokeWidth: 5,
                ),
                const SizedBox(height: 30),
                Text(
                  "Analyzing Product...",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Using PaddleOCR & Sentence Transformer to match with your dataset.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                ),
              ] else ...[
                // THE ERROR UI
                const Icon(Icons.cloud_off, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                Text(
                  "Connection Failed",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Make sure your Django server is running at port 8000.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C897),
                  ),
                  child: const Text(
                    "Go Back",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
