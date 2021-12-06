import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/screens/account_settings_screen.dart';
import 'package:rentool/screens/admin_panel_screen.dart';
import 'package:rentool/screens/ban_user_screen.dart';
import 'package:rentool/screens/chat_screen.dart';
import 'package:rentool/screens/deliver_meet_screen.dart';
import 'package:rentool/screens/edit_post_screen.dart';
import 'package:rentool/screens/edit_request.dart';
import 'package:rentool/screens/edit_review_screen.dart';
import 'package:rentool/screens/first_screen.dart';
import 'package:rentool/screens/forgot_password_screen.dart';
import 'package:rentool/screens/my_notifications.dart';
import 'package:rentool/screens/my_requests.dart';
import 'package:rentool/screens/my_tools_screen.dart';
import 'package:rentool/screens/new_request_screen.dart';
import 'package:rentool/screens/not_found_screen.dart';
import 'package:rentool/screens/payment_settings_screen.dart';
import 'package:rentool/screens/post_screen.dart';
import 'package:rentool/screens/request_screen.dart';
import 'package:rentool/screens/requests_list_screen.dart';
import 'package:rentool/screens/return_meet_screen.dart';
import 'package:rentool/screens/reviews_screen.dart';
import 'package:rentool/screens/search_screen.dart';
import 'package:rentool/screens/settings_screen.dart';
import 'package:rentool/screens/terms_screen.dart';
import 'package:rentool/screens/user_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/cloud_messaging.dart';
import 'package:rentool/services/settings_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_strategy/url_strategy.dart';

const emulatorOn = true;

/// if the first element in [args] is a [Locale] the locale from [SharedPreferences] will be ignored
void main() async {
  if (kIsWeb) {
    printSelfXssWarning();
    setPathUrlStrategy();
  }

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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

  if (kReleaseMode) FirebaseAnalytics();

  CloudMessagingServices? fcmServices;
  if (!kIsWeb) fcmServices = CloudMessagingServices();

  Locale? locale;

  var envLocale = const String.fromEnvironment('locale');
  if (envLocale.isNotEmpty) {
    locale = Locale(envLocale);
  } else {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('locale');
    locale = langCode != null ? Locale(langCode) : null;
  }

  runApp(MyApp(fcmServices: fcmServices, locale: locale));
}

