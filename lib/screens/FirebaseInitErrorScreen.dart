import 'package:flutter/material.dart';

class FirebaseInitErrorScreen extends StatefulWidget {
  final Object error;

  const FirebaseInitErrorScreen({Key key, this.error}) : super(key: key);

  @override
  _FirebaseInitErrorScreenState createState() => _FirebaseInitErrorScreenState();
}

class _FirebaseInitErrorScreenState extends State<FirebaseInitErrorScreen> {
  bool _showInfo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Something went wrong'),
            Text('Couldn\'t initialize Firebase app'),
            SizedBox(height: 30),
            TextButton(
              onPressed: () {
                setState(() {
                  _showInfo = !_showInfo;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('More Info'),
              ),
            ),
            if (_showInfo)
              Text(
                'error type: ${widget.error.runtimeType}\n${widget.error.toString()}',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
