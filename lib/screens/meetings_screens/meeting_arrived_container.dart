import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/deliver_meetings.dart';
import 'package:rentool/models/return_meeting.dart';
import 'package:rentool/widgets/big_icons.dart';

class MeetingArrivedContainer extends StatelessWidget {
  const MeetingArrivedContainer({
    Key? key,
    this.deliverMeeting,
    this.returnMeeting,
  })  : assert(deliverMeeting != null || returnMeeting != null),
        super(key: key);

  final DeliverMeeting? deliverMeeting;
  final ReturnMeeting? returnMeeting;

  bool get noOneArrived => !didUserArrive && !didOtherUserArrive;

  get didUserArrive {
    if (deliverMeeting != null) return deliverMeeting!.userArrived;
    return returnMeeting!.userArrived;
  }

  get didOtherUserArrive {
    if (deliverMeeting != null) return deliverMeeting!.otherUserArrived;
    return returnMeeting!.otherUserArrived;
  }

  get isUserTheOwner {
    if (deliverMeeting != null) return deliverMeeting!.isUserTheOwner;
    return returnMeeting!.isUserTheOwner;
  }

  Future<void> toggleArrived() {
    if (deliverMeeting != null) return deliverMeeting!.setArrived(!deliverMeeting!.userArrived);
    return returnMeeting!.setArrived(!returnMeeting!.userArrived);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (noOneArrived)
                const NoOneArrivedIcon()
              else if (didUserArrive)
                UserArrivedIcon(
                  isUserTheOwner: isUserTheOwner,
                )
              else if (didOtherUserArrive)
                OtherArrivedIcon(
                  isUserTheOwner: isUserTheOwner,
                ),
              const SizedBox(height: 30),
              Text(AppLocalizations.of(context)!.didYouArrive),
              ElevatedButton(
                child: Text(
                  didUserArrive
                      ? AppLocalizations.of(context)!.didntArrived.toUpperCase()
                      : AppLocalizations.of(context)!.arrived.toUpperCase(),
                ),
                style: ButtonStyle(
                  backgroundColor: didUserArrive ? MaterialStateProperty.all(Colors.orange.shade900) : null,
                ),
                onPressed: () {
                  toggleArrived();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
