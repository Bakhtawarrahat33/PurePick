import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AiTipsScreen extends StatefulWidget {
  const AiTipsScreen({super.key});

  @override
  State<AiTipsScreen> createState() => _AiTipsScreenState();
}

class _AiTipsScreenState extends State<AiTipsScreen> {
  late Future<List<dynamic>> _tipsFuture;

  @override
  void initState() {
    super.initState();
    _tipsFuture = _loadTips();
  }

  Future<List<dynamic>> _loadTips() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      return ApiService.getAiTips(userId);
    }
    return [];
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return const Color(0xFFFF3B30);
      case 'medium':
        return const Color(0xFFFF9500);
      case 'low':
        return const Color(0xFF007AFF);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Personalized AI Tips", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _tipsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00C897)),
                  SizedBox(height: 20),
                  Text("Analyzing your profile and scans..."),
                ],
              ),
            );
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  "Complete more scans or update your profile to unlock personalized health tips.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            );
          }

          final tips = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return TipCard(
                title: tip['title'] ?? 'Health Tip',
                body: tip['body'] ?? '',
                category: tip['category'] ?? 'General',
                severity: tip['severity'] ?? 'Low',
                color: _getSeverityColor(tip['severity']),
                ingredient: tip['related_ingredient'],
              );
            },
          );
        },
      ),
    );
  }
}

class TipCard extends StatelessWidget {
  final String title, body, category, severity;
  final String? ingredient;
  final Color color;

  const TipCard({
    super.key,
    required this.title,
    required this.body,
    required this.category,
    required this.severity,
    required this.color,
    this.ingredient,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 6)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  "$severity Priority",
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.4),
            ),
            if (ingredient != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.science, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(
                      "Watch out for: $ingredient",
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
