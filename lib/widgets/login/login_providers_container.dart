import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/misc/custom_icons.dart';
import 'package:rentool/services/auth.dart';

class AuthProvidersContainer extends StatelessWidget {
  const AuthProvidersContainer({Key? key}) : super(key: key);

  Widget _buildHorizontalLine() {
    return const Expanded(
      child: Divider(
        indent: 20,
        endIndent: 20,
        color: Colors.black26,
        thickness: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildHorizontalLine(),
            Text(
              AppLocalizations.of(context)!.or.toUpperCase(),
              style: Theme.of(context).textTheme.subtitle2,
            ),
            _buildHorizontalLine(),
          ],
        ),
        const SizedBox(height: 15),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // These buttons aren't localized due to the providers' guidlines
            AuthProviderButton(
              icon: Image.asset('assets/images/google_icon.png'),
              label: const Text(
                'SIGN IN WITH GOOGLE',
                style: TextStyle(fontFamily: 'Roboto'),
              ),
              onPressed: () {
                googleSignin(context);
              },
              margin: const EdgeInsets.all(5),
              backgroundColor: MaterialStateProperty.all(Colors.white),
              foregroundColor: MaterialStateProperty.all(Colors.black54),
            ),
            AuthProviderButton(
              icon: Image.asset('assets/images/Facebook_icon.png'),
              label: const Text(
                'Login with Facebook',
                style: TextStyle(fontFamily: 'Roboto'),
              ),
              onPressed: () {
                facebookSignin(context);
              },
              margin: const EdgeInsets.all(5),
              backgroundColor: MaterialStateProperty.all(const Color(0xFF1877F2)),
              foregroundColor: MaterialStateProperty.all(Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  void googleSignin(BuildContext context) async {
    try {
      await AuthServices.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        showDiffCredsAlert(context, e.email!);
      } else {
        rethrow;
      }
    }
  }

  void facebookSignin(BuildContext context) async {
    try {
      await AuthServices.signInWithFacebook();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        showDiffCredsAlert(context, e.email!);
      } else {
        rethrow;
      }
    }
  }

  void microsoftSignin(BuildContext context) async {
    throw UnimplementedError();
  }

  showDiffCredsAlert(BuildContext context, String email) async {
    var list = await AuthServices.auth.fetchSignInMethodsForEmail(email);
    showMyAlert(
      context,
      Text(AppLocalizations.of(context)!.loginError),
      SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.diff_creds_error,
            ),
            Text(
              AppLocalizations.of(context)!.no_password_error_dialog2(
                list.length,
                list.length != 1 ? list.toString() : list.first,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.no_password_error_dialog3,
            ),
          ],
        ),
      ),
      [
        TextButton(
          onPressed: () {
            sendPassResetEmail(context, email);
          },
          child: Text(AppLocalizations.of(context)!.send_email),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    );
  }

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

  void sendPassResetEmail(context, String email) async {
    try {
      await AuthServices.auth.sendPasswordResetEmail(email: email);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.emailSent),
      ));
    } on FirebaseAuthException catch (e) {
      print('cought');
      Navigator.pop(context);
      if (e.code == 'invalid-email') {
        showMyAlert(
          context,
          Text(AppLocalizations.of(context)!.error),
          Text(AppLocalizations.of(context)!.badEmail),
        );
      } else if (e.code == 'user-not-found') {
        showMyAlert(
          context,
          Text(AppLocalizations.of(context)!.error),
          Text(AppLocalizations.of(context)!.userNotFoundError),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${AppLocalizations.of(context)!.error}: ${AppLocalizations.of(context)!.emailNotSent}'),
      ));
    }
  }
}

class AuthProviderButton extends StatelessWidget {
  const AuthProviderButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.label,
    this.margin,
    this.height = 40,
    this.width = 250,
    this.backgroundColor,
    this.foregroundColor,
    this.shape,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;
  final EdgeInsetsGeometry? margin;
  final double height;
  final double width;
  final MaterialStateProperty<Color>? backgroundColor;
  final MaterialStateProperty<Color>? foregroundColor;
  final MaterialStateProperty<OutlinedBorder?>? shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: shape,
        ),
        child: Directionality(
          // Keeps the Row in ltr so the provider icon is on the left
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              SizedBox(
                height: 18,
                width: 18,
                child: icon,
              ),
              const SizedBox(width: 24),
              label,
            ],
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

var signInOptions = {
  'Google': {
    'backgroundColor': Colors.white,
    'foregroundColor': Colors.black,
    'icon': const Icon(CustomIcons.google),
  },
  'Facebook': {
    'backgroundColor': Colors.blue.shade800,
    'icon': const Icon(CustomIcons.facebook_square),
  },
  // // Needs an apple developer account which costs $99 🤷‍♂️
  // 'Apple': {
  //   'backgroundColor': Colors.black,
  //   'icon': Icon(CustomIcons.apple),
  // },
  // // Has no flutter implementaion
  // 'Microsoft': {
  //   'backgroundColor': Colors.grey.shade800,
  //   'icon': Icon(CustomIcons.microsoft),
  // },
};
