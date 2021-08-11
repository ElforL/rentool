import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rentool/models/return_meeting.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class ReturnMeetScreen extends StatefulWidget {
  const ReturnMeetScreen({Key? key, required this.tool}) : super(key: key);

  final Tool tool;

  @override
  _ReturnMeetScreenState createState() => _ReturnMeetScreenState();
}

class _ReturnMeetScreenState extends State<ReturnMeetScreen> {
  late ReturnMeeting meeting;
  late bool isUserTheOwner;
  late String userRole;
  late String otherRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Return ${widget.tool.name}'),
      ),
      body: StreamBuilder(
        stream: FirestoreServices.getReturnMeetingStream(widget.tool),
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
          meeting = ReturnMeeting.fromJson(data);
          isUserTheOwner = meeting.isTheOwner(AuthServices.auth.currentUser!.uid);
          userRole = isUserTheOwner ? 'owner' : 'renter';
          otherRole = !isUserTheOwner ? 'owner' : 'renter';

          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (meeting.bothArrived)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('GO BACK'),
                      onPressed: () {
                        arriveFunction();
                      },
                    ),
                  const SizedBox(height: 50),
                  // TODO show dialogs to each agree button
                  rentunAppropiateWidget(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget rentunAppropiateWidget() {
    if (meeting.bothHandedOver) {
      return handoverSuccesContainer();
    } else if (!meeting.bothArrived) {
      return arriveContainer();
    } else {
      if (meeting.disagreementCaseSettled != null) {
        if (meeting.disagreementCaseSettled!) {
          if (meeting.disagreementCaseResult!) {
            // tool damaged
            if (meeting.compensationPrice == null || !(meeting.renterAcceptCompensationPrice ?? false)) {
              return compensationPriceContainer();
            } else {
              return handOverContainer();
            }
          } else {
            // tool undamaged
            return handOverContainer();
          }
        } else {
          return disagreementCaseCreatedContainer();
        }
      } else if (meeting.toolDamaged == null) {
        return checkToolContainer();
      } else {
        if (meeting.toolDamaged!) {
          if (meeting.renterAdmitDamage == null) {
            return admitDamageContainer();
          } else if (meeting.renterAdmitDamage!) {
            if (meeting.compensationPrice == null || !(meeting.renterAcceptCompensationPrice ?? false)) {
              return compensationPriceContainer();
            } else {
              return handOverContainer();
            }
          } else {
            if (meeting.disagreementCaseID == null) {
              return mediaUploadContainer();
            } else {
              return disagreementCaseCreatedContainer();
            }
          }
        } else {
          return handOverContainer();
        }
      }
    }
  }

  arriveFunction() {
    final isUserTheOwner = meeting.isTheOwner(AuthServices.auth.currentUser!.uid);
    final userRole = isUserTheOwner ? 'owner' : 'renter';
    return FirestoreServices.setReturnMeetingField(widget.tool, '${userRole}Arrived', false);
  }

  Widget handoverSuccesContainer() {
    return Column(
      children: const [
        Text('Handover successful'),
        Text('Rent concluded'),
      ],
    );
  }

  Widget arriveContainer() {
    final userArrived = isUserTheOwner ? meeting.ownerArrived : meeting.renterArrived;
    return Column(
      children: [
        const Text('did you arrive?'),
        ElevatedButton(
          child: Text(userArrived ? "DIDN'T ARRIVE YET" : 'ARRIVED'),
          onPressed: () {
            FirestoreServices.setReturnMeetingField(widget.tool, '${userRole}Arrived', !userArrived);
          },
        ),
      ],
    );
  }

  Widget compensationPriceContainer() {
    var _controller = TextEditingController();
    if (meeting.compensationPrice != null) _controller.text = meeting.compensationPrice.toString();
    return Column(
      children: [
        if (meeting.disagreementCaseResult ?? false)
          const Text('After reviewing the case it was decided that the tool was indeed damaged.'),
        const Text('Agree on a compensation price and confirm it'),
        Container(
          constraints: const BoxConstraints(maxWidth: 100),
          child: TextField(
            readOnly: !isUserTheOwner,
            controller: _controller,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]|\.'))],
          ),
        ),
        if (isUserTheOwner) ...[
          ElevatedButton(
            child: const Text('CONFIRM'),
            onPressed: () {
              FirestoreServices.setReturnMeetingField(widget.tool, 'compensationPrice', double.parse(_controller.text));
            },
          ),
          if (meeting.compensationPrice != null)
            if (meeting.renterAcceptCompensationPrice == null)
              Text('Awaiting renter to accept the price of SAR ${meeting.compensationPrice}')
            else
              Text(
                'The renter ${meeting.renterAcceptCompensationPrice! ? 'accepted' : 'rejected'} the price of SAR ${meeting.compensationPrice}',
              ),
        ],
        if (!isUserTheOwner) ...[
          if (meeting.compensationPrice != null) ...[
            ElevatedButton(
              child: const Text('ACCEPT PRICE'),
              onPressed: () {
                FirestoreServices.setReturnMeetingField(widget.tool, 'renterAcceptCompensationPrice', true);
              },
            ),
            ElevatedButton(
              child: const Text('REJECT PRICE'),
              onPressed: () {
                FirestoreServices.setReturnMeetingField(widget.tool, 'renterAcceptCompensationPrice', false);
              },
            ),
          ] else
            const Text('Waiting the owner to set the compensation price'),
        ]
      ],
    );
  }

  Widget handOverContainer() {
    var userConfirmValue = isUserTheOwner ? meeting.ownerConfirmHandover : meeting.renterConfirmHandover;
    return Column(
      children: [
        if (meeting.disagreementCaseSettled ?? false)
          Text(
              'After reviewing the case it was decided that the tool was ${meeting.disagreementCaseResult! ? 'indeed' : 'not'} damaged.'),
        Text(isUserTheOwner ? 'Recive your tool' : 'Hand the tool over to the owner'),
        ElevatedButton(
          child: Text(userConfirmValue ? 'HAND-OVER YET TO HAPPEN' : 'CONFIRM HAND-OVER'),
          onPressed: () {
            FirestoreServices.setReturnMeetingField(widget.tool, '${userRole}ConfirmHandover', !userConfirmValue);
          },
        ),
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

  Widget checkToolContainer() {
    if (isUserTheOwner) {
      return Column(
        children: [
          const Text('Check the tool'),
          ElevatedButton(
            child: const Text('Not Damaged'),
            onPressed: () {
              FirestoreServices.setReturnMeetingField(widget.tool, 'toolDamaged', false);
            },
          ),
          ElevatedButton(
            child: const Text('Damaged'),
            onPressed: () {
              FirestoreServices.setReturnMeetingField(widget.tool, 'toolDamaged', true);
            },
          ),
        ],
      );
    } else {
      return Column(
        children: const [
          Text('The owner is checking the tool.'),
          Text('Please wait.'),
          //
        ],
      );
    }
  }

  Widget admitDamageContainer() {
    if (isUserTheOwner) {
      return Column(
        children: const [
          Text('awaiting renter to admit or deny damages'),
        ],
      );
    } else {
      return Column(
        children: [
          const Text('The owner claims the tool is damaged'),
          const Text("Do you admit you could've damaged the tool?"),
          ElevatedButton(
            child: const Text('I DIDN\'T DAMAGE IT'),
            onPressed: () {
              FirestoreServices.setReturnMeetingField(widget.tool, 'renterAdmitDamage', false);
            },
          ),
          ElevatedButton(
            child: const Text('I DID DAMAGE IT'),
            onPressed: () {
              FirestoreServices.setReturnMeetingField(widget.tool, 'renterAdmitDamage', true);
            },
          ),
        ],
      );
    }
  }

  Widget mediaUploadContainer() {
    var userValue = isUserTheOwner ? meeting.ownerMediaOK : meeting.renterMediaOK;
    return Column(
      children: [
        const Text('Upload media'),
        ElevatedButton(
          child: Text(userValue ? 'NOT DONE' : 'DONE'),
          onPressed: () {
            FirestoreServices.setReturnMeetingField(widget.tool, '${userRole}MediaOK', !userValue);
          },
        ),
      ],
    );
  }
}