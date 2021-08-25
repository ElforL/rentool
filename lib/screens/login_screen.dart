import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rentool/widgets/login/email_sign_screen.dart';
import 'package:rentool/widgets/login/login_providers_container.dart';

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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 6),
                child: Image.asset('assets/images/Logo/primary.png'),
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
