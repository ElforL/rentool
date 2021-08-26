import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentool/models/deliver_meetings.dart';
import 'package:rentool/screens/meetings_screens/deliver_meeting_pics_screen.dart';
import 'package:rentool/screens/meetings_screens/meeting_arrived_container.dart';
import 'package:rentool/screens/meetings_screens/meeting_ids_screen.dart';
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
      arriveFunction(false);
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
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text("Something went wrong\n${snapshot.error}"),
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
    if (data['renter_arrived'] != true || data['owner_arrived'] != true) {
      return MeetingArrivedContainer(
        deliverMeeting: meeting,
      );
    } else if (data['renter_pics_ok'] != true || data['owner_pics_ok'] != true) {
      return DeliverMeetingPicsContainer(
        meeting: meeting!,
      );
    } else if (data['renter_ids_ok'] != true || data['owner_ids_ok'] != true) {
      return MeetingsIdsScreen(
        meeting: meeting!,
      );
    } else {
      if (data['rent_started']) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(
            child: Text('SUCCESS\n Rent has started'),
          ),
        );
      } else if (data['error'] != null) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Text(data['error'].toString()),
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

  void arriveFunction(value) {
    final userRole = isUserTheOwner ? 'owner' : 'renter';
    FirestoreServices.setDeliverMeetingField(tool, '${userRole}_arrived', value);
  }

  void picsFunction(Map<String, dynamic> data, bool isUserTheOwner) {
    final userRole = isUserTheOwner ? 'owner' : 'renter';
    final arePicsOk = data['${userRole}_pics_ok'];
    FirestoreServices.setDeliverMeetingField(tool, '${userRole}_pics_ok', !arePicsOk);
  }
}
