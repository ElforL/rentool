import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/misc/custom_icons.dart';
import 'package:rentool/models/return_meeting.dart';
import 'package:rentool/widgets/big_icons.dart';
import 'package:rentool/widgets/meeting_appbar.dart';
import 'package:rentool/widgets/note_box.dart';

class MeetingHandoverScreen extends StatelessWidget {
  const MeetingHandoverScreen({Key? key, required this.meeting}) : super(key: key);

  final ReturnMeeting meeting;

  MeetingAppBar _buildAppBar(BuildContext context) {
    void Function() onPressed;
    String text = 'unimplemented';

    if (meeting.isUserTheOwner && meeting.disagreementCaseID == null) {
      // if it's the owner and there's no disagreement case go back to inspect -> set `toolDamaged` to `null`
      onPressed = () => meeting.setToolDamaged(null);
      text = AppLocalizations.of(context)!.backToInspect;
    } else if (!meeting.isUserTheOwner && (meeting.renterAcceptCompensationPrice ?? false)) {
      // if it's the renter and `renterAcceptCompensationPrice` is true set `renterAcceptCompensationPrice` to `false`
      onPressed = () => meeting.setAcceptCompensationPrice(null);
      text = AppLocalizations.of(context)!.backToCompPrice;
    } else {
      onPressed = () => meeting.setArrived(false);
      text = AppLocalizations.of(context)!.backToArrival;
    }

    return MeetingAppBar(
      text: text,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (meeting.disagreementCaseResult != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: NoteBox(
                    icon: Icons.gavel_rounded,
                    text: AppLocalizations.of(context)!.afterReviewingCaseToolWas(meeting.disagreementCaseResult!),
                  ),
                ),
              const BigIcon(
                // TODO center the icon. it looks BAD
                icon: CustomIcons.handshake,
              ),
              if (meeting.compensationPrice != null && (meeting.renterAcceptCompensationPrice ?? false))
                Text(
                  '${AppLocalizations.of(context)!.compensationPrice} = ${AppLocalizations.of(context)!.priceDisplay(AppLocalizations.of(context)!.sar, meeting.compensationPrice!.toString())}',
                  style: Theme.of(context).textTheme.caption,
                ),
              SizedBox(height: MediaQuery.of(context).size.height / 10),
              Text(
                meeting.isUserTheOwner
                    ? AppLocalizations.of(context)!.reciveTool
                    : AppLocalizations.of(context)!.handoverTheTool,
                style: Theme.of(context).textTheme.subtitle2,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 210,
                child: ElevatedButton(
                  child: FittedBox(
                    child: Text(
                      (!meeting.userConfirmedHandover
                              ? AppLocalizations.of(context)!.confirmHandOver
                              : AppLocalizations.of(context)!.didntHandOver)
                          .toUpperCase(),
                    ),
                  ),
                  style: ButtonStyle(
                    backgroundColor:
                        meeting.userConfirmedHandover ? MaterialStateProperty.all(Colors.orange.shade900) : null,
                  ),
                  onPressed: () => meeting.setConfirmHandover(!meeting.userConfirmedHandover),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
