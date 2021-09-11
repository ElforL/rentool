import 'package:flutter/material.dart';
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

/// Shows a dialog with the title: "_Are you sure?_"
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
Future<bool?> showConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.areYouSure),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.sure),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    ),
  );
}
