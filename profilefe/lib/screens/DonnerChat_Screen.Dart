import 'package:flutter/material.dart';
import '../services/chat_services.dart';  // Service that connects to backend

class DonorChatScreen extends StatefulWidget {
  final String conversationSid;

  DonorChatScreen({
    required this.conversationSid,
    Key? key,
  }) : super(key: key);

  @override
  _DonorChatScreenState createState() => _DonorChatScreenState();
}

class _DonorChatScreenState extends State<DonorChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> _messages = []; // List to store messages.

  @override
  void initState() {
    super.initState();
   
  }

  Future<void> _fetchMessages() async {
    try {
      final chatService = ChatServices();
      final messages = await chatService.getMessages(widget.conversationSid);
      setState(() {
        _messages = messages;
      });
    } catch (e) {
      print("Error fetching messages: $e");
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final message = _messageController.text.trim();
    try {
      final chatService = ChatServices();
      await chatService.sendMessage(
        widget.conversationSid,
        message,
      );
      setState(() {
        _messages.add({"author": "You", "body": message});
        _messageController.clear();
      });
       _fetchMessages();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Card(
          margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              // Light Blue Strip with Profile and Name
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.lightBlueAccent,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(_messages.isNotEmpty && _messages.first.containsKey('avatarUrl') ? _messages.first['avatarUrl']! : ''),
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _messages.isNotEmpty && _messages.first.containsKey('name') ? _messages.first['name']! : 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // Messages Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message['author'] == "You" ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: message['author'] == "You" ? Colors.lightBlueAccent : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            message['body']!,
                            style: TextStyle(
                              color: message['author'] == "You" ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Typing Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.lightBlueAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
