import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:rentool/models/deliver_meetings.dart';
import 'package:rentool/widgets/dialogs.dart';
import 'package:rentool/widgets/meeting_appbar.dart';

class MeetingsIdsScreen extends StatelessWidget {
  const MeetingsIdsScreen({
    Key? key,
    required this.meeting,
  }) : super(key: key);

  final DeliverMeeting meeting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MeetingAppBar(
        text: AppLocalizations.of(context)!.backToMedia,
        onPressed: () => meeting.setMediaOK(false),
        actions: [
          IconButton(
            onPressed: () => showHelpDialog(context),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.role_id_number_is(meeting.otherUserRole).toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
              FittedBox(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Icon(
                            Icons.badge,
                            size: 50,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          meeting.otherUserID ?? AppLocalizations.of(context)!.loading,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline4!.apply(
                                color: Colors.black,
                                fontFamily: 'Roboto',
                                fontSizeDelta: 5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(AppLocalizations.of(context)!.meeting_id_checklist),
              ),
              const SizedBox(height: 50),
              if (meeting.otherUserID != null)
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: meeting.userIdsOk ? MaterialStateProperty.all(Colors.orange.shade900) : null,
                    ),
                    onPressed: () async {
                      var isSure = meeting.userIdsOk ? true : await showConfirmDialog(context);
                      if (isSure ?? false) meeting.setIdOK(!meeting.userIdsOk);
                    },
                    child: Text(
                      (meeting.userIdsOk
                              ? AppLocalizations.of(context)!.doesnt_match
                              : AppLocalizations.of(context)!.a_match)
                          .toUpperCase(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> showHelpDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return IconAlertDialog(
          icon: Icons.badge,
          titleText: AppLocalizations.of(context)!.deliverMeet_ids_help_dialog_title(meeting.otherUserRole),
          bodyText: AppLocalizations.of(context)!.deliverMeet_ids_help_dialog_body,
          importantText: AppLocalizations.of(context)!.deliverMeet_ids_help_dialog_important(meeting.otherUserRole),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok.toUpperCase()),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> showConfirmDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return IconAlertDialog(
          icon: Icons.badge,
          titleText: AppLocalizations.of(context)!.areYouSure,
          bodyText: AppLocalizations.of(context)!.deliverMeet_ids_confirm_dialog_body(
              meeting.otherUserID ?? '- ${AppLocalizations.of(context)!.id_unknow_error} -'),
          noteText: AppLocalizations.of(context)!.deliverMeet_ids_confirm_dialog_note,
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.sure.toUpperCase()),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      },
    );
  }
}
