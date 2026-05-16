import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;

      // Use the professional ApiService we configured
      final results = await ApiService.analyzeLabelImage(widget.imagePath, userId);

      if (mounted) {
        // Map the new Phase III+ report structure to the Result Screen
        final riskData = results['risk'] ?? {};
        final allergyData = results['allergy_result'] ?? {};
        
        final totalScore = (results['overall_score'] ?? 0).toDouble();
        final riskLevel = riskData['risk_band'] ?? "Unknown";
        final verdict = allergyData['overall_verdict'] ?? '';
        
        // Assemble justifications and alerts into a displayable string
        final List alerts = allergyData['allergy_alerts'] ?? [];
        String personalWarnings = alerts.isNotEmpty 
          ? alerts.map((e) => "?? ${e['plain_explanation']}").join("\n\n")
          : "✅ This product appears safe based on your profile.";

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              score: totalScore.clamp(0, 100).toDouble(),
              riskLevel: riskLevel,
              dangerItems: List<Map<String, dynamic>>.from(
                results['ingredient_breakdown'] ?? [],
              ),
              aiInsight: verdict,
              personalWarnings: personalWarnings,
            ),
          ),
        );
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
