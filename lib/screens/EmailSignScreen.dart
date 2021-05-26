import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rentool/services/auth.dart';

class EmailSignScreen extends StatefulWidget {
  const EmailSignScreen({Key key}) : super(key: key);

  @override
  _EmailSignScreenState createState() => _EmailSignScreenState();
}

class _EmailSignScreenState extends State<EmailSignScreen> {
  TextEditingController _emailContoller = TextEditingController();
  TextEditingController _passwordContoller = TextEditingController();
  TextEditingController _confirmPasswordContoller = TextEditingController();

  bool _isLogin;

  String emailError;
  String passwordError;
  String confirmPasswordError;

  @override
  void dispose() {
    _emailContoller.dispose();
    _passwordContoller.dispose();
    _confirmPasswordContoller.dispose();
    super.dispose();
  }

  submit() async {
    clearErrors();
    if (_isLogin == null) {
      // not determined if login or signup
      await emailSubmit(_emailContoller.text);
    } else if (_isLogin) {
      // login
      try {
        await AuthServices.signInWithEmailAndPassword(_emailContoller.text, _passwordContoller.text);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          setState(() {
            emailError = 'No user found for that email.';
            _isLogin = false;
          });
        } else if (e.code == 'wrong-password') {
          setState(() {
            passwordError = 'Wrong password.';
          });
        }
      }
    } else {
      // signup
      if (_passwordContoller.text != _confirmPasswordContoller.text)
        // unmatched passwords
        setState(() {
          confirmPasswordError = "Passwords don't match.";
        });

      // matched passwords
      try {
        await AuthServices.createUserWithEmailAndPassword(_emailContoller.text, _passwordContoller.text);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          setState(() {
            passwordError = 'The password provided is too weak.';
          });
        } else if (e.code == 'email-already-in-use') {
          setState(() {
            emailError = 'The account already exists for that email.';
            _isLogin = true;
          });
        }
      } catch (e) {
        print(e);
      }
    }
  }

  emailSubmit(String email) async {
    try {
      var list = await AuthServices.auth.fetchSignInMethodsForEmail(email);
      if (list.isNotEmpty) {
        // user exist
        if (list.contains('password')) {
          // user has an email and password sign in credintials
          setState(() {
            _isLogin = true;
          });
        } else {
          setState(() {
            emailError = "This email address doesn't have a password.\nIt uses login with $list";
          });
          showMyAlert(
            context,
            Text('Sign in Error'),
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "This email address is registerd but doesn't have a password. This means it was used by other sign-in methods (e.g., Google or Facebook).",
                  ),
                  Text(
                    "The provider${list.length > 1 ? 's' : ''} associated with this email address ${list.length > 1 ? 'are' : 'is'} ${list.length > 1 ? list : list.first}. So try signing in with ${list.length > 1 ? 'one of them' : 'it'}",
                  ),
                  SizedBox(height: 10),
                  Text('Or we can send you an email to reset/set your password'),
                ],
              ),
            ),
            [
              TextButton(
                onPressed: () {
                  sendPassResetEmail();
                },
                child: Text('SEND EMAIL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        }
      } else {
        // user doesn't exist
        setState(() {
          _isLogin = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        setState(() {
          emailError = 'The email address is badly formatted';
        });
      }
    }
  }

  void sendPassResetEmail() async {
    try {
      await AuthServices.auth.sendPasswordResetEmail(email: _emailContoller.text);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email sent')));
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      if (e.code == 'invalid-email') {
        showMyAlert(
          context,
          Text('Invalid Email'),
          Text('the email address is not valid'),
        );
      } else if (e.code == 'user-not-found') {
        showMyAlert(
          context,
          Text('User not found'),
          Text('There is no user corresponding to the email address'),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERROR: Email not sent')));
    }
  }

  clearErrors() {
    emailError = null;
    passwordError = null;
    confirmPasswordError = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(30),
      constraints: BoxConstraints(maxWidth: 350),
      child: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTextField(
              controller: _emailContoller,
              onFieldSubmitted: (email) => submit(),
              labelText: 'Email address',
              errorText: emailError,
              autofocus: _isLogin == null,
              autofillHints: [AutofillHints.email],
              onTap: () {
                if (_isLogin != null) {
                  // if the email is chosen (password field(s) are shown) and the user taps on the email textField
                  setState(() {
                    _isLogin = null;
                  });
                }
              },
            ),
            if (_isLogin != null)
              _buildTextField(
                controller: _passwordContoller,
                onFieldSubmitted: (password) => submit(),
                labelText: 'Password',
                errorText: passwordError,
                autofocus: true,
                isPassword: true,
                autofillHints: [AutofillHints.password],
              ),
            if (!(_isLogin ?? true))
              _buildTextField(
                controller: _confirmPasswordContoller,
                onFieldSubmitted: (confirmPassword) => submit(),
                labelText: 'Confirm Password',
                errorText: confirmPasswordError,
                isPassword: true,
                autofillHints: [AutofillHints.password],
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 35,
                child: ElevatedButton(
                  child: Text(_isLogin == null
                      ? 'Next'
                      : _isLogin
                          ? 'Log in'
                          : 'Sign up'),
                  onPressed: () => submit(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

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

  Widget _buildTextField({
    TextEditingController controller,
    ValueChanged<String> onFieldSubmitted,
    String labelText,
    String errorText,
    bool readOnly = false,
    bool autofocus = false,
    GestureTapCallback onTap,
    bool isPassword = false,
    Iterable<String> autofillHints,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        autofillHints: autofillHints,
        onEditingComplete: autofillHints != null ? () => TextInput.finishAutofillContext() : null,
        onTap: onTap,
        readOnly: readOnly,
        controller: controller,
        onFieldSubmitted: onFieldSubmitted,
        autofocus: autofocus,
        enableSuggestions: !isPassword,
        autocorrect: !isPassword,
        obscureText: isPassword,
        decoration: InputDecoration(
          errorText: errorText,
          labelText: labelText,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
