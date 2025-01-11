import 'package:flutter/material.dart';
import '../services/chat_services.dart';
import '../routes.dart';
import '../models/user.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final String conversationSid;
  final String userName;
  final String profileImage;

  ChatScreen({
    required this.conversationSid,
    required this.userName,
    required this.profileImage,
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchMessages();
  }

  Future<void> _loadUserData() async {
    final userProvider = UserProvider();
    await userProvider.getCurrentUser();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    setState(() {
      userId = user?.id;
    });
    print('User ID: ${user?.id}');
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final chatService = ChatServices();
      final messages = await chatService.getMessages(widget.conversationSid);
      setState(() {
        _messages = messages.map((message) => {
          ...message,
          'timestamp': message['timestamp'] ?? DateTime.now(),
          'isReceived': message['author'] != userId, 
        }).toList();
        
        _messages.sort((a, b) => 
          (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      print("Error fetching messages: $e");
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
   _fetchMessages();
    final timestamp = DateTime.now();
    _messageController.clear();
    setState(() {
      _isTyping = false;
    });

    try {
      final chatService = ChatServices();
      await chatService.sendMessage(
        widget.conversationSid,
        message,
      );

      setState(() {
        _messages.add({
          "author": userId,
          "body": message,
          "timestamp": timestamp,
          "isReceived": false,
        });
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  String _formatTime(DateTime timestamp) {
    return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Card(
          margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.01),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.lightBlueAccent,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        GoRouter.of(context).go(Routes.home); 
                      },
                    ),
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.profileImage),
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final bool isReceived = message['isReceived'] ?? false;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: isReceived ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.65,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isReceived ? Colors.grey[300] : Colors.lightBlueAccent,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isReceived ? 16 : 0),
                                bottomRight: Radius.circular(isReceived ? 0 : 16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isReceived 
                                  ? CrossAxisAlignment.start 
                                  : CrossAxisAlignment.end,
                              children: [
                                Text(
                                  message['body'] ?? '',
                                  style: TextStyle(
                                    color: isReceived ? Colors.black87 : Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(message['timestamp'] as DateTime),
                                  style: TextStyle(
                                    color: isReceived ? Colors.black54 : Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.black12)),
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
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        onChanged: (text) {
                          setState(() {
                            _isTyping = text.trim().isNotEmpty;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: _isTyping ? _sendMessage : null,
                      icon: Icon(
                        Icons.send,
                        color: _isTyping ? Colors.lightBlueAccent : Colors.grey,
                      ),
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
