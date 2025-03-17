import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart'; // Import Message model


class ApiService {
  static const String baseUrl = 'http://127.0.0.1:3000'; // ⚠️ Note: use 10.0.2.2 for Android Emulator

  // Send a message
  static Future<bool> sendMessage(String sender, String receiver, String content) async {
    final url = Uri.parse('$baseUrl/messages');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender': sender,
        'receiver': receiver,
        'content': content,
      }),
    );

    if (response.statusCode == 200) {
      print('✅ Message sent: ${response.body}');
      return true;
    } else {
      print('❌ Failed to send message: ${response.body}');
      return false;
    }
  }

  // Fetch messages between two users
  static Future<List<Message>> getMessages(String sender, String receiver) async {
    final url = Uri.parse('$baseUrl/messages?sender=$sender&receiver=$receiver');

    final response = await http.get(url);

    if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List<Message> messages = (data['data'] as List)
        .map((msgJson) => Message.fromJson(msgJson))
        .toList();
    return messages;
  } else {
    print('❌ Failed to fetch messages: ${response.body}');
    return [];
  }
  }
}
