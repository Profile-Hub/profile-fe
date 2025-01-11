import 'dart:convert';
import 'package:http/http.dart' as http;
import '../server_config.dart';  
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatServices {
   final String baseUrl = ServerConfig.baseUrl;
   String? _token;
  List<Map<String, dynamic>>? _userDetails;
  List<Map<String, dynamic>>? get userDetails => _userDetails;
  static final _storage = FlutterSecureStorage(); 
  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }
   Future<String> getOrCreateConversation(String donor) async {
    await _loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/conversation'),
      headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      body: jsonEncode({'donor': donor}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['conversationSid']; 
    } else {
      throw Exception('Failed to fetch conversation SID');
    }
  }
Future<String> getConversationByDonor(String reciptent) async {
  await _loadToken();
  final response = await  http.post(
    Uri.parse('$baseUrl/conversation/donor'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    },
    body: jsonEncode({'reciptent': reciptent}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
     
      return data['conversationId'];  
    } else {
      throw Exception('No conversation found');
    }
  } else {
    throw Exception('Failed to fetch conversation SID');
  }
}

  // Send a message
  Future<void> sendMessage(String conversationSid, String message) async {
   await _loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/message'),
      headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      body: json.encode({
        'conversationSid': conversationSid,
        'message': message,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message');
    }
  }

  // Fetch messages
  Future<List<Map<String, String>>> getMessages(String conversationSid) async {
  await _loadToken();

  final response = await http.get(
    Uri.parse('$baseUrl/fetch-message/$conversationSid'),
    headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch messages');
  }

  final List<dynamic> data = json.decode(response.body);
  return data.map<Map<String, String>>((message) {
    return {
      'author': message['author'].toString(),
      'body': message['body'].toString(),
    };
  }).toList();
}
 Future<List<Map<String, dynamic>>?> getSenderDetails() async {
  await _loadToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversation/senderdetails'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          _userDetails = List<Map<String, dynamic>>.from(data['data']);
         
          return _userDetails!;
        } else {
          throw Exception('No conversation found');
        }
      } else {
        throw Exception('Failed to fetch conversation SID');
      }
    } catch (error) {
      print("Error fetching data: $error");
    }
  }
}
