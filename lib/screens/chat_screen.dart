import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../screens/search_user_screen.dart'; // Corrected path to SearchUserScreen

class ChatScreen extends StatefulWidget {
  final String currentUser;
  final String otherUser;
  final String jwtToken; // Add jwtToken as a parameter

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
    required this.jwtToken, // Add this line
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late SocketService socketService;

  @override
  void initState() {
    super.initState();
    socketService = SocketService(); // Initialize the SocketService
    socketService.connect(); // Connect to the socket server
    fetchMessages(); // Fetch chat history when the screen is opened
    _connectToSocket(); // Connect to the socket
  }

  void _connectToSocket() {
    // Generate a unique roomId based on the two users
    final roomId = widget.currentUser.compareTo(widget.otherUser) < 0
        ? '${widget.currentUser}_${widget.otherUser}'
        : '${widget.otherUser}_${widget.currentUser}';

    // Join the room
    socketService.registerUser(roomId);

    // Listen for incoming messages
    socketService.onMessageReceived((data) {
      // Ignore messages sent by the current user (already handled by optimistic UI update)
      if (data['sender'] != widget.currentUser) {
        setState(() {
          messages.add(Message.fromJson(data)); // Add the new message to the list
        });
      }
    });
  }

  Future<void> fetchMessages() async {
    final url = Uri.parse('http://localhost:3000/messages?user1=${widget.currentUser}&user2=${widget.otherUser}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          messages = data.map((json) => Message.fromJson(json)).toList();
        });
      } else {
        print('Failed to fetch messages: ${response.body}');
      }
    } catch (error) {
      print('Error fetching messages: $error');
    }
  }

  Future<void> sendMessage(String content) async {
    final roomId = widget.currentUser.compareTo(widget.otherUser) < 0
        ? '${widget.currentUser}_${widget.otherUser}'
        : '${widget.otherUser}_${widget.currentUser}';

    final messageData = {
      'roomId': roomId,
      'sender': widget.currentUser,
      'receiver': widget.otherUser,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Emit the message
    socketService.sendMessage(messageData);

    // Optimistically update the UI
    setState(() {
      messages.add(Message.fromJson(messageData));
    });

    _controller.clear();
    _scrollToBottomSmooth();
  }

  void _scrollToBottomSmooth() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    socketService.resetListener(); // Reset the listener when the screen is disposed
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.otherUser}'), // Display the correct user
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                bool isMe = msg.sender == widget.currentUser;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.content,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    final content = _controller.text.trim();
                    if (content.isNotEmpty) {
                      sendMessage(content);
                    }
                  },
                ),
              ],
            ),
          ),
         
        ],
      ),
    );
  }
}
