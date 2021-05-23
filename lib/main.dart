import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rentool/screens/FirebaseInitErrorScreen.dart';
import 'package:rentool/screens/HomePage.dart';
import 'package:rentool/screens/LoadingScreen.dart';
import 'package:rentool/screens/LoginScreen.dart';
import 'package:rentool/services/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final AuthServices _auth = AuthServices();

  runApp(MyApp(_auth));
}

class MyApp extends StatelessWidget {
  final AuthServices _auth;

  const MyApp(this._auth);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirstScreen(_auth),
    );
  }
}

class FirstScreen extends StatelessWidget {
  final AuthServices _auth;
  FirstScreen(this._auth, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // Initialize FlutterFire:
      stream: _auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) return FirebaseInitErrorScreen(error: snapshot.error);

        if (!_auth.isSignedIn) {
          print('user signed out');
          return LoginScreen(_auth);
        } else {
          print('user signed in');
          return HomePage(_auth);
        }
      },
    );
  }
}
