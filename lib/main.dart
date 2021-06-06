import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rentool/screens/FirebaseInitErrorScreen.dart';
import 'package:rentool/screens/HomePage.dart';
import 'package:rentool/screens/LoginScreen.dart';
import 'package:rentool/screens/userScreen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  static _MyAppState of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale;

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      title: 'Rentool',
      onGenerateTitle: (_) => AppLocalizations.of(_).rentool,
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
        var user = snapshot.data;

        if (user == null) {
          print('User signed out');
          return LoginScreen();
        } else {
          print('Signed in as ${user.displayName} ');
          if (!user.emailVerified) {
            print('Email address not verified. sending a verfication email');
            user.sendEmailVerification();
          }
          FirestoreServices.ensureUserExist(user);
          return UserScreen();
          // return HomePage();
        }
      },
    );
  }
}
