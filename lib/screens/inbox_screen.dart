import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'chat_screen.dart';
import 'search_user_screen.dart';

class InboxScreen extends StatefulWidget {
  final String currentUser;
  final String jwtToken;

  const InboxScreen({
    Key? key,
    required this.currentUser,
    required this.jwtToken,
  }) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> conversations = [];
  bool isLoading = true;
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _connectToSocket();
  }

  @override
  void dispose() {
    socket.disconnect(); // Disconnect the socket when the screen is disposed
    super.dispose();
  }

  Future<void> _fetchConversations() async {
    final url = Uri.parse('http://localhost:3000/conversations?user=${widget.currentUser}');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.jwtToken}', // Pass the JWT token for authentication
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          conversations = data
              .map((json) => Map<String, dynamic>.from(json))
              .toList()
              ..sort((a, b) => b['timestamp'].compareTo(a['timestamp'])); // Sort by timestamp (descending)
          isLoading = false;
        });
      } else {
        print('Failed to fetch conversations: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch conversations: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error fetching conversations: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching conversations: $error')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _connectToSocket() {
    // Connect to the WebSocket server
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer ${widget.jwtToken}'}, // Pass the JWT token
    });

    socket.connect();

    // Listen for updates to conversations
    socket.on('conversation_update', (data) {
      print('Received conversation update: $data');
      setState(() {
        final updatedConversation = Map<String, dynamic>.from(data);
        final index = conversations.indexWhere(
            (conv) => conv['otherUser'] == updatedConversation['otherUser']);
        if (index != -1) {
          // Update the existing conversation
          conversations[index] = updatedConversation;
        } else {
          // Add a new conversation
          conversations.add(updatedConversation);
        }

        // Sort the conversations by timestamp (descending)
        conversations.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate directly to the SearchScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    loggedInUser: widget.currentUser,
                    jwtToken: widget.jwtToken,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : conversations.isEmpty
              ? const Center(child: Text('No conversations yet'))
              : ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return ListTile(
                      title: Text(conversation['otherUser']),
                      subtitle: Text(conversation['message']),
                      trailing: Text(conversation['timestamp']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              currentUser: widget.currentUser,
                              otherUser: conversation['otherUser'],
                              jwtToken: widget.jwtToken,
                            ),
                          ),
                        ).then((_) {
                          _fetchConversations(); // Refresh conversations when returning from ChatScreen
                        });
                      },
                    );
                  },
                ),
    );
  }
}