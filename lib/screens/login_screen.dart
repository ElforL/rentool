import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/main.dart';
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
            ],
          ),
        ),
      ),
    );
  }
}
