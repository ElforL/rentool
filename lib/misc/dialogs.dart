import 'package:flutter/material.dart';
import 'package:rentool/screens/account_settings_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/widgets/icon_alert_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<dynamic> showDisagreementCasesHelpDialog(BuildContext context, bool isUserTheOwner) {
  return showDialog(
    context: context,
    builder: (context) => IconAlertDialog(
      icon: Icons.gavel_rounded,
      titleText: AppLocalizations.of(context)!.disagreement_cases,
      bodyText: '''${AppLocalizations.of(context)!.disagreement_cases_creation}
          \n${isUserTheOwner ? AppLocalizations.of(context)!.cases_help_dialog_owner_body : AppLocalizations.of(context)!.cases_help_dialog_renter_body}
          \n${AppLocalizations.of(context)!.disagreement_cases_after_decision}''',
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.ok.toUpperCase()),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

/// Shows a dialog with the default title as "_Are you sure?_"
/// and two buttons: '_CANCEL_' and '_SURE_'
///
/// Returns:
/// - `true` if the user taps on '_SURE_'
/// - `false` if the user taps on '_CANCEL_'.
/// - `null` if it was popped without pressing one the buttons.
///
/// Usage:
/// ```dart
///   final isSure = await showConfirmDialog(context);
///   if(isSure ?? false) doSomething();
/// ```
Future<bool?> showConfirmDialog(BuildContext context, {Widget? content, Widget? title, List<Widget>? actions}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: title ?? Text(AppLocalizations.of(context)!.areYouSure),
      content: content,
      actions: actions ??
          [
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.sure.toUpperCase()),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
    ),
  );
}

Future<bool?> showErrorDialog(BuildContext context, {Widget? content, Widget? title, List<Widget>? actions}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: title ?? Text(AppLocalizations.of(context)!.error),
      content: content,
      actions: actions ??
          [
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok.toUpperCase()),
              onPressed: () => Navigator.pop(context),
            ),
          ],
    ),
  );
}

Future<dynamic> showIconAlertDialog(BuildContext context,
    {required IconData icon,
    required String titleText,
    String? bodyText,
    String? importantText,
    String? noteText,
    List<Widget>? actions,
    Key? key}) {
  return showDialog(
    context: context,
    builder: (context) => IconAlertDialog(
      icon: icon,
      titleText: titleText,
      bodyText: bodyText,
      importantText: importantText,
      noteText: noteText,
      actions: actions,
      key: key,
    ),
  );
}

Future<dynamic> showEmailNotVerifiedDialog(BuildContext context, {List<Widget>? actions}) {
  return showDialog(
    context: context,
    builder: (context) => IconAlertDialog(
      icon: Icons.mark_email_read_rounded,
      titleText: AppLocalizations.of(context)!.email_address_not_verified,
      bodyText: AppLocalizations.of(context)!.you_need_to_verify_email,
      actions: actions ??
          [
            if (AuthServices.currentUser != null)
              TextButton(
                child: Text(AppLocalizations.of(context)!.resend_email.toUpperCase()),
                onPressed: () {
                  AuthServices.currentUser!.sendEmailVerification();
                  Navigator.pop(context);
                },
              ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok.toUpperCase()),
              onPressed: () => Navigator.pop(context),
            ),
          ],
    ),
  );
}

Future<dynamic> showIdMissingDialog(BuildContext context, {List<Widget>? actions}) {
  return showDialog(
    context: context,
    builder: (context) => IconAlertDialog(
      icon: Icons.badge,
      titleText: AppLocalizations.of(context)!.no_id_number,
      bodyText: AppLocalizations.of(context)!.you_must_set_ID_number,
      actions: actions ??
          [
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.set_id.toUpperCase()),
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AccountSettingsScreen.routeName);
              },
            ),
          ],
    ),
  );
}
