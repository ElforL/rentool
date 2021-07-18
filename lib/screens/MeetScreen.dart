import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class MeetScreen extends StatefulWidget {
  const MeetScreen({Key key, this.tool}) : super(key: key);

  final Tool tool;

  @override
  _MeetScreenState createState() => _MeetScreenState(tool.ownerUID == AuthServices.auth.currentUser.uid);
}

class _MeetScreenState extends State<MeetScreen> {
  _MeetScreenState(this.isUserTheOwner);

  final bool isUserTheOwner;

  bool bothArrived;
  bool bothPicsOK;
  bool bothIdsOK;

  @override
  void dispose() {
    if (!bothIdsOK) {
      arriveFunction(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Meeting for ${widget.tool.name}')),
      body: StreamBuilder(
        stream: FirestoreServices.getMeetingStream(widget.tool),
        builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Something went wrong\n${snapshot.error}"),
            );
          }
          if (snapshot.connectionState != ConnectionState.active)
            return Center(
              child: Text('Getting ready...'),
            );

          var data = snapshot.data.data();
          bothArrived = data['renter_arrived'] == true && data['owner_arrived'] == true;
          bothPicsOK = data['renter_pics_ok'] == true && data['owner_pics_ok'] == true;
          bothIdsOK = data['renter_ids_ok'] == true && data['owner_ids_ok'] == true;
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (bothArrived)
                    ElevatedButton.icon(
                      icon: Icon(Icons.arrow_back),
                      label: Text('GO BACK'),
                      onPressed: () {
                        arriveFunction(false);
                      },
                    ),
                  SizedBox(height: 50),
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
    if (data['renter_arrived'] != true || data['owner_arrived'] != true) {
      return MeetingArrivedContainer(
        didUserArrive: data['${userRole}_arrived'] ?? false,
        didOtherUserArrive: data['${userRole}_arrived'] ?? false,
        onPressed: () => arriveFunction(!data['${userRole}_arrived']),
      );
    } else if (data['renter_pics_ok'] != true || data['owner_pics_ok'] != true) {
      return MeetingPicsContainer(
        data: data,
        isUserTheOwner: isUserTheOwner,
        onPressed: () => picsFunction(data, isUserTheOwner),
        onTakePics: () {
          // TODO upload and add url to db
          // ImagePicker().getImage(source: ImageSource.camera);
          var url =
              'https://www.hebergementwebs.com/image/04/044b635292b90188f40c240b51ae64bc.png/how-to-fix-http-error-code-501.png';
          FirestoreServices.setMeetingField(widget.tool, '${userRole}_pics_urls', FieldValue.arrayUnion([url]));
        },
      );
    } else if (data['renter_ids_ok'] != true || data['owner_ids_ok'] != true) {
      final currentValue = data['${userRole}_ids_ok'];
      return MeetingIdsContainer(
        data: data,
        isUserTheOwner: isUserTheOwner,
        onPressed: () => FirestoreServices.setMeetingField(widget.tool, '${userRole}_ids_ok', !currentValue),
      );
    } else {
      if (data['rent_started']) {
        return Center(
          child: Text('SUCCESS\n Rent has started'),
        );
      } else if (data['error'] != null) {
        return Center(
          child: Text(data['error'].toString()),
        );
      } else {
        // TODO
        return Center(
          child: Text('Loading... / unemplemented'),
        );
      }
    }
  }

  void arriveFunction(value) {
    final userRole = isUserTheOwner ? 'owner' : 'renter';
    FirestoreServices.setMeetingField(widget.tool, '${userRole}_arrived', value);
  }

  void picsFunction(Map<String, dynamic> data, bool isUserTheOwner) {
    final userRole = isUserTheOwner ? 'owner' : 'renter';
    final arePicsOk = data['${userRole}_pics_ok'];
    FirestoreServices.setMeetingField(widget.tool, '${userRole}_pics_ok', !arePicsOk);
  }
}

class MeetingArrivedContainer extends StatelessWidget {
  const MeetingArrivedContainer({
    Key key,
    @required this.didUserArrive,
    @required this.didOtherUserArrive,
    @required this.onPressed,
  }) : super(key: key);

  final bool didUserArrive;
  final bool didOtherUserArrive;
  final void Function() onPressed;

  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('You: ${didUserArrive ? 'Arrived / Ready' : "Didn't arrive yet"}'),
        Text('The Renter: ${didOtherUserArrive ? 'Arrived / Ready' : "Didn't arrive yet"}'),
        SizedBox(height: 30),
        Text('Did you arrive?'),
        ElevatedButton(
          child: Text(didUserArrive ? "I'M NOT THERE" : 'I ARRIVED'),
          style: ButtonStyle(
            backgroundColor: didUserArrive ? MaterialStateProperty.all(Colors.redAccent) : null,
          ),
          onPressed: onPressed,
        ),
      ],
    );
  }
}

class MeetingPicsContainer extends StatelessWidget {
  MeetingPicsContainer({
    Key key,
    @required this.data,
    @required this.isUserTheOwner,
    @required this.onPressed,
    @required this.onTakePics,
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
                label: Text('Take pictures'),
                icon: Icon(Icons.camera_alt),
                onPressed: onTakePics,
              )
            ],
          ),
          SizedBox(
            height: 150,
            child: (myPics == null || myPics.isEmpty)
                ? SizedBox(
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
          Divider(),
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
            child: (othersPics == null || othersPics.isEmpty)
                ? SizedBox(
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
          Divider(),
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
  MeetingIdsContainer({Key key, @required this.data, @required this.isUserTheOwner, @required this.onPressed})
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
        SizedBox(height: 30),
        Text('Does it match'),
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
