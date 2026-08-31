import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';

void main() => runApp(const RiyaApp());

class RiyaApp extends StatelessWidget {
  const RiyaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.pinkAccent,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  String _currentMood = "SWEET ❤️";
  bool _isLoading = false;

  // CONFIGURATION (Apna Server URL aur Gemini API Key yahan daalein)
  final String _serverUrl = "http://YOUR_BACKEND_IP:8000";
  final String _apiKey = "YOUR_GEMINI_API_KEY";

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": text});
      _isLoading = true;
    });
    _controller.clear();

    try {
      final res = await http.post(
        Uri.parse("$_serverUrl/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_input": text, "api_key": _apiKey}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _messages.add({"sender": "riya", "text": data["reply"]});
          _currentMood = data["mood"];
        });

        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource("$_serverUrl/voice?t=${DateTime.now().millisecondsSinceEpoch}"));
      }
    } catch (e) {
      setState(() => _messages.add({"sender": "riya", "text": "Connection Error! Check Backend Server."}));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.pinkAccent,
              child: Text("R", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Riya AI v4.0", style: TextStyle(fontSize: 16)),
                Text(_currentMood, style: const TextStyle(fontSize: 11, color: Colors.pinkAccent)),
              ],
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                bool isUser = _messages[i]["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.pinkAccent.shade400 : const Color(0xFF242424),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                    ),
                    child: Text(_messages[i]["text"]!, style: const TextStyle(fontSize: 15, height: 1.3)),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(color: Colors.pinkAccent),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Riya se baat karein...",
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  backgroundColor: Colors.pinkAccent,
                  onPressed: () => _sendMessage(_controller.text),
                  child: const Icon(Icons.send, color: Colors.white),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
