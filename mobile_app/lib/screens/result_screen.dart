import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ResultScreen extends StatefulWidget {
  final double score; // This is the HAZARD score (0-100) from backend
  final String riskLevel;
  final List<Map<String, dynamic>> dangerItems;
  final String aiInsight;
  final String personalWarnings;

  const ResultScreen({
    super.key,
    required this.score,
    required this.riskLevel,
    required this.dangerItems,
    this.aiInsight = '',
    this.personalWarnings = '',
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;
  List<dynamic> _alternatives = [];
  bool _isLoadingAlternatives = true;

  @override
  void initState() {
    super.initState();
    _fetchAlternatives();
  }

  Future<void> _fetchAlternatives() async {
    if (widget.dangerItems.isEmpty) {
      setState(() => _isLoadingAlternatives = false);
      return;
    }

    try {
      final dangerNames = widget.dangerItems
          .map((e) => e['name'].toString())
          .toList();
      final alts = await ApiService.getAlternatives(dangerNames);
      if (mounted) {
        setState(() {
          _alternatives = alts;
          _isLoadingAlternatives = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAlternatives = false);
    }
  }

  Future<void> _handleSave() async {
    // Show dialog to get product name
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Save Result"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Product Name",
            hintText: "e.g. My Shampoo",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      if (userId == 0) throw Exception("User not logged in");

      await ApiService.saveProduct(
        userId: userId,
        name: name,
        score: widget.score.toInt(),
        riskLevel: widget.riskLevel,
        ingredients: widget.dangerItems.map((e) => e['name']).join(", "),
        // We only save dangerous ones here as a summary, or we could pass all ingredients if we had them.
        // For now, saving the flagged items is better than nothing.
      );

      if (mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product saved to favorites!")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The backend now sends the Safety Score directly (100 = Safe)
    final int safetyScore = widget.score.clamp(0, 100).toInt();

    // 2. Determine Color Status based on SAFETY Score
    final bool isSafe = safetyScore > 70; // >70% safe is Green
    final Color statusColor = isSafe
        ? const Color(0xFF00C853)
        : Colors.redAccent;
    final String statusText = isSafe ? "SAFE TO USE" : "WARNING DETECTED";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Analysis Result"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isSaved ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
            onPressed: (_isSaving || _isSaved) ? null : _handleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Circular Score Indicator
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "$safetyScore%",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const Text(
                    "Safety Score",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Hazards List
            if (widget.dangerItems.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Risks Found:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              ...widget.dangerItems.map(
                (item) => Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      "${item['name']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${item['reason']}"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        "${item['hazard_level']}".toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              // Safe State View
              Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "No harmful ingredients detected based on your profile.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),

            // --- AI INSIGHTS SECTION ---
            if (widget.aiInsight.isNotEmpty ||
                widget.personalWarnings.isNotEmpty) ...[
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFFFF0080)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8E2DE2).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                        SizedBox(width: 10),
                        Text(
                          "PurePick AI Insight",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (widget.personalWarnings.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_rounded,
                              color: Colors.yellowAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.personalWarnings,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                    if (widget.aiInsight.isNotEmpty)
                      Text(
                        widget.aiInsight,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // --- SAFER ALTERNATIVES SECTION ---
            if (widget.dangerItems.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Safer Alternatives",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              if (_isLoadingAlternatives)
                const CircularProgressIndicator()
              else if (_alternatives.isEmpty)
                const Text(
                  "No exact alternatives found for these ingredients.",
                  style: TextStyle(color: Colors.grey),
                )
              else
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _alternatives.length,
                    itemBuilder: (context, index) {
                      final alt = _alternatives[index];
                      return Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9DC183).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFF9DC183).withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF9DC183),
                                  size: 18,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    alt['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Replaces: ${alt['replaces']}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              "Function: ${alt['function']}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "Hazard Score: ${alt['score']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Scan Another Product",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),

            // Go to Saved
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // We can't easily go to SavedScreen directly if it's not in the route stack cleanly,
                // but usually it's accessible from Home.
                // For now, just 'Scan Another' is enough, or we could add 'View Favorites'
                Navigator.pop(context); // Close result
              },
              child: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }
}
