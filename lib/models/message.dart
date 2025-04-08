class Message {
  final String sender;
  final String receiver;
  final String content;
  final String timestamp;
  final bool isGroup;
  final List<dynamic> emojis;
  final String fileUrl;

  Message({
    required this.sender,
    required this.receiver,
    required this.content,
    required this.timestamp,
    required this.isGroup,
    required this.emojis,
    required this.fileUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sender: json['sender'],
      receiver: json['receiver'],
      content: json['content'] ?? '',
      timestamp: json['timestamp'] ?? '',
      isGroup: json['isGroup'] ?? false,
      emojis: json['emojis'] ?? [],
      fileUrl: json['fileUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'receiver': receiver,
      'content': content,
      'timestamp': timestamp,
      'isGroup': isGroup,
      'emojis': emojis,
      'fileUrl': fileUrl,
    };
  }
}
