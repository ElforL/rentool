import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:rentool/screens/EmailSignScreen.dart';
import 'package:rentool/services/auth.dart';

class LoginScreen extends StatelessWidget {
  final AuthServices _auth;

  const LoginScreen(this._auth, {Key key}) : super(key: key);

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
                  'Sign-in to your Rentool Account',
                  style: Theme.of(context).textTheme.headline5,
                ),
              ),
              EmailSignScreen(_auth),
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
                          padding: const EdgeInsets.only(right: 10),
                          child: option.value['icon'] == null
                              ? Icon(Icons.error)
                              : option.value['icon'] as Widget, //Icon(Icons.email),
                        ),
                        Text(
                          'Sign in in with ${option.key}',
                        ),
                      ],
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

  void googleSignin() {
    _auth.signInWithGoogle();
  }

  void facebookSignin() {
    // _auth.signInWithFacebook();
  }

  void appleSignin() {
    _auth.signInWithApple();
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
  'Apple': {
    'backgroundColor': Colors.black,
    'icon': Icon(FontAwesome.apple),
  },
  'Microsoft': {
    'backgroundColor': Colors.grey.shade800,
    'icon': Icon(MaterialCommunityIcons.microsoft),
  },
};
