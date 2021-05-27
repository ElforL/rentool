import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:rentool/screens/EmailSignScreen.dart';
import 'package:rentool/services/auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key key}) : super(key: key);

  /// shows an alert dialog
  Future showMyAlert(
    BuildContext context,
    Widget title,
    Widget content, [
    List<Widget> actions,
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
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AppLocalizations.of(context).login_welcome,
                  style: Theme.of(context).textTheme.headline5,
                ),
              ),
              EmailSignScreen(),
              for (var option in signInOptions.entries)
                Container(
                  constraints: BoxConstraints(maxWidth: 250),
                  // width: 250,
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.all(kIsWeb ? 17 : 10)),
                      backgroundColor: option.value['backgroundColor'] == null
                          ? null
                          : MaterialStateProperty.all<Color>(option.value['backgroundColor'] as Color),
                      foregroundColor: option.value['foregroundColor'] == null
                          ? null
                          : MaterialStateProperty.all<Color>(option.value['foregroundColor'] as Color),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: option.value['icon'] == null
                              ? Icon(Icons.error)
                              : option.value['icon'] as Widget, //Icon(Icons.email),
                        ),
                        Text(
                          '${AppLocalizations.of(context).sign_in_with} ${option.key}',
                        ),
                      ],
                    ),
                    onPressed: () {
                      switch (option.key) {
                        case 'Google':
                          googleSignin(context);
                          break;
                        case 'Facebook':
                          facebookSignin(context);
                          break;
                        case 'Apple':
                          appleSignin();
                          break;
                        case 'Microsoft':
                          microsoftSignin();
                          break;
                        default:
                          print('Could not find assigned method for sign-in button. ${option.key}');
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void googleSignin(BuildContext context) async {
    try {
      await AuthServices.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        showDiffCredsAlert(context, e.email);
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
        showDiffCredsAlert(context, e.email);
      } else {
        rethrow;
      }
    }
  }

  showDiffCredsAlert(BuildContext context, String email) async {
    var list = await AuthServices.auth.fetchSignInMethodsForEmail(email);
    showMyAlert(
      context,
      Text(AppLocalizations.of(context).loginError),
      SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).diff_creds_error,
            ),
            Text(
              AppLocalizations.of(context).no_password_error_dialog2(
                list.length > 1 ? 's' : '',
                list.length > 1 ? 'are' : 'is',
                list.length > 1 ? list : list.first,
                list.length > 1 ? 'one of them' : 'it',
              ),
            ),
            SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).no_password_error_dialog3,
            ),
          ],
        ),
      ),
      [
        TextButton(
          onPressed: () {
            sendPassResetEmail(context, email);
          },
          child: Text(AppLocalizations.of(context).send_email),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context).ok),
        ),
      ],
    );
  }

  void sendPassResetEmail(context, String email) async {
    try {
      await AuthServices.auth.sendPasswordResetEmail(email: email);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).emailSent),
      ));
    } on FirebaseAuthException catch (e) {
      print('cought');
      Navigator.pop(context);
      if (e.code == 'invalid-email') {
        showMyAlert(
          context,
          Text(AppLocalizations.of(context).error),
          Text(AppLocalizations.of(context).badEmail),
        );
      } else if (e.code == 'user-not-found') {
        showMyAlert(
          context,
          Text(AppLocalizations.of(context).error),
          Text(AppLocalizations.of(context).userNotFoundError),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${AppLocalizations.of(context).error}: ${AppLocalizations.of(context).emailNotSent}'),
      ));
    }
  }

  void appleSignin() {
    // _auth.signInWithApple();
  }

  void microsoftSignin() {
    //
  }
}

var signInOptions = {
  'Google': {
    'backgroundColor': Colors.white,
    'foregroundColor': Colors.black,
    'icon': Icon(AntDesign.google),
  },
  'Facebook': {
    'backgroundColor': Colors.blue.shade800,
    'icon': Icon(FontAwesome.facebook_square),
  },
  // // Needs an apple developer account which costs $99 🤷‍♂️
  // 'Apple': {
  //   'backgroundColor': Colors.black,
  //   'icon': Icon(FontAwesome.apple),
  // },
  // // Azure subscription is free for only 12 months 🤔
  // 'Microsoft': {
  //   'backgroundColor': Colors.grey.shade800,
  //   'icon': Icon(MaterialCommunityIcons.microsoft),
  // },
};
