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

  Color _parseColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your AI Health Tips")),
      body: FutureBuilder<List<dynamic>>(
        future: _tipsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("PurePick AI is preparing your custom tips..."),
                ],
              ),
            );
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "Unable to load tips at this time. ${snapshot.error ?? ""}",
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
                color: _parseColor(tip['color'] ?? 'teal'),
              );
            },
          );
        },
      ),
    );
  }
}

class TipCard extends StatelessWidget {
  final String title, body;
  final Color color;
  const TipCard({
    super.key,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: color),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
