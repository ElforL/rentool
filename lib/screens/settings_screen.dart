import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/main.dart';
import 'package:rentool/services/settings_services.dart';
import 'package:rentool/widgets/list_label.dart';
import 'package:rentool/widgets/loading_indicator.dart';
import 'package:rentool/widgets/logo_image.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settings = SettingsServices();

  Future<void> _getSettings() async {
    if (!settings.initiated) return settings.init();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: FutureBuilder(
          future: _getSettings(),
          builder: (context, snapshot) {
            if (!settings.initiated) {
              return const Center(
                child: LoadingIndicator(),
              );
            }
            return ListView(
              children: [
                ListLabel(
                  text: AppLocalizations.of(context)!.notifications,
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(AppLocalizations.of(context)!.enable_notifications),
                  subtitle: Text(AppLocalizations.of(context)!.enable_notifications_subtitle),
                  trailing: Switch(
                    value: settings.getNotificationsEnabled() ?? true,
                    onChanged: (value) async {
                      await settings.setNotificationsEnabled(value);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ListLabel(
                  text: AppLocalizations.of(context)!.view,
                ),
                ListTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(AppLocalizations.of(context)!.language),
                  subtitle: Text(_languageSubtitle()),
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return SingleChoiceSettingScreen(
                            title: Text(AppLocalizations.of(context)!.language),
                            selectedValue: settings.getLanguageCode(),
                            choices: [
                              SettingChoice(
                                displayWidget: Text(
                                  AppLocalizations.of(context)!.device_default('').replaceFirst(': ', ''),
                                ),
                                value: null,
                              ),
                              for (var locale in AppLocalizations.supportedLocales)
                                SettingChoice(
                                  displayWidget: Text(_getLanguageNameFromCode(locale.languageCode) ??
                                      AppLocalizations.of(context)!.english),
                                  value: locale.languageCode,
                                ),
                            ],
                          );
                        },
                      ),
                    );

                    if (result is String || result == null) {
                      settings.setLanguageCode(result);
                      MyApp.of(context)?.setLocale(result == null ? null : Locale(result));
                    }
                  },
                ),
                ListTile(
                  // TODO add theme feature
                  enabled: false,
                  leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                  title: Text(AppLocalizations.of(context)!.theme),
                  subtitle: Text(_themeSubtitle()),
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return SingleChoiceSettingScreen(
                            title: Text(AppLocalizations.of(context)!.theme),
                            selectedValue: settings.getdarkTheme(),
                            choices: [
                              SettingChoice(
                                displayWidget: Text(
                                  AppLocalizations.of(context)!.device_default('').replaceFirst(': ', ''),
                                ),
                                value: null,
                              ),
                              SettingChoice(
                                displayWidget: Text(AppLocalizations.of(context)!.light),
                                value: false,
                              ),
                              SettingChoice(
                                displayWidget: Text(AppLocalizations.of(context)!.dark),
                                value: true,
                              ),
                            ],
                          );
                        },
                      ),
                    );

                    if (result is bool || result == null) {
                      await settings.setdarkTheme(result);
                      setState(() {});
                      // TODO add setBrightness to MyApp
                      // MyApp.of(context)?.setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 20),
                ListLabel(
                  text: AppLocalizations.of(context)!.support,
                ),
                ListTile(
                  leading: const Icon(Icons.help_center),
                  title: Text(AppLocalizations.of(context)!.help_center),
                  onTap: () {
                    // TODO create Help center
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: Text(AppLocalizations.of(context)!.report_an_issue),
                  onTap: () {
                    // TODO
                  },
                ),
                const SizedBox(height: 20),
                ListLabel(
                  text: AppLocalizations.of(context)!.about,
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: Text(AppLocalizations.of(context)!.privacy_policy),
                  onTap: () {
                    // TODO create Privacy policy
                  },
                ),
                ListTile(
                  leading: const Icon(null),
                  title: Text(AppLocalizations.of(context)!.user_agreement),
                  onTap: () {
                    // TODO create User agreement
                  },
                ),
                ListTile(
                  leading: const Icon(null),
                  title: Text(AppLocalizations.of(context)!.software_licenses),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationIcon: SizedBox(
                        height: 40,
                        child: LogoImage.primary(),
                      ),
                      applicationName: '',
                    );
                  },
                ),
              ],
            );
          }),
    );
  }

  String _themeSubtitle() {
    final isDark = settings.getdarkTheme();

    if (isDark == null) {
      final currentTheme = Theme.of(context).brightness == Brightness.dark
          ? AppLocalizations.of(context)!.dark
          : AppLocalizations.of(context)!.light;

      return AppLocalizations.of(context)!.device_default(currentTheme);
    }
    return isDark ? AppLocalizations.of(context)!.dark : AppLocalizations.of(context)!.light;
  }

  String _languageSubtitle() {
    final langCode = settings.getLanguageCode();

    if (langCode == null) {
      final currentLanguage =
          _getLanguageNameFromCode(AppLocalizations.of(context)!.localeName) ?? AppLocalizations.of(context)!.english;
      return AppLocalizations.of(context)!.device_default(currentLanguage);
    }
    return _getLanguageNameFromCode(langCode) ?? AppLocalizations.of(context)!.english;
  }

  /// return the language name based on [langCode]
  ///
  /// e.g., en -> English
  String? _getLanguageNameFromCode(String langCode) {
    switch (langCode) {
      case 'en':
        return AppLocalizations.of(context)!.english;
      case 'ar':
        return AppLocalizations.of(context)!.arabic;
    }
  }
}

class SingleChoiceSettingScreen extends StatefulWidget {
  const SingleChoiceSettingScreen({
    Key? key,
    required this.choices,
    required this.selectedValue,
    this.title,
  }) : super(key: key);

  final List<SettingChoice> choices;
  final Object? selectedValue;
  final Widget? title;

  @override
  State<SingleChoiceSettingScreen> createState() => _SingleChoiceSettingScreenState();
}

class _SingleChoiceSettingScreenState extends State<SingleChoiceSettingScreen> {
  late Object? selectedValue;

  @override
  void initState() {
    selectedValue = widget.selectedValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pop(context, selectedValue);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: widget.title,
        ),
        body: ListView.builder(
          itemCount: widget.choices.length,
          itemBuilder: (context, index) {
            final choice = widget.choices[index];
            return ListTile(
              title: choice.displayWidget,
              leading: const Icon(null),
              trailing: Icon(
                choice.value == selectedValue ? Icons.radio_button_on : Icons.radio_button_off,
                color: choice.value == selectedValue ? Theme.of(context).colorScheme.primary : null,
              ),
              onTap: () {
                setState(() {
                  selectedValue = choice.value;
                });
              },
            );
          },
        ),
      ),
    );
  }
}

class SettingChoice {
  SettingChoice({
    required this.displayWidget,
    required this.value,
  });

  /// the widget that'll be placed in the [ListTile]'s title. preferably a [Text] widget.
  final Widget displayWidget;

  /// the value of the choice.
  final Object? value;
}
