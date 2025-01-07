import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:twilio_conversations/twilio_conversations.dart';

class ChatService {
  late TwilioConversationsClient _client;
  late Conversation _conversation;
  List<Message> _messages = [];
  final String baseUrl = 'YOUR_BACKEND_URL';
  
  // Stream controller to notify UI of new messages
  final _messageController = StreamController<List<Message>>.broadcast();
  Stream<List<Message>> get messageStream => _messageController.stream;

  Future<void> initTwilioClient(String conversationSid, String identity, String authToken) async {
    try {
      // Initialize Twilio client with user's token
      _client = await TwilioConversationsClient.create(authToken);
      
      // Get the specific conversation
      _conversation = await _client.getConversation(conversationSid);
      
      // Load existing messages
      final MessagePaginator paginator = await _conversation.getMessages();
      _messages = paginator.items;
      _messageController.add(_messages);

      // Listen for new messages
      _conversation.onMessageAdded.listen((Message message) {
        _messages.insert(0, message);
        _messageController.add(_messages);
      });

      // Listen for message updates
      _conversation.onMessageUpdated.listen((MessageUpdatedEvent event) {
        final index = _messages.indexWhere((m) => m.sid == event.message.sid);
        if (index != -1) {
          _messages[index] = event.message;
          _messageController.add(_messages);
        }
      });

    } catch (e) {
      print('Error initializing Twilio client: $e');
      throw Exception('Failed to initialize chat');
    }
  }

  Future<void> sendMessage(String text) async {
    try {
      final attributes = {'type': 'text'};
      await _conversation.sendMessage(
        messageOptions: MessageOptions()
          ..withBody(text)
          ..withAttributes(attributes),
      );
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message');
    }
  }

  Future<void> markMessageRead(Message message) async {
    try {
      await message.setLastReadTimestamp(DateTime.now());
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  void dispose() {
    _messageController.close();
    _client.shutdown();
  }
}