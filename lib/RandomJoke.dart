import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Programming Memes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MemeHomePage(),
    );
  }
}

class Meme {
  final int id;
  final String imageUrl;
  final DateTime created;

  Meme({
    required this.id, 
    required this.imageUrl, 
    required this.created
  });

  factory Meme.fromJson(Map<String, dynamic> json) {
    return Meme(
      id: json['id'],
      imageUrl: json['image'],
      created: DateTime.parse(json['created']),
    );
  }
}

class MemeHomePage extends StatefulWidget {
  @override
  _MemeHomePageState createState() => _MemeHomePageState();
}

class _MemeHomePageState extends State<MemeHomePage> {
  Meme? _currentMeme;
  bool _isLoading = false;
  String? _errorMessage;

  // API Headers
  final Map<String, String> _headers = {
    'x-apihub-key': '0GCBMgx0whQW7d4NIGnNT7AWaczbTfRWGICqnqrkN7dnT4rbSD',
    'x-apihub-host': 'Programming-Memes-Images.allthingsdev.co',
    'x-apihub-endpoint': 'c1752127-9642-42d2-935d-d93c18f65f2c',
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };

  Future<void> _fetchRandomMeme() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://Programming-Memes-Images.proxy-production.allthingsdev.co/v1/memes'),
        headers: _headers,
      );

      developer.log('Response Status Code: ${response.statusCode}', name: 'MemeApp');

      if (response.statusCode == 200) {
        try {
          // Parse the JSON response
          final List<dynamic> memeData = json.decode(response.body);
          
          // Convert to Meme objects
          final List<Meme> memes = memeData.map((json) => Meme.fromJson(json)).toList();

          // Randomly select a meme
          final random = Random();
          final selectedMeme = memes[random.nextInt(memes.length)];

          setState(() {
            _currentMeme = selectedMeme;
            _isLoading = false;
          });

          developer.log('Selected Meme URL: ${_currentMeme?.imageUrl}', name: 'MemeApp');
        } catch (parseError) {
          setState(() {
            _errorMessage = 'Failed to parse meme data: $parseError';
            _isLoading = false;
          });
          developer.log('Parse Error: $parseError', name: 'MemeApp', error: parseError);
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load memes: ${response.reasonPhrase}\n'
                          'Status Code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: ${e.toString()}';
        _isLoading = false;
      });
      developer.log('Fetch meme error', 
        name: 'MemeApp', 
        error: e.toString(),
        stackTrace: StackTrace.current
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Programming Memes'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Detailed error display
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
            // Loading indicator
            else if (_isLoading)
              CircularProgressIndicator()
            // Meme image
            else if (_currentMeme != null)
              Column(
                children: [
                  Image.network(
                    _currentMeme!.imageUrl,
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return CircularProgressIndicator();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Text('Failed to load image: $error');
                    },
                  ),
                  SizedBox(height: 10),
                  Text('Meme ID: ${_currentMeme!.id}'),
                  Text('Created: ${_currentMeme!.created.toLocal()}'),
                ],
              )
            // Initial state
            else
              Text('Press the button to fetch a meme'),

            SizedBox(height: 20),

            // Fetch Meme Button
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchRandomMeme,
              child: Text('Get Random Meme'),
            ),
          ],
        ),
      ),
    );
  }
}