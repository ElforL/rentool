import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/screens/account_settings_screen.dart';
import 'package:rentool/screens/admin_panel_screen.dart';
import 'package:rentool/screens/ban_user_screen.dart';
import 'package:rentool/screens/chat_screen.dart';
import 'package:rentool/screens/deliver_meet_screen.dart';
import 'package:rentool/screens/edit_post_screen.dart';
import 'package:rentool/screens/edit_request.dart';
import 'package:rentool/screens/edit_review_screen.dart';
import 'package:rentool/screens/error_screen.dart';
import 'package:rentool/screens/forgot_password_screen.dart';
import 'package:rentool/screens/home_page.dart';
import 'package:rentool/screens/login_screen.dart';
import 'package:rentool/screens/my_notifications.dart';
import 'package:rentool/screens/my_requests.dart';
import 'package:rentool/screens/my_tools_screen.dart';
import 'package:rentool/screens/new_request_screen.dart';
import 'package:rentool/screens/post_screen.dart';
import 'package:rentool/screens/request_screen.dart';
import 'package:rentool/screens/requests_list_screen.dart';
import 'package:rentool/screens/return_meet_screen.dart';
import 'package:rentool/screens/reviews_screen.dart';
import 'package:rentool/screens/search_screen.dart';
import 'package:rentool/screens/settings_screen.dart';
import 'package:rentool/screens/user_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/cloud_messaging.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/services/settings_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  if (kIsWeb) printSelfXssWarning();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const emulatorOn = true;
  // Configure emulator settings
  if (emulatorOn && !kReleaseMode) {
    try {
      const localhost = '192.168.3.2';

      // //// AUTHENTICATION ////
      await FirebaseAuth.instance.useAuthEmulator(localhost, 9099);

      // //// FIRESTORE ////
      FirebaseFirestore.instance.useFirestoreEmulator(localhost, 8080);

      // STORAGE
      await FirebaseStorage.instance.useStorageEmulator(localhost, 9199);

      // FUNCTIONS
      FirebaseFunctions.instance.useFunctionsEmulator(localhost, 5001);
    } catch (_) {}
  }
  // Turn off persistence (offline access)
  // it's automatically off in web and trying to turn it off manually throws an error
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  CloudMessagingServices? fcmServices;
  if (!kIsWeb) fcmServices = CloudMessagingServices();

  final prefs = await SharedPreferences.getInstance();
  final langCode = prefs.getString('locale');
  final locale = langCode != null ? Locale(langCode) : null;

  runApp(MyApp(fcmServices: fcmServices, locale: locale));
}

void printSelfXssWarning() {
  return print('''
  \u001B[6m\u001B[43m\u001B[31m⚠ WARNING!\u001B[0m
  \u001B[31mDo not enter or paste any code here.
  \u001B[31mUsing the console could allow attackers to steal your information using `\u001B[1m\u001B[3m\u001B[21mSelf-XSS\u001B[0m\u001B[31m`.\u001B[0m''');
}

class MyApp extends StatefulWidget {
  static _MyAppState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();

  const MyApp({Key? key, this.fcmServices, this.locale}) : super(key: key);

  final CloudMessagingServices? fcmServices;
  final Locale? locale;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  CloudMessagingServices? get fcmServices => widget.fcmServices;

  void setLocale(Locale? locale) async {
    setState(() {
      _locale = locale;
    });
  }

  void nextLocale(context) {
    final currentLangCode = AppLocalizations.of(context)?.localeName;
    if (currentLangCode != null) {
      final currentLocale = Locale(currentLangCode);
      final currentIndex = AppLocalizations.supportedLocales.indexOf(currentLocale);
      final nextIndex = (currentIndex + 1) % AppLocalizations.supportedLocales.length;
      final nextLocale = AppLocalizations.supportedLocales.elementAt(nextIndex);
      setLocale(nextLocale);
      final settings = SettingsServices();
      settings.init().then((_) => settings.setLanguageCode(nextLocale.languageCode));
    }
  }

