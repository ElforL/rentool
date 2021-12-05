import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/main.dart';
import 'package:rentool/screens/terms_screen.dart';
import 'package:rentool/widgets/login/email_sign_screen.dart';
import 'package:rentool/widgets/login/login_providers_container.dart';
import 'package:rentool/widgets/logo_image.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
                  text: TextSpan(
                    text: AppLocalizations.of(context)!.by_use_u_agree_2,
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
