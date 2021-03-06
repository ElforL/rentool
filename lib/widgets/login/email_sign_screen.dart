import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/main.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/screens/forgot_password_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/functions.dart';

class EmailSignContainer extends StatefulWidget {
  const EmailSignContainer({Key? key}) : super(key: key);

  @override
  _EmailSignContainerState createState() => _EmailSignContainerState();
}

class _EmailSignContainerState extends State<EmailSignContainer> {
  final TextEditingController _emailContoller = TextEditingController();
  final TextEditingController _usernameContoller = TextEditingController();
  final TextEditingController _passwordContoller = TextEditingController();
  final TextEditingController _confirmPasswordContoller = TextEditingController();

  bool? _isLogin;
  bool _showPasswords = false;
  bool _isLoading = false;

  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? usernameError;

  @override
  void dispose() {
    _emailContoller.dispose();
    _usernameContoller.dispose();
    _passwordContoller.dispose();
    _confirmPasswordContoller.dispose();
    super.dispose();
  }

  submit() async {
    if (_emailContoller.text.isEmpty) return;
    clearErrors();
    if (_isLogin == null) {
      // not determined if login or signup
      await emailSubmit(_emailContoller.text);
    } else if (_isLogin!) {
      // login
      try {
        bool shouldReturn = false;
        if (_emailContoller.text.isEmpty) {
          emailError = AppLocalizations.of(context)!.you_cant_leave_this_empty;
          shouldReturn = true;
        }
        if (_passwordContoller.text.isEmpty) {
          passwordError = AppLocalizations.of(context)!.you_cant_leave_this_empty;
          shouldReturn = true;
        }
        if (shouldReturn) return;
        setState(() => _isLoading = true);

        await AuthServices.signInWithEmailAndPassword(_emailContoller.text, _passwordContoller.text);

        setState(() => _isLoading = false);
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);

        if (e.code == 'user-not-found') {
          setState(() {
            emailError = AppLocalizations.of(context)!.userNotFoundError;
            _isLogin = false;
          });
        } else if (e.code == 'wrong-password') {
          setState(() {
            passwordError = AppLocalizations.of(context)!.wrongPassword;
          });
        } else {
          showMyAlert(
            context,
            Text(AppLocalizations.of(context)!.loginError),
            SelectableText(AppLocalizations.of(context)!.errorInfo + '\n${e.code}:${e.message}'),
            [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.ok),
              )
            ],
          );
          debugPrint(e.code);
        }
      } catch (e) {
        setState(() => _isLoading = false);

        showErrorDialog(context);
      }
    } else {
      // signup
      bool shouldReturn = false;
      if (_emailContoller.text.isEmpty) {
        emailError = AppLocalizations.of(context)!.you_cant_leave_this_empty;
        shouldReturn = true;
      }
      if (_usernameContoller.text.isEmpty) {
        usernameError = AppLocalizations.of(context)!.you_cant_leave_this_empty;
        shouldReturn = true;
      }
      if (_passwordContoller.text.isEmpty) {
        passwordError = AppLocalizations.of(context)!.you_cant_leave_this_empty;
        shouldReturn = true;
      }
      if (_confirmPasswordContoller.text.isEmpty) {
        confirmPasswordError = AppLocalizations.of(context)!.you_cant_leave_this_empty;
        shouldReturn = true;
      }
      if (shouldReturn) {
        setState(() {});
        return;
      }

      if (_passwordContoller.text != _confirmPasswordContoller.text) {
        // unmatched passwords
        setState(() {
          confirmPasswordError = AppLocalizations.of(context)!.pass_not_match;
        });
        return;
      }
      if (!_isPasswordStrong(_passwordContoller.text)) {
        setState(() {
          passwordError = AppLocalizations.of(context)!.weak_password;
        });
        return;
      }

      // matched passwords
      try {
        setState(() => _isLoading = true);

        await AuthServices.createUserWithEmailAndPassword(
          _emailContoller.text,
          _passwordContoller.text,
        );
        await FunctionsServices.updateUsername(_usernameContoller.text.trim());

        try {
          setState(() => _isLoading = false);

          MyApp.of(context)?.setState(() {});
        } catch (_) {}
      } on FirebaseAuthException catch (e) {
        _isLoading = false;

        if (e.code == 'weak-password') {
          setState(() {
            passwordError = AppLocalizations.of(context)!.weak_password;
          });
        } else if (e.code == 'email-already-in-use') {
          setState(() {
            emailError = AppLocalizations.of(context)!.email_already_in_use;
            _isLogin = true;
          });
        } else {
          setState(() {});
          showMyAlert(
            context,
            Text(AppLocalizations.of(context)!.signUpError),
            SelectableText(AppLocalizations.of(context)!.errorInfo + '\n${e.code}:${e.message}'),
            [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.ok),
              )
            ],
          );
        }
      } catch (e, stacktrace) {
        debugPrintStack(label: 'Signup non firebase error: ${e.runtimeType} - $e', stackTrace: stacktrace);
        if (e is FlutterError) debugPrintStack(stackTrace: e.stackTrace);

        try {
          setState(() => _isLoading = false);
        } catch (_) {}

        showMyAlert(
          context,
          Text(AppLocalizations.of(context)!.signUpError),
          SelectableText(AppLocalizations.of(context)!.errorInfo + e.toString()),
          [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.ok),
            )
          ],
        );
      }
    }
  }

  emailSubmit(String email) async {
    try {
      setState(() => _isLoading = true);

      var list = await AuthServices.auth.fetchSignInMethodsForEmail(email);

      setState(() => _isLoading = false);

      if (list.isNotEmpty) {
        // user exist
        if (list.contains('password')) {
          // user has an email and password sign in credintials
          setState(() {
            _isLogin = true;
          });
        } else {
          setState(() {
            emailError = AppLocalizations.of(context)!.no_password_error(list);
          });
          showMyAlert(
            context,
            Text(AppLocalizations.of(context)!.loginError),
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.no_password_error_dialog1,
                  ),
                  Text(
                    AppLocalizations.of(context)!.no_password_error_dialog2(
                      list.length,
                      list.length != 1 ? list.toString() : list.first,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(AppLocalizations.of(context)!.no_password_error_dialog3),
                ],
              ),
            ),
            [
              TextButton(
                onPressed: () {
                  sendPassResetEmail();
                },
                child: Text(AppLocalizations.of(context)!.send_email.toUpperCase()),
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
      } else {
        // user doesn't exist
        setState(() {
          _isLogin = false;
        });
      }
    } on FirebaseAuthException catch (e, stacktrace) {
      setState(() => _isLoading = false);

      if (e.code == 'invalid-email') {
        setState(() {
          emailError = AppLocalizations.of(context)!.badEmail;
        });
      } else {
        showMyAlert(
          context,
          Text(AppLocalizations.of(context)!.loginError),
          SelectableText(AppLocalizations.of(context)!.errorInfo + e.toString()),
          [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.ok),
            )
          ],
        );
        debugPrintStack(label: e.toString(), stackTrace: stacktrace);
      }
    } catch (e, stacktrace) {
      setState(() => _isLoading = false);

      debugPrintStack(label: e.toString(), stackTrace: stacktrace);
    }
  }

  void sendPassResetEmail() async {
    try {
      await AuthServices.auth.sendPasswordResetEmail(email: _emailContoller.text);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.emailSent),
      ));
    } on FirebaseAuthException catch (e) {
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
    } catch (e) {
      showMyAlert(
        context,
        Text(AppLocalizations.of(context)!.loginError),
        SelectableText(AppLocalizations.of(context)!.errorInfo + e.toString()),
        [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          )
        ],
      );
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
      padding: const EdgeInsets.all(30),
      constraints: const BoxConstraints(maxWidth: 350),
      child: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTextField(
              controller: _emailContoller,
              onFieldSubmitted: (email) => submit(),
              labelText: AppLocalizations.of(context)!.emailAddress,
              errorText: emailError,
              autofillHints: [AutofillHints.email],
              onTap: () {
                if (_isLogin != null && !_isLoading) {
                  // if the email is chosen (password field(s) are shown) and the user taps on the email textField
                  setState(() {
                    _isLogin = null;
                  });
                }
              },
            ),
            if (!(_isLogin ?? true))
              _buildTextField(
                controller: _usernameContoller,
                labelText: AppLocalizations.of(context)!.username,
                errorText: usernameError,
                autofillHints: [AutofillHints.username],
              ),
            if (_isLogin != null)
              _buildTextField(
                controller: _passwordContoller,
                onFieldSubmitted: (password) => submit(),
                labelText: AppLocalizations.of(context)!.password,
                errorText: passwordError,
                autofocus: true,
                isPassword: true,
                autofillHints: [AutofillHints.password],
              ),
            if (!(_isLogin ?? true)) ...[
              _buildTextField(
                controller: _confirmPasswordContoller,
                onFieldSubmitted: (confirmPassword) => submit(),
                labelText: AppLocalizations.of(context)!.form_confirm_password,
                errorText: confirmPasswordError,
                isPassword: true,
                autofillHints: [AutofillHints.password],
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 35,
                child: ElevatedButton(
                  key: const Key('SubmitButton'),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : Text(_isLogin == null
                          ? AppLocalizations.of(context)!.next.toUpperCase()
                          : _isLogin!
                              ? AppLocalizations.of(context)!.login
                              : AppLocalizations.of(context)!.signUp),
                  onPressed: _isLoading ? null : () => submit(),
                ),
              ),
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.forgot_your_password),
              onPressed: () async {
                Navigator.pushNamed(context, ForgotPasswordScreen.routeName, arguments: _emailContoller.text.trim());
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isPasswordStrong(String password) {
    if (password.length < 10) {
      return false;
    } else if (!password.contains(RegExp('[a-zA-Z\u0621-\u064A]'))) {
      return false;
    } else if (!password.contains(RegExp(r'[@$!%*#?&^]'))) {
      return false;
    } else if (!password.contains(RegExp(r'[\d]'))) {
      return false;
    }
    return true;
  }

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

  Widget _buildTextField({
    TextEditingController? controller,
    ValueChanged<String>? onFieldSubmitted,
    String? labelText,
    String? errorText,
    bool readOnly = false,
    bool autofocus = false,
    GestureTapCallback? onTap,
    bool isPassword = false,
    Iterable<String>? autofillHints,
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
        obscureText: !_showPasswords && isPassword,
        decoration: InputDecoration(
          suffixIcon: !isPassword
              ? null
              : IconButton(
                  icon: Icon(_showPasswords ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _showPasswords = !_showPasswords;
                    });
                  },
                ),
          errorText: errorText,
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
