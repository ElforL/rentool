import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/meetings_containers/meeting_arrived_container.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class MeetScreen extends StatefulWidget {
  MeetScreen({Key? key, required this.tool})
      : isUserTheOwner = tool.ownerUID == AuthServices.auth.currentUser!.uid,
        super(key: key);

  final Tool tool;
  final bool isUserTheOwner;

  @override
  _MeetScreenState createState() => _MeetScreenState();
}

class _MeetScreenState extends State<MeetScreen> {
  _MeetScreenState();

  bool get isUserTheOwner => widget.isUserTheOwner;

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
    return Scaffold(
      appBar: AppBar(title: Text('Meeting for ${widget.tool.name}')),
      body: StreamBuilder(
        stream: FirestoreServices.getDeliverMeetingStream(widget.tool),
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
          bothArrived = data['renter_arrived'] == true && data['owner_arrived'] == true;
          bothPicsOK = data['renter_pics_ok'] == true && data['owner_pics_ok'] == true;
          bothIdsOK = data['renter_ids_ok'] == true && data['owner_ids_ok'] == true;
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (bothArrived!)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('GO BACK'),
                      onPressed: () {
                        arriveFunction(false);
                      },
                    ),
                  const SizedBox(height: 50),
                  // TODO show dialogs to each agree button
                  rentunAppropiateWidget(data, isUserTheOwner),
                ],
              ),
            ),
          );
        },
      ),
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
      return MeetingPicsContainer(
        data: data,
        isUserTheOwner: isUserTheOwner,
        onPressed: () => picsFunction(data, isUserTheOwner),
        onTakePics: () {
          // TODO upload and add url to db
          // ImagePicker().getImage(source: ImageSource.camera);
          var url =
              'https://www.hebergementwebs.com/image/04/044b635292b90188f40c240b51ae64bc.png/how-to-fix-http-error-code-501.png';
          FirestoreServices.setDeliverMeetingField(widget.tool, '${userRole}_pics_urls', FieldValue.arrayUnion([url]));
        },
      );
    } else if (data['renter_ids_ok'] != true || data['owner_ids_ok'] != true) {
      final currentValue = data['${userRole}_ids_ok'];
      return MeetingIdsContainer(
        data: data,
        isUserTheOwner: isUserTheOwner,
        onPressed: () => FirestoreServices.setDeliverMeetingField(widget.tool, '${userRole}_ids_ok', !currentValue),
      );
    } else {
      if (data['rent_started']) {
        return const Center(
          child: Text('SUCCESS\n Rent has started'),
        );
      } else if (data['error'] != null) {
        return Center(
          child: Text(data['error'].toString()),
        );
      } else {
        // TODO
        return const Center(
          child: Text('Loading... / unemplemented'),
        );
      }
    }
  }

  void arriveFunction(value) {
    final userRole = isUserTheOwner ? 'owner' : 'renter';
    FirestoreServices.setDeliverMeetingField(widget.tool, '${userRole}_arrived', value);
  }

  void picsFunction(Map<String, dynamic> data, bool isUserTheOwner) {
    final userRole = isUserTheOwner ? 'owner' : 'renter';
    final arePicsOk = data['${userRole}_pics_ok'];
    FirestoreServices.setDeliverMeetingField(widget.tool, '${userRole}_pics_ok', !arePicsOk);
  }
}

class MeetingPicsContainer extends StatelessWidget {
  MeetingPicsContainer({
    Key? key,
    required this.data,
    required this.isUserTheOwner,
    required this.onPressed,
    required this.onTakePics,
  })  : iAgree = data['${isUserTheOwner ? 'owner' : 'renter'}_pics_ok'],
        super(key: key);

  final void Function() onPressed;
  final void Function() onTakePics;
  final Map<String, dynamic> data;
  final bool isUserTheOwner;

  final bool iAgree;

  @override
  Widget build(BuildContext context) {
    List<String> myPics = List<String>.from(data['${isUserTheOwner ? 'owner' : 'renter'}_pics_urls']);
    List<String> othersPics = List<String>.from(data['${!isUserTheOwner ? 'owner' : 'renter'}_pics_urls']);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your photos', style: Theme.of(context).textTheme.subtitle2),
              OutlinedButton.icon(
                label: const Text('Take pictures'),
                icon: const Icon(Icons.camera_alt),
                onPressed: onTakePics,
              )
            ],
          ),
          SizedBox(
            height: 150,
            child: (myPics.isEmpty)
                ? const SizedBox(
                    height: 150,
                    child: Center(
                      child: Text('No Photos'),
                    ),
                  )
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var pic in myPics)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Image.network(pic),
                        ),
                    ],
                  ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'The ${isUserTheOwner ? "renter's" : "owner's"}',
                style: Theme.of(context).textTheme.subtitle2,
              ),
              Text(
                data['${!isUserTheOwner ? 'owner' : 'renter'}_pics_ok'] ? 'Agree' : "Doesn't agree",
                style: TextStyle(
                  color: data['${!isUserTheOwner ? 'owner' : 'renter'}_pics_ok'] ? Colors.green : Colors.red,
                ),
              )
            ],
          ),
          SizedBox(
            height: 150,
            child: (othersPics.isEmpty)
                ? const SizedBox(
                    child: Center(
                      child: Text('No Photos'),
                    ),
                  )
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var pic in othersPics)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Image.network(pic),
                        ),
                    ],
                  ),
          ),
          const Divider(),
          ElevatedButton(
            onPressed: onPressed,
            child: Text(iAgree ? 'DISAGREE' : 'AGREE'),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(iAgree ? Colors.red : Colors.green),
            ),
          )
        ],
      ),
    );
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
