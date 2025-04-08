import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../screens/search_user_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; // Add this import

class ChatScreen extends StatefulWidget {
  final String currentUser;
  final String otherUser;
  final String jwtToken;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
    required this.jwtToken,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late SocketService socketService;
  bool _showEmojiPicker = false;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    socketService = SocketService();
    socketService.connect();
    fetchMessages();
    _connectToSocket();
    
  _focusNode.addListener(() {
    if (_focusNode.hasFocus) {
      setState(() {
        _showEmojiPicker = false;
      });
    }
  });
  }

  void _connectToSocket() {
    final roomId = widget.currentUser.compareTo(widget.otherUser) < 0
        ? '${widget.currentUser}_${widget.otherUser}'
        : '${widget.otherUser}_${widget.currentUser}';

    socketService.registerUser(roomId);

    socketService.onMessageReceived((data) {
      if (data['sender'] != widget.currentUser) {
        setState(() {
          messages.add(Message.fromJson(data));
        });
      }
    });
  }

  Future<void> fetchMessages() async {
    final url = Uri.parse(
        'http://localhost:3000/messages?user1=${widget.currentUser}&user2=${widget.otherUser}');
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
      'isGroup': false,
      'emojis': [],
      'fileUrl': ""
    };

    socketService.sendMessage(messageData);

    setState(() {
      messages.add(Message.fromJson(messageData));
    });

    _controller.clear();
    _scrollToBottomSmooth();
  }

  void sendMessageAttachment(String fileUrl) {
    final roomId = widget.currentUser.compareTo(widget.otherUser) < 0
        ? '${widget.currentUser}_${widget.otherUser}'
        : '${widget.otherUser}_${widget.currentUser}';

    final messageData = {
      'roomId': roomId,
      'sender': widget.currentUser,
      'receiver': widget.otherUser,
      'content': '', // Empty text when file is attached
      'timestamp': DateTime.now().toIso8601String(),
      'isGroup': false,
      'emojis': [],
      'fileUrl': fileUrl,
    };

    socketService.sendMessage(messageData);

    setState(() {
      messages.add(Message.fromJson(messageData));
    });
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

  // FILE PICKING AND UPLOADING LOGIC
  void pickFile() async {
    if (kIsWeb) {
      print('Web file picking not supported yet.');
    } else if (Platform.isAndroid || Platform.isIOS) {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        print('Picked file: $fileName');
        // Upload file to backend
        final uploadUri = Uri.parse('http://localhost:3000/upload');
        var request = http.MultipartRequest('POST', uploadUri);
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
        var response = await request.send();
        if (response.statusCode == 200) {
          final respStr = await response.stream.bytesToString();
          final jsonResp = jsonDecode(respStr);
          final fileUrl = jsonResp['fileUrl'];
          print('Uploaded file URL: $fileUrl');
          // Send a message with the attachment
          sendMessageAttachment(fileUrl);
        } else {
          print('Error uploading file: ${response.statusCode}');
        }
      }
    } else {
      print('Platform not supported for file picking.');
    }
  }

  @override
  void dispose() {
    socketService.resetListener();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.otherUser}'),
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
                    margin: const EdgeInsets.symmetric(
                        vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: msg.fileUrl != null && msg.fileUrl.isNotEmpty
                        ? (msg.fileUrl.endsWith('.jpg') ||
                                msg.fileUrl.endsWith('.jpeg') ||
                                msg.fileUrl.endsWith('.png')
                            ? Image.network(
                                msg.fileUrl,
                                width: 200,
                                height: 200,
                              )
                            : GestureDetector(
                                onTap: () {
                                  // You can implement file open/download logic here.
                                },
                                child: Text(
                                  'Attachment: ${msg.fileUrl.split('/').last}',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline),
                                ),
                              ))
                        : Text(
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
  child: Column(
    children: [
      Row(
        children: [
          IconButton(
            icon: Icon(
              _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
              color: Colors.orange,
            ),
            onPressed: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _showEmojiPicker = !_showEmojiPicker;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: pickFile,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
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
      if (_showEmojiPicker)
        SizedBox(
          height: 250,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              _controller.text += emoji.emoji;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
            },
            config: Config(
              columns: 7,
              emojiSizeMax: 32,
              verticalSpacing: 0,
              horizontalSpacing: 0,
              gridPadding: EdgeInsets.zero,
              initCategory: Category.RECENT,
              bgColor: const Color(0xFFF2F2F2),
              indicatorColor: Colors.blue,
              iconColor: Colors.grey,
              iconColorSelected: Colors.blue,
              backspaceColor: Colors.red,
              skinToneDialogBgColor: Colors.white,
              enableSkinTones: true,
              recentTabBehavior: RecentTabBehavior.RECENT,
              recentsLimit: 28,
              noRecents: const Text(
                'No Recents',
                style: TextStyle(fontSize: 20, color: Colors.black26),
              ),
              loadingIndicator: const SizedBox.shrink(),
              tabIndicatorAnimDuration: kTabScrollDuration,
              categoryIcons: const CategoryIcons(),
              buttonMode: ButtonMode.MATERIAL,
            ),
          ),
        )
    ],
  ),
),

        ],
      ),
    );
  }
}
