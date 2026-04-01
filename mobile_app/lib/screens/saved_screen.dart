import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<dynamic> _savedProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedProducts();
  }

  Future<void> _loadSavedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      if (userId == 0) throw Exception("User not logged in");

      final products = await ApiService.getSavedProducts(userId);
      if (mounted) {
        setState(() {
          _savedProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      await ApiService.deleteSavedProduct(productId);
      // Optimistic update
      setState(() {
        _savedProducts.removeWhere((p) => p['id'] == productId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product removed from favorites")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error removing product: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Saved Products",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text("Error: $_errorMessage"))
          : _savedProducts.isEmpty
          ? const Center(child: Text("No saved products yet."))
          : RefreshIndicator(
              onRefresh: _loadSavedProducts,
              color: const Color(0xFF9DC183),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _savedProducts.length,
                itemBuilder: (context, index) {
                  final product = _savedProducts[index];
                  return _buildSavedItem(product);
                },
              ),
            ),
    );
  }

  Widget _buildSavedItem(Map<String, dynamic> product) {
    // Determine icon and color based on score/category
    IconData icon = Icons.shopping_bag;
    Color color = Colors.blue;

    // Simple logic for visual variety
    if (product['risk_level'] == 'High Risk') {
      color = Colors.red;
      icon = Icons.warning;
    } else if (product['risk_level'] == 'Moderate Risk') {
      color = Colors.orange;
      icon = Icons.info_outline;
    } else if (product['risk_level'] == 'Safe') {
      color = const Color(0xFF9DC183); // Sage Green
      icon = Icons.health_and_safety;
    } else if (product['risk_level'] == 'High') {
      color = Colors.red;
      icon = Icons.warning;
    }

    return Dismissible(
      key: Key(product['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteProduct(product['id']);
      },
      child: GestureDetector(
        onTap: () {
          // Parse ingredients if available, otherwise just pass an empty list
          List<Map<String, dynamic>> dummyDangerItems = [];
          if (product['ingredients_text'] != null &&
              product['ingredients_text'].isNotEmpty) {
            // Basic reconstruction for UI purposes
            final names = product['ingredients_text'].split(', ');
            for (var n in names) {
              dummyDangerItems.add({
                'name': n,
                'reason': 'Saved hazard',
                'hazard_level': product['risk_level'],
              });
            }
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                score: (product['score'] ?? 0).toDouble(),
                riskLevel: product['risk_level'] ?? "Unknown",
                dangerItems: dummyDangerItems,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              // Icon Box
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 15),

              // Text Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? "Unknown Product",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      product['brand'] ?? (product['risk_level'] ?? "Unknown"),
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "Date: ${product['date'] ?? ''}",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              // Heart Icon (Filled red) - effectively delete button if clicked
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () => _deleteProduct(product['id']),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
