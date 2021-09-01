import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/deliver_meetings.dart';
import 'package:rentool/screens/meetings_screens/deliver_meeting_pics_screen.dart';
import 'package:rentool/screens/meetings_screens/meeting_arrived_container.dart';
import 'package:rentool/screens/meetings_screens/meeting_ids_screen.dart';
import 'package:rentool/screens/meetings_screens/meeting_success_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class DeliverMeetScreen extends StatefulWidget {
  const DeliverMeetScreen({Key? key}) : super(key: key);

  @override
  _DeliverMeetScreenState createState() => _DeliverMeetScreenState();
}

class _DeliverMeetScreenState extends State<DeliverMeetScreen> {
  late Tool tool;
  late bool isUserTheOwner;

  DeliverMeeting? meeting;

  @override
  void dispose() {
    if (!(meeting?.bothIdsOk ?? false)) {
      meeting!.setArrived(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    tool = ModalRoute.of(context)!.settings.arguments as Tool;
    isUserTheOwner = tool.ownerUID == AuthServices.currentUid;

    return StreamBuilder(
      stream: FirestoreServices.getDeliverMeetingStream(tool),
      builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          // TODO
          // if (snapshot.error is FirebaseException && (snapshot.error as FirebaseException).code == 'permission-denied')
          //   return FirestorePermissionDeniedScreen();
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                "Something went wrong\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.active) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Getting ready...'),
            ),
          );
        }

        var data = snapshot.data!.data()!;
        meeting = DeliverMeeting.fromJson(tool, data);
        return rentunAppropiateWidget(data, isUserTheOwner);
      },
    );
  }

  Widget rentunAppropiateWidget(Map<String, dynamic> data, bool isUserTheOwner) {
    if (!meeting!.bothArrived) {
      return MeetingArrivedContainer(
        deliverMeeting: meeting,
      );
    } else if (!meeting!.bothMediaOk) {
      return DeliverMeetingPicsContainer(
        meeting: meeting!,
      );
    } else if (!meeting!.bothIdsOk) {
      return MeetingsIdsScreen(
        meeting: meeting!,
      );
    } else {
      if (meeting!.rentStarted) {
        return MeetingSuccessScreen(
          title: AppLocalizations.of(context)!.success,
          subtitle: AppLocalizations.of(context)!.rentHasStarted,
        );
      } else if (meeting!.error != null) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Text(meeting!.error.toString()),
          ),
        );
      } else {
        // TODO
        return Scaffold(
          appBar: AppBar(),
          body: const Center(
            child: Text('Loading... / unemplemented'),
          ),
        );
      }
    }
  }
}
