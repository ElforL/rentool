import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/main.dart';
import 'package:rentool/screens/error_screen.dart';
import 'package:rentool/screens/login_screen.dart';
import 'package:rentool/screens/no_network_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/services/settings_services.dart';
import 'package:rentool/screens/home_page.dart';

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
          FirestoreServices.updateChecklist();
          return StreamBuilder(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, AsyncSnapshot<ConnectivityResult?> snapshot) {
              if (snapshot.data == ConnectivityResult.none) {
                return const NoNetworkScreen();
              }
              return const LoginScreen();
            },
          );
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
          FirestoreServices.updateChecklist();

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
