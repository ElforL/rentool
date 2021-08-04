import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/screens/FirebaseInitErrorScreen.dart';
import 'package:rentool/screens/LoginScreen.dart';
import 'package:rentool/screens/userScreen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/cloud_messaging.dart';
import 'package:rentool/services/firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const EMULATOR_ON = true;
  // Configure emulator settings
  if (EMULATOR_ON && !kReleaseMode) {
    final localhost = defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';

    // //// AUTHENTICATION ////
    await FirebaseAuth.instance.useAuthEmulator('$localhost', 9099);

    // //// FIRESTORE ////
    FirebaseFirestore.instance.useFirestoreEmulator(localhost, 8080);

    // STORAGE
    await FirebaseStorage.instance.useStorageEmulator('$localhost', 9199);
  }
  // Turn off persistence (offline access)
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: false,
    );
  }

  CloudMessagingServices? fcmServices;
  if (!kIsWeb) fcmServices = CloudMessagingServices();
  await fcmServices?.init();

  runApp(MyApp(fcmServices: fcmServices));
}

class MyApp extends StatefulWidget {
  static _MyAppState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();
  const MyApp({Key? key, this.fcmServices}) : super(key: key);

  final CloudMessagingServices? fcmServices;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  CloudMessagingServices? get fcmServices => widget.fcmServices;

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
      onGenerateTitle: (_) => AppLocalizations.of(_)!.rentool,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirstScreen(),
    );
  }
}

class FirstScreen extends StatelessWidget {
  FirstScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // Initialize FlutterFire:
      stream: AuthServices.authStateChanges,
      builder: (context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.hasError) return FirebaseInitErrorScreen(error: snapshot.error!);
        var user = snapshot.data;

        if (user == null) {
          print('User signed out');
          return LoginScreen();
        } else {
          print('Signed in as ${user.displayName ?? '[Unser Name]'} ');
          if (!user.emailVerified) {
            print('Email address not verified.');
          }
          FirestoreServices.ensureUserExist(user).then((userDocExists) {
            if (userDocExists) addFcmTokenToDb(user, AppLocalizations.of(context)!.localeName);
          });

          return UserScreen();
        }
      },
    );
  }

  void addFcmTokenToDb(User user, String languageCode) async {
    if (kIsWeb) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      FirestoreServices.addDeviceToken(token, user.uid, languageCode);
    }
  }
}
