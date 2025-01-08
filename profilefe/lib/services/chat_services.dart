import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:twilio_chat_conversation/twilio_chat_conversation.dart';

class ChatService {
  late TwilioConversationsClient _client;
  late TwilioConversation _conversation;
  List<TwilioMessage> _messages = [];
  final String baseUrl = 'YOUR_BACKEND_URL'; // Replace with your backend URL

  // Stream controller to notify UI of new messages
  final _messageController = StreamController<List<TwilioMessage>>.broadcast();
  Stream<List<TwilioMessage>> get messageStream => _messageController.stream;

  /// Initializes the Twilio client and sets up the conversation
  Future<void> initTwilioClient(String conversationSid, String identity, String authToken) async {
    try {
      // Initialize Twilio client with user's token
      _client = await TwilioConversationsClient.create(authToken);

      // Get the specific conversation
      _conversation = await _client.getConversation(conversationSid);

      // Load existing messages
      final messages = await _conversation.getMessages();
      _messages = messages ?? [];
      _messageController.add(_messages);

      // Listen for new messages
      _conversation.onMessageAdded.listen((TwilioMessage message) {
        _messages.insert(0, message);
        _messageController.add(_messages);
      });

      // Listen for updates to messages
      _conversation.onMessageUpdated.listen((TwilioMessageUpdatedEvent event) {
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

  /// Sends a message to the conversation
  Future<void> sendMessage(String text) async {
    try {
      final attributes = {'type': 'text'};
      await _conversation.sendMessage(
        body: text,
        attributes: jsonEncode(attributes),
      );
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message');
    }
  }

  /// Marks a message as read by the recipient
  Future<void> markMessageRead(TwilioMessage message) async {
    try {
      await message.setLastReadTimestamp(DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  /// Fetches the donor-recipient conversation from the backend
  Future<String> fetchConversationSid(String donorId, String recipientId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-conversation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'donorId': donorId, 'recipientId': recipientId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['conversationSid'];
      } else {
        throw Exception('Failed to fetch conversation SID');
      }
    } catch (e) {
      print('Error fetching conversation SID: $e');
      throw Exception('Failed to fetch conversation SID');
    }
  }

  /// Disposes resources when no longer needed
  void dispose() {
    _messageController.close();
    _client.shutdown();
  }
}