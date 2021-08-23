import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentool/screens/meetings_screens/deliver_meeting_pics_screen.dart';
import 'package:rentool/screens/meetings_screens/meeting_arrived_container.dart';
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

  bool? bothArrived;
  bool? bothPicsOK;
  bool? bothIdsOK;

  @override
  void dispose() {
    if (!(bothIdsOK ?? false)) {
      arriveFunction(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    tool = ModalRoute.of(context)!.settings.arguments as Tool;
    isUserTheOwner = tool.ownerUID == AuthServices.auth.currentUser!.uid;

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
        bothArrived = data['renter_arrived'] == true && data['owner_arrived'] == true;
        bothPicsOK = data['renter_pics_ok'] == true && data['owner_pics_ok'] == true;
        bothIdsOK = data['renter_ids_ok'] == true && data['owner_ids_ok'] == true;
        return rentunAppropiateWidget(data, isUserTheOwner);
      },
    );
  }

  Widget rentunAppropiateWidget(Map<String, dynamic> data, bool isUserTheOwner) {
    final userRole = isUserTheOwner ? 'owner' : 'renter';
    final otherRole = !isUserTheOwner ? 'owner' : 'renter';
    if (data['renter_arrived'] != true || data['owner_arrived'] != true) {
      return MeetingArrivedContainer(
        isUserTheOwner: isUserTheOwner,
        didUserArrive: data['${userRole}_arrived'] ?? false,
        didOtherUserArrive: data['${otherRole}_arrived'] ?? false,
        onPressed: () => arriveFunction(!data['${userRole}_arrived']),
      );
    } else if (data['renter_pics_ok'] != true || data['owner_pics_ok'] != true) {
      // showDialog(
      //   context: context,
      //   builder: (context) => IconAlertDialog(
      //     icon: Icons.camera_alt,
      //     titleText: 'Are you sure',
      //     bodyText: 'Do you agree with the owner’s pictures and videos?',
      //     importantText:
      //         'These pictures and videos will be evidence of the tool’s status before renting so make sure you check the owner’s pictures and videos and agree on them.',
      //     noteText:
      //         'Note: if the owner changed his pictures and videos after you agree your status will change to not agree automatically.',
      //     actions: [
      //       TextButton(
      //         child: const Text('OK'),
      //         onPressed: () => Navigator.pop(context),
      //       ),
      //     ],
      //   ),
      // );
      return DeliverMeetingPicsContainer(
        didUserAgree: data['${userRole}_pics_ok'],
        didOtherUserAgree: data['${otherRole}_pics_ok'],
        isUserTheOwner: isUserTheOwner,
        onPressed: () => picsFunction(data, isUserTheOwner),
      );
    } else if (data['renter_ids_ok'] != true || data['owner_ids_ok'] != true) {
      final currentValue = data['${userRole}_ids_ok'];
      return Scaffold(
        appBar: AppBar(),
        body: MeetingIdsContainer(
          data: data,
          isUserTheOwner: isUserTheOwner,
          onPressed: () => FirestoreServices.setDeliverMeetingField(tool, '${userRole}_ids_ok', !currentValue),
        ),
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

class MeetingIdsContainer extends StatelessWidget {
  const MeetingIdsContainer({Key? key, required this.data, required this.isUserTheOwner, required this.onPressed})
      : super(key: key);

  final void Function() onPressed;
  final Map<String, dynamic> data;
  final bool isUserTheOwner;

  @override
  Widget build(BuildContext context) {
    final userRole = isUserTheOwner ? 'owner' : 'renter';
    final otherRole = !isUserTheOwner ? 'owner' : 'renter';
    final bool iAgree = data['${userRole}_ids_ok'];

    final String otherIDnumber =
        data['${otherRole}_id'] ?? "**UNKNOW ID**\nThis is not meant to happen. please cancel and contact support.";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("The $otherRole's ID number is:"),
        Text(
          otherIDnumber,
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        Text(
          "Ask the $otherRole to give you his ID and make sure\n1- it matches him/her.\n2-its number matches the number above.\n3- it's not expired or about to.",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        const Text('Does it match'),
        ElevatedButton(
          child: Text(iAgree ? "NOT A MATCH" : 'A MATCH'),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(iAgree ? Colors.redAccent : Colors.green),
          ),
          onPressed: onPressed,
        ),
      ],
    );
  }
}
