import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/services/auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  static const routeName = '/forgotPassword';

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool argsRead = false;
  bool emailSent = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!argsRead) {
      argsRead = true;
      var args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) _controller.text = args;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.forgot_your_password),
      ),
      body: Center(
        child: emailSent
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.we_sent_password_reset_email),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.back),
                  )
                ],
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.enter_your_email_address),
                  ),
                  ListTile(
                    title: TextField(
                      autofocus: true,
                      controller: _controller,
                      decoration: InputDecoration(
                        label: Text(AppLocalizations.of(context)!.emailAddress),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text(
                      AppLocalizations.of(context)!.we_will_send_password_reset_email,
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                          ),
                    ),
                  ),
                  ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 100),
                          child: OutlinedButton(
                            child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 100),
                          child: ElevatedButton(
                            child: Text(AppLocalizations.of(context)!.send.toUpperCase()),
                            onPressed: () async {
                              try {
                                await AuthServices.auth.sendPasswordResetEmail(email: _controller.text.trim());
                              } on FirebaseAuthException catch (e) {
                                _showFirebaseAuthExceptionDialog(e);
                              } catch (e) {
                                _showErrorDialog(e);
                              }
                              setState(() => emailSent = true);
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Future<dynamic> _showFirebaseAuthExceptionDialog(FirebaseAuthException e) {
    late String body;
    if (e.code == 'invalid-email') {
      body = AppLocalizations.of(context)!.badEmail;
    } else if (e.code == 'user-not-found') {
      body = AppLocalizations.of(context)!.userNotFoundError;
    } else {
      return _showErrorDialog(e);
    }
    final dialog = AlertDialog(
      title: Text(AppLocalizations.of(context)!.error),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.ok.toUpperCase()),
        ),
      ],
    );
    return showDialog(context: context, builder: (context) => dialog);
  }

  Future<dynamic> _showErrorDialog(Object e) {
    final dialog = AlertDialog(
      title: Text(AppLocalizations.of(context)!.error),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.errorInfo + ':\n'),
          SelectableText(e.toString()),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.ok.toUpperCase()),
        ),
      ],
    );
    return showDialog(context: context, builder: (context) => dialog);
  }
}
