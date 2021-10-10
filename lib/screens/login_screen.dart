import 'package:flutter/material.dart';
import 'package:rentool/main.dart';
import 'package:rentool/widgets/login/email_sign_screen.dart';
import 'package:rentool/widgets/login/login_providers_container.dart';
import 'package:rentool/widgets/logo_image.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  /// shows an alert dialog
  Future showMyAlert(
    BuildContext context,
    Widget title,
    Widget content, [
    List<Widget>? actions,
  ]) async {
    Widget k = AlertDialog(
      title: title,
      content: content,
      actions: actions,
    );
    return await showDialog(context: context, builder: (context) => k);
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
                    // tooltip: AppLocalizations.of(context)!.lan,
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
