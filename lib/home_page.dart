import 'package:flutter/material.dart';
import '../screens/chat_screen.dart'; // Make sure to import your chat screen

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select User')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      currentUser: 'Alice',
                      otherUser: 'Bob',
                    ),
                  ),
                );
              },
              child: const Text('Login as Alice'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      currentUser: 'Bob',
                      otherUser: 'Alice',
                    ),
                  ),
                );
              },
              child: const Text('Login as Bob'),
            ),
          ],
        ),
      ),
    );
  }
}
