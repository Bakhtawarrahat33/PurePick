import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  final List<String> _suggestions = [
    "What should I avoid?",
    "Is SLS safe for me?",
    "Check my last scan",
    "Explain Parabens"
  ];

  @override
  void initState() {
    super.initState();
    _messages.add({
      "role": "bot",
      "text": "Hello! I'm your PurePick AI. I've reviewed your profile and I'm ready to help. What would you like to know?"
    });
  }

  void _sendMessage([String? text]) async {
    String userText = text ?? _controller.text;
    if (userText.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    setState(() {
      _messages.add({"role": "user", "text": userText});
      _controller.clear();
      _isLoading = true;
    });

    try {
      final response = await ApiService.chatWithAI(userText, userId);
      setState(() {
        _messages.add({"role": "bot", "text": response['reply']});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add({
          "role": "bot",
          "text": "I'm having trouble connecting. Please try again."
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("PurePick AI", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isUser = _messages[index]['role'] == 'user';
                return _buildMessageBubble(isUser, _messages[index]['text']!);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Thinking...", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
            ),
          if (_messages.length == 1) _buildSuggestions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _suggestions.map((s) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(s, style: const TextStyle(fontSize: 12)),
            backgroundColor: Colors.white,
            onPressed: () => _sendMessage(s),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMessageBubble(bool isUser, String text) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF00C897) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15, height: 1.3),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Ask about any ingredient...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF1F3F4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: const CircleAvatar(
              backgroundColor: Color(0xFF00C897),
              child: Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
