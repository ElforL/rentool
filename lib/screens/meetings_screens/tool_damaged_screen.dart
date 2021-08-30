import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/return_meeting.dart';
import 'package:rentool/widgets/big_icons.dart';
import 'package:rentool/widgets/meeting_appbar.dart';

class MeetingToolDamagedScreen extends StatelessWidget {
  const MeetingToolDamagedScreen({
    Key? key,
    required this.meeting,
  }) : super(key: key);

  final ReturnMeeting meeting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MeetingAppBar(
        text: meeting.isUserTheOwner
            ? AppLocalizations.of(context)!.backToInspect
            : AppLocalizations.of(context)!.backToArrival,
        onPressed: () {
          meeting.isUserTheOwner ? meeting.setToolDamaged(null) : meeting.setArrived(false);
        },
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const BigIcon(icon: Icons.mood_bad),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  meeting.isUserTheOwner
                      ? AppLocalizations.of(context)!.informedRenterOfClaims
                      : AppLocalizations.of(context)!.ownerClaimsUDamaged,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height / 10),
              if (meeting.isUserTheOwner) ...[
                Text(AppLocalizations.of(context)!.changedYourMind),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    child: Text(AppLocalizations.of(context)!.toolIsNotDamaged.toUpperCase()),
                    onPressed: () => meeting.setToolDamaged(false),
                  ),
                ),
              ] else ...[
                Text(AppLocalizations.of(context)!.doYouAdmitThat),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    child: Text(AppLocalizations.of(context)!.yesIDamaged.toUpperCase()),
                    onPressed: () => meeting.setAdmitDamage(true),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                    child: Text(AppLocalizations.of(context)!.noIDidntDamage.toUpperCase()),
                    onPressed: () => meeting.setAdmitDamage(false),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
