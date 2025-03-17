class Message {
  final String sender;
  final String receiver;
  final String content;
  final DateTime timestamp;

  Message({
    required this.sender,
    required this.receiver,
    required this.content,
    required this.timestamp,
  });

  // Factory constructor to create a Message object from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sender: json['sender'],
      receiver: json['receiver'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  // Convert Message object to JSON
  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'receiver': receiver,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
