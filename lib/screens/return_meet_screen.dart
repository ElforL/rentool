import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentool/models/return_meeting.dart';
import 'package:rentool/screens/meetings_screens/check_tool_screen.dart';
import 'package:rentool/screens/meetings_screens/compensation_price_screen.dart';
import 'package:rentool/screens/meetings_screens/handover_screen.dart';
import 'package:rentool/screens/meetings_screens/meeting_arrived_container.dart';
import 'package:rentool/screens/meetings_screens/tool_damaged_screen.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class ReturnMeetScreen extends StatefulWidget {
  const ReturnMeetScreen({Key? key}) : super(key: key);

  @override
  _ReturnMeetScreenState createState() => _ReturnMeetScreenState();
}

class _ReturnMeetScreenState extends State<ReturnMeetScreen> {
  late Tool tool;

  late ReturnMeeting meeting;
  late bool isUserTheOwner;
  late String userRole;
  late String otherRole;

  @override
  void dispose() {
    meeting.setArrived(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    tool = ModalRoute.of(context)!.settings.arguments as Tool;

    return StreamBuilder(
      stream: FirestoreServices.getReturnMeetingStream(tool),
      builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("Something went wrong\n${snapshot.error}"),
          );
        }
        if (snapshot.connectionState != ConnectionState.active) {
          return const Center(
            child: Text('Getting ready...'),
          );
        }

        var data = snapshot.data!.data()!;
        meeting = ReturnMeeting.fromJson(tool, data);
        isUserTheOwner = meeting.isUserTheOwner;
        userRole = isUserTheOwner ? 'owner' : 'renter';
        otherRole = !isUserTheOwner ? 'owner' : 'renter';

        return rentunAppropiateWidget();
      },
    );
  }

  Widget rentunAppropiateWidget() {
    if (meeting.bothHandedOver) {
      return handoverSuccesContainer();
    } else if (!meeting.bothArrived) {
      return MeetingArrivedContainer(
        returnMeeting: meeting,
      );
    } else {
      if (meeting.disagreementCaseSettled != null) {
        if (meeting.disagreementCaseSettled!) {
          if (meeting.disagreementCaseResult!) {
            // tool damaged
            if (meeting.compensationPrice == null || !(meeting.renterAcceptCompensationPrice ?? false)) {
              return MeetingCompensationPriceScreen(meeting: meeting);
            } else {
              return MeetingHandoverScreen(meeting: meeting);
            }
          } else {
            // tool undamaged
            return MeetingHandoverScreen(meeting: meeting);
          }
        } else {
          return disagreementCaseCreatedContainer();
        }
      } else if (meeting.toolDamaged == null) {
        return MeetingCheckToolScreen(
          meeting: meeting,
        );
      } else {
        if (meeting.toolDamaged!) {
          if (meeting.renterAdmitDamage == null) {
            return MeetingToolDamagedScreen(
              meeting: meeting,
            );
          } else if (meeting.renterAdmitDamage!) {
            if (meeting.compensationPrice == null || !(meeting.renterAcceptCompensationPrice ?? false)) {
              return MeetingCompensationPriceScreen(meeting: meeting);
            } else {
              return MeetingHandoverScreen(meeting: meeting);
            }
          } else {
            if (meeting.disagreementCaseID == null) {
              return mediaUploadContainer();
            } else {
              return disagreementCaseCreatedContainer();
            }
          }
        } else {
          return MeetingHandoverScreen(meeting: meeting);
        }
      }
    }
  }

  Widget handoverSuccesContainer() {
    return Column(
      children: const [
        Text('Handover successful'),
        Text('Rent concluded'),
      ],
    );
  }

  Widget disagreementCaseCreatedContainer() {
    return Column(
      children: [
        const Text(
          'a disagreement case was created. We will review the images/videos and arrive to a decission',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text('Disagreement case ID: ${meeting.disagreementCaseID}'),
      ],
    );
  }

  Widget mediaUploadContainer() {
    var userValue = isUserTheOwner ? meeting.ownerMediaOK : meeting.renterMediaOK;
    return Column(
      children: [
        const Text('Upload media'),
        ElevatedButton(
          child: Text(userValue ? 'NOT DONE' : 'DONE'),
          onPressed: () {
            FirestoreServices.setReturnMeetingField(tool, '${userRole}MediaOK', !userValue);
          },
        ),
      ],
    );
  }
}
