import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  final String currentUser;

  const InboxScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> conversations = [];

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    final url = Uri.parse('http://localhost:3000/conversations?user=${widget.currentUser}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          conversations = data.map((json) => Map<String, dynamic>.from(json)).toList();
        });
      } else {
        print('Failed to fetch conversations: ${response.body}');
      }
    } catch (error) {
      print('Error fetching conversations: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
      ),
      body: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return ListTile(
            title: Text(conversation['otherUser']),
            subtitle: Text(conversation['message']),
            trailing: Text(conversation['timestamp']),
            onTap: () {
              // Navigate to ChatScreen with the selected user
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    currentUser: widget.currentUser,
                    otherUser: conversation['otherUser'],
                    jwtToken: 'your_jwt_token', // Pass the JWT token
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}