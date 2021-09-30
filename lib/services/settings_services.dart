import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsServices {
  /// was [settingsServices.init()] called
  bool initiated = false;

  late final SharedPreferences sharedPreferences;

  /// Boolean value
  static const notificationsEnabledKey = 'notifications_enabled';

  /// String value
  static const languageKey = 'locale';

  /// Boolean value
  ///
  /// key for dark or light theme
  static const darkThemeKey = 'dark_theme';

  Future<void> init() async {
    if (initiated) return;
    sharedPreferences = await SharedPreferences.getInstance();
    if (getNotificationsEnabled() == null) await setNotificationsEnabled(true);
    initiated = true;
  }

  /// if null then the device's langauge is used
  String? getLanguageCode() {
    return sharedPreferences.getString(languageKey);
  }

  Future<bool> setLanguageCode(String? newValue) {
    if (newValue != null) {
      return sharedPreferences.setString(languageKey, newValue);
    }
    return sharedPreferences.remove(languageKey);
  }

  bool? getNotificationsEnabled() {
    return sharedPreferences.getBool(notificationsEnabledKey);
  }

  Future<bool> setNotificationsEnabled(bool newValue) async {
    if (!newValue) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String? uuid;
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final androidInfo = await deviceInfo.androidInfo;
          uuid = androidInfo.androidId;
          break;
        case TargetPlatform.iOS:
          final iosInfo = await deviceInfo.iosInfo;
          uuid = iosInfo.identifierForVendor;
          break;
        default:
          print("couldn't identify current platfrom in `setNotificationsEnabled()`");
      }
      if (uuid != null && AuthServices.currentUid != null) {
        FirestoreServices.deleteDeviceToken(uuid, AuthServices.currentUid!);
      }
    }
    return sharedPreferences.setBool(notificationsEnabledKey, newValue);
  }

  /// if null then the device's theme is used
  bool? getdarkTheme() {
    return sharedPreferences.getBool(darkThemeKey);
  }

  Future<bool> setdarkTheme(bool? newValue) {
    if (newValue != null) {
      return sharedPreferences.setBool(darkThemeKey, newValue);
    }
    return sharedPreferences.remove(darkThemeKey);
  }
}
