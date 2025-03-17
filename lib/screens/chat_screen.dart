import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // For smooth scrolling
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

late SocketService socketService;

class ChatScreen extends StatefulWidget {
  final String currentUser;
  final String otherUser;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchMessages();

    socketService = SocketService();
    socketService.connect();
    socketService.registerUser(widget.currentUser);

    // ✅ Listen for real-time messages
    socketService.onMessageReceived((data) {
      print("📨 Real-time message received: $data");
      Message incomingMessage = Message.fromJson(data);

      // Avoid duplicates and check if relevant to this chat
      if (!messages.any((msg) =>
          msg.sender == incomingMessage.sender &&
          msg.receiver == incomingMessage.receiver &&
          msg.content == incomingMessage.content)) {
        setState(() {
          messages.add(incomingMessage);
        });
        _scrollToBottomSmooth();
      }
    });
  }

  // Fetch chat history
  Future<void> fetchMessages() async {
    final fetchedMessages =
        await ApiService.getMessages(widget.currentUser, widget.otherUser);
    print("📥 Fetched Messages: $fetchedMessages");

    setState(() {
      messages = fetchedMessages;
    });

    // Scroll to bottom after rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottomSmooth();
    });
  }

  // Send message
  Future<void> sendMessage(String content) async {
    final messageData = {
      'sender': widget.currentUser,
      'receiver': widget.otherUser,
      'content': content,
    };

    bool success = await ApiService.sendMessage(
        widget.currentUser, widget.otherUser, content);

    if (success) {
      socketService.sendMessage(messageData); // Real-time delivery

      setState(() {
        messages.add(Message.fromJson(messageData)); // Instant UI update
      });

      // ✅ Clear input field and scroll down
      _controller.clear();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollToBottomSmooth();
      });

    } else {
      print("❌ Failed to send message to API.");
    }
  }

  // Smooth scroll to bottom
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
    socketService.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.otherUser}')),
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
                      style: TextStyle(fontSize: 16),
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
                    if (_controller.text.trim().isNotEmpty) {
                      sendMessage(_controller.text.trim());
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
