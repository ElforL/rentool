import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/deliver_meetings.dart';
import 'package:rentool/screens/error_screen.dart';
import 'package:rentool/screens/meetings_screens/deliver_meeting_pics_screen.dart';
import 'package:rentool/screens/meetings_screens/meeting_arrived_container.dart';
import 'package:rentool/screens/meetings_screens/meeting_error_screen.dart';
import 'package:rentool/screens/meetings_screens/meeting_ids_screen.dart';
import 'package:rentool/screens/meetings_screens/meeting_success_screen.dart';
import 'package:rentool/screens/meetings_screens/processing_payments_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/widgets/loading_indicator.dart';

class DeliverMeetScreen extends StatefulWidget {
  const DeliverMeetScreen({Key? key}) : super(key: key);

  static const routeName = '/deliver';

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
          return ErrorScreen(error: snapshot.error);
        }
        if (snapshot.connectionState != ConnectionState.active) {
          return _buildLoadingScreen(context);
        }

        var data = snapshot.data!.data()!;
        meeting = DeliverMeeting.fromJson(tool, data, snapshot.data!.id);
        return rentunAppropiateWidget(data, isUserTheOwner);
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

  Widget rentunAppropiateWidget(Map<String, dynamic> data, bool isUserTheOwner) {
    if (kIsWeb) {
      return const ErrorScreen(error: "Meetings can only be done in the app");
    } else if (!meeting!.bothArrived) {
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
    } else if (meeting!.processingPayment && meeting!.paymentsSuccessful == null) {
      return const ProcessingPaymentScreen(showAppBar: false);
    } else if (meeting!.rentStarted || meeting!.paymentsSuccessful!) {
      return MeetingSuccessScreen(
        title: AppLocalizations.of(context)!.success,
        subtitle: meeting!.rentStarted ? AppLocalizations.of(context)!.rentHasStarted : '',
      );
    } else if (meeting!.errors != null && meeting!.errors!.isNotEmpty) {
      return MeetingErrorScreen(meeting: meeting!);
    } else {
      var json = meeting?.toJson()
        ?..remove('renter_id')
        ..remove('owner_id');
      return ErrorScreen(
        error: "Invalid state: the meeting's current state should be impossible.\ntoJson: $json",
      );
    }
  }
}
