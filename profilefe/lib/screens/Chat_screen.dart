import 'package:flutter/material.dart';
import '../services/chat_services.dart';
import '../routes.dart';
import '../models/user.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../theme.dart';

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
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
          onPressed: () => GoRouter.of(context).go(Routes.senderscreen),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.profileImage),
              radius: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  'Online',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isReceived ? AppTheme.surfaceGrey : AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomLeft: isReceived ? Radius.zero : const Radius.circular(16),
                            bottomRight: isReceived ? const Radius.circular(16) : Radius.zero,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isReceived 
                              ? CrossAxisAlignment.start 
                              : CrossAxisAlignment.end,
                          children: [
                            Text(
                              message['body'] ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isReceived ? AppTheme.textDark : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(message['timestamp'] as DateTime),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isReceived ? AppTheme.textGrey : Colors.white70,
                                fontSize: 10,
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
        ],
      ),
    );
  }
}
