class Message {
  final String sender;
  final String receiver;
  final String content;
  final String timestamp;

  Message({
    required this.sender,
    required this.receiver,
    required this.content,
    required this.timestamp,
  });

  // Factory method to create a Message object from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sender: json['sender'] ?? 'Unknown', // Provide a default value
      receiver: json['receiver'] ?? 'Unknown', // Provide a default value
      content: json['content'] ?? '', // Provide a default value
      timestamp: json['timestamp'] ?? '', // Provide a default value
    );
  }

  // Method to convert a Message object to JSON
  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'receiver': receiver,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
