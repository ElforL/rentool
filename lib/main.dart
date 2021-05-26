import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rentool/screens/FirebaseInitErrorScreen.dart';
import 'package:rentool/screens/HomePage.dart';
import 'package:rentool/screens/LoginScreen.dart';
import 'package:rentool/services/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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

class FirstScreen extends StatelessWidget {
  FirstScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // Initialize FlutterFire:
      stream: AuthServices.authStateChanges,
      builder: (context, AsyncSnapshot<User> snapshot) {
        if (snapshot.hasError) return FirebaseInitErrorScreen(error: snapshot.error);

        if (!AuthServices.isSignedIn) {
          print('User signed out');
          return LoginScreen();
        } else {
          print('User ${snapshot.data.displayName} signed in');
          if (!snapshot.data.emailVerified) {
            print('Email address not verified. sending a verfication email');
            snapshot.data.sendEmailVerification();
          }
          return HomePage();
        }
      },
    );
  }
}
