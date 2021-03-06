import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/main.dart';
import 'package:rentool/misc/constants.dart';
import 'package:rentool/misc/misc.dart';
import 'package:rentool/screens/terms_screen.dart';
import 'package:rentool/services/auth.dart';
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
                if (!kIsWeb || AuthServices.currentUser != null) ...[
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
                ],
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
                const SizedBox(height: 20),
                ListLabel(
                  text: AppLocalizations.of(context)!.support,
                ),
                ListTile(
                  leading: const Icon(Icons.support),
                  title: Text(AppLocalizations.of(context)!.contact_support),
                  onTap: () {
                    launchUrl('mailto:$supportEmailAddress');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: Text(AppLocalizations.of(context)!.help_contact_us),
                  onTap: () {
                    launchUrl('mailto:$helpEmailAddress');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: Text(AppLocalizations.of(context)!.report_an_issue),
                  onTap: () {
                    try {
                      launchUrl(issueReportFormMailtoLink(defaultTargetPlatform, context));
                    } catch (e) {
                      _showCouldntEmailDialog(context);
                    }
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
                    Navigator.of(context).pushNamed(TermsScreen.privacyPolicyRouteName);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.article),
                  title: Text(AppLocalizations.of(context)!.tos),
                  onTap: () {
                    Navigator.of(context).pushNamed(TermsScreen.tosRouteName);
                  },
                ),
                ListTile(
                  leading: const Icon(null),
                  title: Text(AppLocalizations.of(context)!.software_licenses),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (BuildContext context) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            appBarTheme: const AppBarTheme(backgroundColor: Colors.grey),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: LicensePage(
                              applicationIcon: SizedBox(
                                height: 40,
                                child: LogoImage.primary(),
                              ),
                              applicationName: '',
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            );
          }),
    );
  }

  Future<dynamic> _showCouldntEmailDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.couldnt_open_email_client),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.couldnt_open_email_client_desc + '\n'),
            Text(AppLocalizations.of(context)!.send_issue_to_this_email_address),
            SelectableText(
              reportIssueEmailAddress,
              onTap: () {
                Clipboard.setData(const ClipboardData(text: reportIssueEmailAddress));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(AppLocalizations.of(context)!.email_address_copied),
                ));
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.ok.toUpperCase()),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
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
