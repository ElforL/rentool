import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rentool/screens/FirebaseInitErrorScreen.dart';
import 'package:rentool/screens/HomePage.dart';
import 'package:rentool/screens/LoadingScreen.dart';
import 'package:rentool/screens/LoginScreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirstScreen(),
    );
  }
}

class FirstScreen extends StatefulWidget {
  FirstScreen({Key key}) : super(key: key);

  @override
  _FirstScreenState createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize FlutterFire:
      future: _initialization,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return FirebaseInitErrorScreen(error: snapshot.error);
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          // temporary
          return LoginScreen();
          return HomePage();
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return LoadingScreen();
      },
    );
  }
}
