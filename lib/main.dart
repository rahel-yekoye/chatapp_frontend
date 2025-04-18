import 'package:chat_app_flutter/home_page.dart';
import 'package:flutter/material.dart';
import 'screens/register_screen.dart'; // Import the RegisterScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(), // Set RegisterScreen as the initial screen
    );
  }
}
