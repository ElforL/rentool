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

  void init() async {
    if (initiated) return;
    sharedPreferences = await SharedPreferences.getInstance();
    if (getNotificationsEnabled() == null) await setNotificationsEnabled(true);
    initiated = true;
  }

  /// if null then the device's langauge is used
  String? getLanguageCode() {
    return sharedPreferences.getString(languageKey);
  }

  Future<bool> setLanguageCode(String newValue) {
    return sharedPreferences.setString(languageKey, newValue);
  }

  bool? getNotificationsEnabled() {
    return sharedPreferences.getBool(notificationsEnabledKey);
  }

  Future<bool> setNotificationsEnabled(bool newValue) {
    // TODO disable sending notification from FCM
    return sharedPreferences.setBool(notificationsEnabledKey, newValue);
  }

  /// if null then the device's theme is used
  bool? getdarkThemeKey() {
    return sharedPreferences.getBool(darkThemeKey);
  }

  Future<bool> setdarkThemeKey(bool newValue) {
    return sharedPreferences.setBool(darkThemeKey, newValue);
  }
}
