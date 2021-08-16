import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/screens/firebase_init_error_screen.dart';
import 'package:rentool/screens/home_page.dart';
import 'package:rentool/screens/login_screen.dart';
import 'package:rentool/screens/user_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/cloud_messaging.dart';
import 'package:rentool/services/firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const emulatorOn = true;
  // Configure emulator settings
  if (emulatorOn && !kReleaseMode) {
    final localhost = defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';

    // //// AUTHENTICATION ////
    await FirebaseAuth.instance.useAuthEmulator(localhost, 9099);

    // //// FIRESTORE ////
    FirebaseFirestore.instance.useFirestoreEmulator(localhost, 8080);

    // STORAGE
    await FirebaseStorage.instance.useStorageEmulator(localhost, 9199);
  }
  // Turn off persistence (offline access)
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
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
        appBarTheme: const AppBarTheme(
          backwardsCompatibility: false,
          foregroundColor: Colors.black87,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        primarySwatch: Colors.blue,
      ),
      home: const FirstScreen(),
    );
  }
}

class FirstScreen extends StatelessWidget {
  const FirstScreen({Key? key}) : super(key: key);

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
          return const LoginScreen();
        } else {
          print('Signed in as ${user.displayName ?? '[Unser Name]'} ');
          if (!user.emailVerified) {
            print('Email address not verified.');
          }
          FirestoreServices.ensureUserExist(user).then((userDocExists) {
            if (userDocExists) addFcmTokenToDb(user, AppLocalizations.of(context)!.localeName);
          });

          return const HomePage();
          return const UserScreen();
        }
      },
    );
  }

  void addFcmTokenToDb(User user, String languageCode) async {
    if (kIsWeb) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? uuid;
    String? deviceName;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidInfo = await deviceInfo.androidInfo;
        uuid = androidInfo.androidId;
        deviceName = androidInfo.model;
        break;
      case TargetPlatform.iOS:
        final iosInfo = await deviceInfo.iosInfo;
        uuid = iosInfo.identifierForVendor;
        deviceName = iosInfo.model;
        break;
      default:
        print("addFcmTokenToDb() couldn't identify current platfrom");
        return;
    }

    if (uuid != null) FirestoreServices.addDeviceToken(token, user.uid, uuid, deviceName);
  }
}
