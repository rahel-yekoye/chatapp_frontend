import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  bool isListenerSet = false; // To track if the listener has been added already

  void connect() {
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false, // First set to false
    });

    socket.connect(); // Then connect

    // ✅ Test connection
    socket.onConnect((_) => print('🟢 Socket connected: ${socket.id}'));
    socket.onDisconnect((_) => print('🔴 Socket disconnected'));
    socket.onConnectError((data) => print('❌ Connect Error: $data'));
    socket.onError((data) => print('❌ General Error: $data'));
  }

  // ✅ Join room
  void registerUser(String username) {
    print('Joining room: $username');
    socket.emit('join_room', username);
  }

  // ✅ Send message
  void sendMessage(Map<String, dynamic> messageData) {
    print('📤 Sending message: $messageData');
    socket.emit('send_message', messageData);
  }

  // ✅ Listen to messages (only once)
  void onMessageReceived(Function(Map<String, dynamic>) callback) {
    if (!isListenerSet) { // Only set listener if not already set
      socket.on('receive_message', (data) {
        print('📨 Message received: $data');
        callback(Map<String, dynamic>.from(data));
      });
      isListenerSet = true; // Mark listener as set
    }
  }

  // Reset the listener and socket connection
  void resetListener() {
    isListenerSet = false; // Reset listener flag if needed
  }
  void dispose() {
    socket.dispose();
        resetListener(); // Ensure the listener is reset on dispose
  }
}