/// Print warning for the user to not paste any code in the console
///
/// [About Self-XSS](https://en.wikipedia.org/wiki/Self-XSS)
void printSelfXssWarning() {
  // ignore: avoid_print
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

  void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink(onSuccess: (PendingDynamicLinkData? dynamicLink) async {
      final Uri? deepLink = dynamicLink?.link;
      if (deepLink != null) _deepLinkHandler(deepLink);
    }, onError: (OnLinkErrorException e) async {
      debugPrint('onLinkError');
      debugPrint(e.message);
      debugPrint(e.stacktrace);
    });

    final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null) _deepLinkHandler(deepLink);
  }

  Future<void> _deepLinkHandler(Uri deepLink) async {
    if (deepLink.path == '/emailVerified') {
      try {
        // refresh token
        debugPrint('Refreshing user token');
        await AuthServices.currentUser?.getIdToken(true);
        await AuthServices.currentUser?.reload();
      } catch (e, stacktrace) {
        debugPrintStack(label: e.toString(), stackTrace: stacktrace);
      }
    }
  }

  @override
  void initState() {
    _locale = widget.locale;
    super.initState();
    if (!kIsWeb) initDynamicLinks();
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
      onGenerateRoute: (settings) {
        // https://flutter.dev/docs/cookbook/navigation/navigate-with-arguments#alternatively-extract-the-arguments-using-ongenerateroute
        if (settings.name == null) return null;
        final uri = Uri.parse(settings.name!);
        if (uri.pathSegments.isEmpty) return null;
        final firstSegments = '/${uri.pathSegments[0]}';

        // Post Screen
        if (firstSegments == PostScreen.routeName) {
          final uri = Uri.parse(settings.name!);

          Tool? toolArg;

          if (settings.arguments is Tool) {
            // If there's argument. usually when pressed by a button.
            toolArg = settings.arguments as Tool;
          } else if (uri.pathSegments.length >= 2) {
            // no argument but there's a uri toolId
            final toolId = uri.pathSegments[1];
            const emptyString = '...';
            // Blank tool (the screen will call `getToolSnaphots` which will update it based on the id)
            toolArg = Tool(toolId, emptyString, emptyString, emptyString, 0, 0, [], emptyString, false);
          }

          if (toolArg is! Tool) return null; // can't find the tool so, return a 404
          return MaterialPageRoute(
            builder: (context) => const PostScreen(),
            settings: RouteSettings(
              name: PostScreen.routeName + '/${toolArg.id}',
              arguments: toolArg,
            ),
          );
        }

        // Search Screen
        if (firstSegments == SearchScreen.routeName) {
          final uri = Uri.parse(settings.name!);

          String? arg;
          if (settings.arguments is String) {
            arg = settings.arguments as String;
          } else if (uri.pathSegments.length >= 2) {
            // no argument but there's a uri argument
            final searchQuery = uri.pathSegments[1];
            arg = searchQuery;
          }

          if (arg is! String) return null; // return a 404
          return MaterialPageRoute(
            builder: (context) => const SearchScreen(),
            settings: RouteSettings(
              name: SearchScreen.routeName + '/$arg',
              arguments: arg,
            ),
          );
        }

        if (firstSegments == UserScreen.routeName) {
          final uri = Uri.parse(settings.name!);
          String? uid;

          UserScreenArguments? arg;
          if (settings.arguments is UserScreenArguments) {
            arg = settings.arguments as UserScreenArguments;
          } else if (uri.pathSegments.length >= 2) {
            // no argument but there's a uri argument
            uid = uri.pathSegments[1];
            arg = UserScreenArguments(uid: uid);
          }

          if (arg is! UserScreenArguments) return null; // return a 404
          return MaterialPageRoute(
            builder: (context) => const UserScreen(),
            settings: RouteSettings(
              name: UserScreen.routeName + '/$uid',
              arguments: arg,
            ),
          );
        }
      },
      onUnknownRoute: (settings) {
        // If path was any of these cases don't push 404 page
        if (settings.name?.startsWith('/links/emailVer') ?? false) {
          _deepLinkHandler(Uri.parse('https://rentool.site/emailVerified'));
          return null;
        }

        return MaterialPageRoute(builder: (context) => const NotFoundScreen());
      },
      routes: {
        '/': (context) => const FirstScreen(),
        TermsScreen.tosRouteName: (context) => const TermsScreen(isTos: true),
        TermsScreen.privacyPolicyRouteName: (context) => const TermsScreen(isTos: false),
        EditPostScreen.routeNameNew: (context) => const EditPostScreen(),
        EditPostScreen.routeNameEdit: (context) => const EditPostScreen(isEditing: true),
        DeliverMeetScreen.routeName: (context) => const DeliverMeetScreen(),
        ReturnMeetScreen.routeName: (context) => const ReturnMeetScreen(),
        NewRequestScreen.routeName: (context) => const NewRequestScreen(),
        RequestsListScreen.routeName: (context) => const RequestsListScreen(),
        RequestScreen.routeName: (context) => const RequestScreen(),
        MyNotificationsScreen.routeName: (context) => const MyNotificationsScreen(),
        MyRequestsScreen.routeName: (context) => const MyRequestsScreen(),
        MyToolsScreen.routeName: (context) => const MyToolsScreen(),
        EditRequestScreen.routeName: (context) => const EditRequestScreen(),
        EditReviewScreen.routeNameNew: (context) => const EditReviewScreen(isNew: true),
        EditReviewScreen.routeNameEdit: (context) => const EditReviewScreen(isNew: false),
        ReviewsScreen.routeName: (context) => const ReviewsScreen(),
        ChatScreen.routeName: (context) => const ChatScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        AccountSettingsScreen.routeName: (context) => AccountSettingsScreen(),
        ForgotPasswordScreen.routeName: (context) => const ForgotPasswordScreen(),
        AdminPanelScreen.routeName: (context) => AdminPanelScreen(),
        BanUserScreen.routeName: (context) => const BanUserScreen(),
        PaymentSettingsScreen.routeName: (context) => const PaymentSettingsScreen(),
      },
    );
  }
}
