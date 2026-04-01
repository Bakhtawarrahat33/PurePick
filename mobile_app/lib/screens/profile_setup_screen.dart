import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1 Data
  final TextEditingController _ageController = TextEditingController(
    text: "22",
  );
  String _selectedGender = "Female";
  String _selectedSkinType = "Combination";

  // Step 2 Data
  List<String> _selectedAllergies = [];
  final List<String> _commonAllergies = [
    "Fragrance",
    "Parabens",
    "Sulfates",
    "Gluten",
    "Nuts",
    "Dairy",
    "Soy",
    "Alcohol",
  ];
  final TextEditingController _allergySearchController =
      TextEditingController();

  // Step 3 Data
  List<String> _selectedConditions = [];
  final List<String> _commonConditions = [
    "Acne",
    "Eczema",
    "Rosacea",
    "Psoriasis",
    "Dermatitis",
    "Hyperpigmentation",
    "None",
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('user_id');
      if (userId != null) {
        final profileData = await ApiService.getProfile(userId);
        final String rawAllergies = profileData['allergies'] ?? '';

        if (rawAllergies.isNotEmpty) {
          final tags = rawAllergies.split(',').map((e) => e.trim()).toList();

          List<String> loadedAllergies = [];
          List<String> loadedConditions = [];

          for (var tag in tags) {
            if (tag.startsWith("Skin:")) {
              _selectedSkinType = tag.split(":")[1];
            } else if (tag.startsWith("Gender:")) {
              _selectedGender = tag.split(":")[1];
            } else if (_commonConditions.contains(tag) ||
                tag.toLowerCase().contains("acne") ||
                tag.toLowerCase().contains("rosacea")) {
              // Heuristic approach to sorting conditions vs allergies if they weren't strictly prefixed
              loadedConditions.add(tag);
            } else {
              loadedAllergies.add(tag);
            }
          }

          setState(() {
            _selectedAllergies = loadedAllergies;
            _selectedConditions = loadedConditions;
          });
        }
      }
    } catch (e) {
      print("Could not load profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finishProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('user_id');

      if (userId == null) throw Exception("User session lost.");

      // Combine Data for Backend
      // We pass everything relevant to safety as "allergies" for the analysis engine
      final profileTags = [
        ..._selectedAllergies,
        ..._selectedConditions,
        "Skin:$_selectedSkinType",
        "Gender:$_selectedGender",
      ].join(",");

      await ApiService.updateProfile(userId, profileTags);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Purple/Pink Gradient Header
          Container(
            height: 300,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8E2DE2),
                  Color(0xFFFF0080),
                ], // Purple to Pink
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Create Your Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Help us personalize your experience",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "All fields marked with * are required",
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. White Bottom Sheet Container
          Container(
            margin: const EdgeInsets.only(top: 240),
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepContent(),
                const Spacer(),
                _buildSummary(),
                const SizedBox(height: 20),
                _buildNavigationButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 0) {
      // Step 1: Basic Info
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel("Age *", Icons.calendar_today),
          const SizedBox(height: 10),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Enter your age",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildInputLabel("Gender *", Icons.people_outline),
          const SizedBox(height: 10),
          Row(
            children: ["Male", "Female", "Other"]
                .map(
                  (g) => Expanded(
                    child: _buildSelectableChip(
                      g,
                      _selectedGender == g,
                      () => setState(() => _selectedGender = g),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 20),
          _buildInputLabel("Skin Type *", Icons.water_drop_outlined),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ["Dry", "Oily", "Combination", "Sensitive", "Normal"]
                .map(
                  (s) => _buildSelectableChip(
                    s,
                    _selectedSkinType == s,
                    () => setState(() => _selectedSkinType = s),
                  ),
                )
                .toList(),
          ),
        ],
      );
    } else if (_currentStep == 1) {
      // Step 2: Allergies
      return Expanded(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInputLabel(
                    "Allergies & Sensitivities",
                    Icons.error_outline,
                  ),
                  const Text(
                    "(Optional)",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Search Bar
              TextField(
                controller: _allergySearchController,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    // Validation: Check if input contains digits
                    if (RegExp(r'[0-9]').hasMatch(value)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Allergies cannot contain numbers."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _selectedAllergies.add(value);
                      _allergySearchController.clear();
                    });
                  }
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Search or add custom allergy",
                  suffixIcon: GestureDetector(
                    onTap: () {
                      final value = _allergySearchController.text;
                      if (value.isNotEmpty) {
                        if (RegExp(r'[0-9]').hasMatch(value)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Allergies cannot contain numbers.",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _selectedAllergies.add(value);
                          _allergySearchController.clear();
                        });
                      }
                    },
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "Add",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Selected Allergies
              if (_selectedAllergies.isNotEmpty) ...[
                const Text(
                  "Selected allergies:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedAllergies
                      .map(
                        (a) => Chip(
                          label: Text(
                            a,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF8E2DE2),
                          deleteIcon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                          onDeleted: () =>
                              setState(() => _selectedAllergies.remove(a)),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],

              const Text(
                "Common allergies:",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _commonAllergies.map((a) {
                  final isSelected = _selectedAllergies.contains(a);
                  return _buildSelectableChip(a, isSelected, () {
                    setState(() {
                      isSelected
                          ? _selectedAllergies.remove(a)
                          : _selectedAllergies.add(a);
                    });
                  });
                }).toList(),
              ),
            ],
          ),
        ),
      );
    } else {
      // Step 3: Skin Conditions
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInputLabel("Skin Conditions", Icons.show_chart),
              const Text(
                "(Select all that apply)",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _commonConditions.map((c) {
              final isSelected = _selectedConditions.contains(c);
              return _buildSelectableChip(c, isSelected, () {
                setState(() {
                  isSelected
                      ? _selectedConditions.remove(c)
                      : _selectedConditions.add(c);
                });
              });
            }).toList(),
          ),
        ],
      );
    }
  }

  Widget _buildInputLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8E2DE2)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSelectableChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8E2DE2).withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF8E2DE2) : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? const Color(0xFF8E2DE2) : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    if (_currentStep < 2) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8E2DE2).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person, size: 16, color: Color(0xFF8E2DE2)),
              SizedBox(width: 8),
              Text(
                "Profile Summary",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E2DE2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text("• Age: ${_ageController.text} years old"),
          Text("• Gender: $_selectedGender"),
          Text("• Skin Type: $_selectedSkinType"),
          Text(
            "• Allergies: ${_selectedAllergies.isEmpty ? 'None' : _selectedAllergies.join(', ')}",
          ),
          Text(
            "• Conditions: ${_selectedConditions.isEmpty ? 'None' : _selectedConditions.join(', ')}",
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  _finishProfile();
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFFFF0080)],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 2 ? "Complete Profile" : "Continue",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