  @override
  void initState() {
    _locale = widget.locale;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      title: 'Rentool',
      onGenerateTitle: (_) => AppLocalizations.of(_)!.rentool,
      // using the builder instead of `theme` to access the context, get the locale
      // and change the font family based on the language
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            inputDecorationTheme: InputDecorationTheme(
              fillColor: Colors.blue.withAlpha(50),
            ),
            fontFamily: AppLocalizations.of(context)!.localeName == 'ar' ? 'Almarai' : null,
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarBrightness: Brightness.light,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
              foregroundColor: Colors.black87,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            primarySwatch: Colors.blue,
          ),
          child: child!,
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const FirstScreen(),
        PostScreen.routeName: (context) => const PostScreen(),
        EditPostScreen.routeNameNew: (context) => const EditPostScreen(),
        EditPostScreen.routeNameEdit: (context) => const EditPostScreen(isEditing: true),
        DeliverMeetScreen.routeName: (context) => const DeliverMeetScreen(),
        ReturnMeetScreen.routeName: (context) => const ReturnMeetScreen(),
        NewRequestScreen.routeName: (context) => const NewRequestScreen(),
        RequestsListScreen.routeName: (context) => const RequestsListScreen(),
        SearchScreen.routeName: (context) => const SearchScreen(),
        RequestScreen.routeName: (context) => const RequestScreen(),
        MyNotificationsScreen.routeName: (context) => const MyNotificationsScreen(),
        MyRequestsScreen.routeName: (context) => const MyRequestsScreen(),
        MyToolsScreen.routeName: (context) => const MyToolsScreen(),
        EditRequestScreen.routeName: (context) => const EditRequestScreen(),
        UserScreen.routeName: (context) => const UserScreen(),
        EditReviewScreen.routeNameNew: (context) => const EditReviewScreen(isNew: true),
        EditReviewScreen.routeNameEdit: (context) => const EditReviewScreen(isNew: false),
        ReviewsScreen.routeName: (context) => const ReviewsScreen(),
        ChatScreen.routeName: (context) => const ChatScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        AccountSettingsScreen.routeName: (context) => AccountSettingsScreen(),
        ForgotPasswordScreen.routeName: (context) => const ForgotPasswordScreen(),
        AdminPanelScreen.routeName: (context) => AdminPanelScreen(),
        BanUserScreen.routeName: (context) => const BanUserScreen(),
      },
    );
  }
}

class FirstScreen extends StatelessWidget {
  const FirstScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthServices.authStateChanges,
      builder: (context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.hasError) {
          return ErrorScreen(
            child: Text(AppLocalizations.of(context)!.couldnt_init_app),
            error: snapshot.error!,
          );
        }
        var user = snapshot.data;
        MyApp.of(context)?.fcmServices?.init(context);

        if (user == null) {
          print('User signed out');
          FirestoreServices.userIdNumber = null;
          return const LoginScreen();
        } else {
          print('Signed in as ${user.displayName ?? '[No Username]'} ');
          final settings = SettingsServices();
          settings.init().then((_) {
            if (settings.getNotificationsEnabled() == null) {
              settings.setNotificationsEnabled(true);
            }

            // Delete or add fcm token to db based on [settings.getNotificationsEnabled()]
            _getDeviceUuidAndName().then((uuidAndName) async {
              if (uuidAndName[0] == null) return;
              final doc = await FirestoreServices.getDeviceTokenDoc(uuidAndName[0]!, user.uid);

              // If the user has no device token but has notification enabled in settings
              // call [settings.setNotificationsEnabled(true)] which will calls [FirestoreService.addDeviceToken()]
              // and if the user has a token but the setting is set to false
              // call [settings.setNotificationsEnabled(false)] which will calls [FirestoreService.deleteDeviceToken()]
              //
              // P.S: getNotificationsEnabled() is nullable that's why I'm using the '==' operator with bools
              // the alternative is `bool? != null && bool!` or `!(bool? ?? false)` which is less readable
              if (doc.data()?['token'] == null && settings.getNotificationsEnabled() == true) {
                settings.setNotificationsEnabled(true);
              } else if (doc.data()?['token'] != null && settings.getNotificationsEnabled() == false) {
                settings.setNotificationsEnabled(false);
              }
            });
          });
          FirestoreServices.updateUserIdNumber();

          return const HomePage();
        }
      },
    );
  }

  Future<List<String?>> _getDeviceUuidAndName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? uuid;
    String? deviceName;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidInfo = await deviceInfo.androidInfo;
        uuid = androidInfo.androidId;
        deviceName = androidInfo.model;
        return [uuid, deviceName];
      case TargetPlatform.iOS:
        final iosInfo = await deviceInfo.iosInfo;
        uuid = iosInfo.identifierForVendor;
        deviceName = iosInfo.model;
        return [uuid, deviceName];
      default:
        print("_getDeviceUuidAndName() doesn't support current platfrom: $defaultTargetPlatform");
        return [null, null];
    }
  }
}
