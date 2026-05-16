import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<dynamic>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      return ApiService.getHistory(userId);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan History")),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No scans found."));
          }

          final history = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              // Data from backend: {id, score, items, flagged, date}
              // Adjust based on your API response structure
              // Assuming API returns: {'score': float, 'date': string, ...}

              final double score = (item['score'] ?? 0).toDouble();
              // Backend now sends a 100-based Safety Score directly
              final int safetyScore = score.toInt().clamp(0, 100);
              
              Color scoreColor = safetyScore >= 70
                  ? Colors.green
                  : (safetyScore >= 40 ? Colors.orange : Colors.red);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () {
                    // Navigate to ResultScreen with the historical data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultScreen(
                          score: score,
                          riskLevel: item['risk_level'] ?? 'moderate',
                          dangerItems: List<Map<String, dynamic>>.from(item['flagged_ingredients'] ?? []),
                          aiInsight: item['ai_analysis'] ?? '',
                          personalWarnings: item['personal_warnings'] ?? '',
                        ),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: scoreColor,
                    child: Text(
                      "$safetyScore",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(item['product_name'] ?? "Scan #${item['id']}"),
                  subtitle: Text(item['date'] ?? 'Unknown Date'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
