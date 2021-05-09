import 'package:flutter/material.dart';
import 'package:rentool/services/auth.dart';

class LoginScreen extends StatelessWidget {
  AuthServices _auth = AuthServices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var option in signInOptions.entries)
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: option.value['backgroundColor'] == null
                        ? null
                        : MaterialStateProperty.all<Color>(option.value['backgroundColor']!),
                    foregroundColor: option.value['foregroundColor'] == null
                        ? null
                        : MaterialStateProperty.all<Color>(option.value['foregroundColor']!),
                  ),
                  child: Text(
                    'Sign in in with ${option.key}',
                  ),
                  onPressed: () {
                    switch (option.key) {
                      case 'Google':
                        googleSignin();
                        break;
                      case 'Facebook':
                        facebookSignin();
                        break;
                      case 'Apple':
                        appleSignin();
                        break;
                      case 'Microsoft':
                        microsoftSignin();
                        break;
                      case 'Email':
                        emailSignin();
                        break;
                      default:
                        print('Could not find assigned method for sign-in button. ${option.key}');
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void googleSignin() {
    print('Google');
    _auth.signInWithGoogle();
  }

  void facebookSignin() {
    _auth.signInWithFacebook();
  }

  void appleSignin() {
    _auth.signInWithApple();
  }

  void microsoftSignin() {
    //
  }
  void emailSignin() {
    //
  }
}

var signInOptions = {
  'Google': {
    'backgroundColor': Colors.white,
    'foregroundColor': Colors.black,
  },
  'Facebook': {
    'backgroundColor': Colors.blue.shade800,
  },
  'Apple': {
    'backgroundColor': Colors.black,
  },
  'Microsoft': {
    'backgroundColor': Colors.grey.shade800,
  },
  'Email': {
    'backgroundColor': Colors.red,
  },
};
