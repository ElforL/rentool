import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/models/return_meeting.dart';
import 'package:rentool/screens/error_screen.dart';
import 'package:rentool/screens/meetings_screens/check_tool_screen.dart';
import 'package:rentool/screens/meetings_screens/compensation_price_screen.dart';
import 'package:rentool/screens/meetings_screens/disagreement_case_created_screen.dart';
import 'package:rentool/screens/meetings_screens/disagreement_media_screen.dart';
import 'package:rentool/screens/meetings_screens/handover_screen.dart';
import 'package:rentool/screens/meetings_screens/meeting_arrived_container.dart';
import 'package:rentool/screens/meetings_screens/meeting_success_screen.dart';
import 'package:rentool/screens/meetings_screens/tool_damaged_screen.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/loading_indicator.dart';

class ReturnMeetScreen extends StatefulWidget {
  const ReturnMeetScreen({Key? key}) : super(key: key);

  static const routeName = '/return';

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
          return ErrorScreen(error: snapshot.error);
        }
        if (snapshot.connectionState != ConnectionState.active) {
          return _buildLoadingScreen(context);
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

  Scaffold _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingIndicator(
              strokeWidth: 5,
              height: 70,
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.loading,
              style: Theme.of(context).textTheme.headline5,
            ),
          ],
        ),
      ),
    );
  }

  Widget rentunAppropiateWidget() {
    if (meeting.bothHandedOver) {
      return MeetingSuccessScreen(
        title: AppLocalizations.of(context)!.success,
        subtitle: AppLocalizations.of(context)!.rentHasConcluded,
      );
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
          return MeetingDisagreementCaseCreatedScreen(meeting: meeting);
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
              return DisagreementMediaScreen(
                meeting: meeting,
              );
            } else {
              return MeetingDisagreementCaseCreatedScreen(meeting: meeting);
            }
          }
        } else {
          return MeetingHandoverScreen(meeting: meeting);
        }
      }
    }
  }
}
