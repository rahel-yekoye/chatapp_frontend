import 'package:flutter/material.dart';
import '../screens/register_screen.dart'; // Import the Register screen
import '../screens/login_screen.dart'; // Import the Login screen

class HomePage extends StatelessWidget {
  final String? loggedInUser; // Add a parameter for the logged-in user

  const HomePage({super.key, this.loggedInUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(loggedInUser != null
            ? 'Welcome, $loggedInUser'
            : 'Welcome to Chat App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loggedInUser == null) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text('Register'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Login'),
              ),
            ] else ...[
              const Text('You are logged in!'),
            ],
          ],
        ),
      ),
    );
  }
}
