import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_screen.dart'; // Ensure this path is correct

class SearchScreen extends StatefulWidget {
  final String loggedInUser; // Pass the logged-in user's ID or username
  final String jwtToken; // Pass the JWT token

  const SearchScreen({
    required this.loggedInUser,
    required this.jwtToken,
    Key? key,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();
  Map<String, dynamic>? _searchResult;
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _searchUser() async {
    final phoneNumber = _phoneNumberController.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a phone number.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/search?phoneNumber=$phoneNumber'),
        headers: {
          'Authorization': 'Bearer ${widget.jwtToken}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _searchResult = jsonDecode(response.body)['user'];
          _errorMessage = null;
        });
      } else {
        setState(() {
          _searchResult = null;
          _errorMessage = jsonDecode(response.body)['error'];
        });
      }
    } catch (error) {
      setState(() {
        _searchResult = null;
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Enter phone number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchUser,
              child: const Text('Search'),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            if (_searchResult != null)
              Column(
                children: [
                  Text('Username: ${_searchResult!['username']}'),
                  Text('Phone Number: ${_searchResult!['phoneNumber']}'),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to chat screen with the found user
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            currentUser: widget.loggedInUser, // Match the parameter name
                            otherUser: _searchResult!['username'], // Match the parameter name
                            jwtToken: widget.jwtToken, // Pass the required jwtToken parameter
                          ),
                        ),
                      );
                    },
                    child: const Text('Start Chat'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class SearchUserScreen extends StatelessWidget {
  final String loggedInUser;
  final String jwtToken;

  const SearchUserScreen({
    required this.loggedInUser,
    required this.jwtToken,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search User'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchScreen(
                  loggedInUser: loggedInUser,
                  jwtToken: jwtToken,
                ),
              ),
            );
          },
          child: const Text('Search User'),
        ),
      ),
    );
  }
}