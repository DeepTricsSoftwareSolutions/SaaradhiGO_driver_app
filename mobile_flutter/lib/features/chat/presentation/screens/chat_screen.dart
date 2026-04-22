
import 'package:flutter/material.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';

class ChatScreen extends StatefulWidget {
  final String riderId;
  final String riderName;

  const ChatScreen({super.key, required this.riderId, required this.riderName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'sender': 'rider', 'text': 'I am near the metro gate.', 'time': '10:05 AM'},
    {'sender': 'driver', 'text': 'Got it. I will be there in 2 mins.', 'time': '10:06 AM'},
  ];

  void _sendMessage() {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'sender': 'driver',
        'text': _msgCtrl.text.trim(),
        'time': '10:08 AM', // Hardcoded for demo
      });
      _msgCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: AppTheme.primaryGold),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.riderName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text("Online", style: TextStyle(fontSize: 11, color: AppTheme.successGreen)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.call, color: AppTheme.primaryGold)),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isDriver = msg['sender'] == 'driver';
                return Align(
                  alignment: isDriver ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDriver ? AppTheme.primaryGold : Colors.white10,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isDriver ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isDriver ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg['text'], style: TextStyle(color: isDriver ? Colors.black : Colors.white, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(msg['time'], style: TextStyle(color: isDriver ? Colors.black45 : Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Color(0xFF141414)),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(100)),
                child: TextField(
                  controller: _msgCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: AppTheme.primaryGold, shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
