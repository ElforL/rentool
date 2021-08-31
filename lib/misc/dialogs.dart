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
