import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/main.dart';
import 'package:rentool/misc/constants.dart';
import 'package:rentool/misc/misc.dart';
import 'package:rentool/screens/terms_screen.dart';
import 'package:rentool/widgets/login/email_sign_screen.dart';
import 'package:rentool/widgets/login/login_providers_container.dart';
import 'package:rentool/widgets/logo_image.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  showAppDialog(BuildContext context) {
    final sheet = BottomSheet(
      onClosing: () {},
      enableDrag: false,
      builder: (context) {
        buttonStyle([bool isGrey = false]) => ButtonStyle(
              backgroundColor: isGrey ? MaterialStateProperty.all(Colors.grey) : null,
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.open_with),
            ),
            ListTile(
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: LogoImage.primaryIcon(),
              ),
              title: Text(AppLocalizations.of(context)!.use_app_4_better),
              trailing: ElevatedButton(
                style: buttonStyle(),
                onPressed: () => launchUrl('$githubRepoUrl/releases'),
                // child: Text(AppLocalizations.of(context)!.download),
                child: Text(AppLocalizations.of(context)!.download.toUpperCase()),
              ),
            ),
            ListTile(
              leading: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.public,
                  size: 34,
                ),
              ),
              title: Text(AppLocalizations.of(context)!.continue_in_browser),
              trailing: ElevatedButton(
                style: buttonStyle(true),
                onPressed: () => Navigator.pop(context),
                // child: Text(AppLocalizations.of(context)!.close),
                child: Text(AppLocalizations.of(context)!.continue_.toUpperCase()),
              ),
            ),
          ],
        );
      },
    );

    showModalBottomSheet(context: context, builder: (context) => sheet);
  }

  @override
  void initState() {
    if (kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      SchedulerBinding.instance?.addPostFrameCallback((_) => showAppDialog(context));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          primary: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    color: Theme.of(context).colorScheme.primary,
                    tooltip: AppLocalizations.of(context)!.language,
                    icon: const Icon(Icons.language),
                    onPressed: () {
                      MyApp.of(context)?.nextLocale(context);
                    },
                  )
                ],
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.only(left: 60, right: 60, top: 60),
                child: LogoImage.primary(),
              ),
              const EmailSignContainer(),
              const AuthProvidersContainer(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: AppLocalizations.of(context)!.by_use_u_agree_2,
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: AppLocalizations.of(context)!.tos,
                        style: TextStyle(color: Colors.blue.shade700),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.of(context).pushNamed(TermsScreen.tosRouteName),
                      ),
                      TextSpan(text: ' ${AppLocalizations.of(context)!.and} '),
                      TextSpan(
                        text: AppLocalizations.of(context)!.privacy_policy,
                        style: TextStyle(color: Colors.blue.shade700),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.of(context).pushNamed(TermsScreen.privacyPolicyRouteName),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
