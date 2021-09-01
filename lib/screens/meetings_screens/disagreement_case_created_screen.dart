import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/models/return_meeting.dart';
import 'package:rentool/widgets/big_icons.dart';

class MeetingDisagreementCaseCreatedScreen extends StatelessWidget {
  const MeetingDisagreementCaseCreatedScreen({
    Key? key,
    required this.meeting,
  }) : super(key: key);

  final ReturnMeeting meeting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_outlined),
            onPressed: () => showDisagreementCasesHelpDialog(context, meeting.isUserTheOwner),
            tooltip: AppLocalizations.of(context)!.what_are_disagreement_cases,
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const BigIcon(
                  icon: Icons.gavel_rounded,
                ),
                const SizedBox(height: 75),
                Text(
                  AppLocalizations.of(context)!.disagreementCaseCreated,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  child: Text(
                    AppLocalizations.of(context)!.what_are_disagreement_cases.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  onPressed: () => showDisagreementCasesHelpDialog(context, meeting.isUserTheOwner),
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 5),
                Text(
                  AppLocalizations.of(context)!.disagreementCaseID.toUpperCase(),
                  style: Theme.of(context).textTheme.overline!.copyWith(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                SelectableText(
                  meeting.disagreementCaseID ?? '- - -',
                  style: Theme.of(context).textTheme.overline!.copyWith(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.center,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: meeting.disagreementCaseID));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(AppLocalizations.of(context)!.disagreementCaseIDCopied),
                    ));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
