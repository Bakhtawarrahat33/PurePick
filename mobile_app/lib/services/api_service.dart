import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // IMPORTANT: Replace with your laptop's local IP address (e.g., 192.168.1.5)
  // Do NOT use 'localhost' for physical phones.
  static const String baseUrl = 'http://192.168.1.71:8000/api';
  // Inside your ApiService class
  // lib/services/api_service.dart

  static Future<Map<String, dynamic>> loginWithGoogle(String? token) async {
    // 1. Log the token to see if Google actually sent it to your phone
    print(
      "DEBUG: Google Token received on phone: ${token?.substring(0, 10)}...",
    );

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/google-login/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'token': token}),
          )
          .timeout(
            const Duration(seconds: 10),
          ); // Prevent the app from hanging forever

      // 2. Log the status code (200 is success, 400/500 is error)
      print("DEBUG: Backend Status Code: ${response.statusCode}");
      print("DEBUG: Backend Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Backend Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      // 3. Log any connection or network errors
      print("DEBUG: Connection Error: $e");
      throw Exception('Failed to connect to backend at $baseUrl');
    }
  }

  // 1. Register User
  // 1. Register User
  static Future<Map<String, dynamic>> register(
    String name,
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "username": username,
        "password": password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? "Registration failed",
      );
    }
  }

  // 2. Login User
  // 2. Login User
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Invalid credentials");
    }
  }

  // 3. Update Health Profile
  static Future<void> updateProfile(int userId, String allergies) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profile/update/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "allergies": allergies}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to save profile");
    }
  }

  // Get Profile
  static Future<Map<String, dynamic>> getProfile(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/$userId/'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load profile");
    }
  }

  // 4. Analyze Product (The Big One)
  // Sends list of ingredients (text) OR image to backend
  static Future<Map<String, dynamic>> analyzeIngredients(
    List<String> ingredients,
    int userId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"ingredients": ingredients, "user_id": userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(
        "DEBUG: Analysis Failed. Status: ${response.statusCode}, Body: ${response.body}",
      );
      throw Exception(
        "Analysis failed: ${response.statusCode} - ${response.body}",
      );
    }
  }

  // 4b. Analyze Product from Image (AI Pipeline)
  static Future<Map<String, dynamic>> analyzeLabelImage(
    String imagePath,
    int userId,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/scan-label/'),
    );

    request.fields['user_id'] = userId.toString();
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(
        "DEBUG: Image Analysis Failed. Status: ${response.statusCode}, Body: ${response.body}",
      );
      throw Exception("Analysis failed: ${response.body}");
    }
  }

  // 5. Get Safer Alternatives
  static Future<List<dynamic>> getAlternatives(
    List<String> dangerIngredients,
  ) async {
    if (dangerIngredients.isEmpty) return [];

    final response = await http.post(
      Uri.parse('$baseUrl/alternatives/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"danger_ingredients": dangerIngredients}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['alternatives'] ?? [];
    } else {
      return []; // Silently fail for alternatives to not break the UI
    }
  }

  // 6. Get Scan History
  static Future<List<dynamic>> getHistory(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/history/$userId/'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load history");
    }
  }

  // 6. Chat with AI (New)
  static Future<Map<String, dynamic>> chatWithAI(String query) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"query": query}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to chat with AI: ${response.body}");
    }
  }

  // 7. Save Product
  static Future<void> saveProduct({
    required int userId,
    required String name,
    required int score,
    String? brand,
    String? ingredients,
    String? riskLevel,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/saved/add/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "name": name,
        "score": score,
        "brand": brand,
        "ingredients": ingredients,
        "risk_level": riskLevel,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to save product: ${response.body}");
    }
  }

  // 8. Get Saved Products
  static Future<List<dynamic>> getSavedProducts(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/saved/$userId/'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load saved products");
    }
  }

  // 9. Delete Saved Product
  static Future<void> deleteSavedProduct(int productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/saved/delete/$productId/'),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete product");
    }
  }

  // 10. Get AI Tips
  static Future<List<dynamic>> getAiTips(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/ai-tips/$userId/'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['tips'] ?? [];
    } else {
      throw Exception("Failed to load AI tips");
    }
  }
}
