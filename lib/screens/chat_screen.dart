import 'package:flutter/material.dart';
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
  bool isListenerRegistered = false; // Flag for listener registration

  @override
  void initState() {
    super.initState();
    fetchMessages();

    socketService = SocketService();
    socketService.connect();
    socketService.registerUser(widget.currentUser);

    // Register the listener only once
    if (!isListenerRegistered) {
      socketService.onMessageReceived((data) {
        print("📨 Real-time message received: $data");
        Message incomingMessage = Message.fromJson(data);

        // Prevent adding the same message multiple times
        if (!messages.any((msg) =>
            msg.sender == incomingMessage.sender &&
            msg.receiver == incomingMessage.receiver &&
            msg.content == incomingMessage.content)) {
          setState(() {
            messages.add(incomingMessage);
          });
          _scrollToBottomSmooth();
        } else {
          print("Duplicate message ignored.");
        }
      });

      isListenerRegistered = true;
    }
  }

  // Fetch existing chat history (messages from the database)
  Future<void> fetchMessages() async {
    final fetchedMessages = await ApiService.getMessages(widget.currentUser, widget.otherUser);
    print("📥 Fetched Messages: $fetchedMessages");

    setState(() {
      messages = fetchedMessages;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottomSmooth();
    });
  }

  // Sending message handler
  Future<void> sendMessage(String content) async {
    final messageData = {
      'sender': widget.currentUser,
      'receiver': widget.otherUser,
      'content': content,
    };

    // Optimistically update UI
    final newMessage = Message.fromJson({
      ...messageData,
      'timestamp': DateTime.now().toIso8601String(), // Ensure timestamp exists
    });

    // Check if the message already exists in the list
    if (!messages.any((msg) =>
        msg.sender == newMessage.sender &&
        msg.receiver == newMessage.receiver &&
        msg.content == newMessage.content)) {
      setState(() {
        messages.add(newMessage);
      });
      _controller.clear();
      _scrollToBottomSmooth();
    } else {
      print("Duplicate message ignored.");
    }

    // Send to backend (DB and real-time)
    bool success = await ApiService.sendMessage(
      widget.currentUser, widget.otherUser, content);

    if (success) {
      socketService.sendMessage(messageData);
    } else {
      print("❌ Failed to send message to API.");
    }
  }

  // Smooth scrolling function
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
