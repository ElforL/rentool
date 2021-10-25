import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:rentool/models/deliver_meetings.dart';
import 'package:rentool/services/auth.dart';

class MeetingErrorScreen extends StatelessWidget {
  MeetingErrorScreen({Key? key, required this.meeting})
      : assert(meeting.errors != null),
        super(key: key);

  final DeliverMeeting meeting;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    meeting.errors!.sort((a, b) {
      if (a is! Map || b is! Map) return 0;
      Timestamp timeA = a['time'];
      Timestamp timeB = b['time'];

      timeA.compareTo(timeB);

      return 1;
    });
    for (var error in meeting.errors!) {
      if (error is Map) {
        final time = error['time'];
        final uid = error['side_uid'];

        if (time is! Timestamp || uid is! String) continue;

        String text;
        if (meeting.isUserTheOwner) {
          if (uid == AuthServices.currentUid) {
            text = AppLocalizations.of(context)!.owner_pay_fail_as_owner;
          } else {
            text = AppLocalizations.of(context)!.renter_pay_fail_as_owner;
          }
        } else {
          if (uid == AuthServices.currentUid) {
            text = AppLocalizations.of(context)!.renter_pay_fail_as_renter;
          } else {
            text = AppLocalizations.of(context)!.owner_pay_fail_as_renter;
          }
        }

        final child = ListTile(
          leading: const Icon(
            Icons.money_off,
            color: Colors.black,
            size: 50,
          ),
          title: Text(text),
          subtitle: Text(DateFormat('d/MM/yyyy - hh:mm a').format(time.toDate())),
        );
        children.add(child);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.error),
      ),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            ...children,
          ],
        ),
      ),
    );
  }
}
