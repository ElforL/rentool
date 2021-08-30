import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/return_meeting.dart';
import 'package:rentool/widgets/big_icons.dart';
import 'package:rentool/widgets/meeting_appbar.dart';
import 'package:rentool/widgets/note_box.dart';

class MeetingCompensationPriceScreen extends StatelessWidget {
  MeetingCompensationPriceScreen({
    Key? key,
    required this.meeting,
  }) : super(key: key);

  final ReturnMeeting meeting;
  final _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String appBarText;
    void Function() appBarFunc;
    if (meeting.disagreementCaseResult ?? false) {
      appBarText = AppLocalizations.of(context)!.backToArrival;
      appBarFunc = () => meeting.setArrived(false);
    } else if (meeting.renterAdmitDamage ?? false) {
      if (meeting.isUserTheOwner) {
        appBarText = AppLocalizations.of(context)!.backToInspect;
        appBarFunc = () => meeting.setToolDamaged(null);
      } else {
        appBarText = AppLocalizations.of(context)!.backToClaim;
        appBarFunc = () => meeting.setAdmitDamage(null);
      }
    } else {
      // this case should be impossible.
      appBarText = AppLocalizations.of(context)!.backToArrival;
      appBarFunc = () => meeting.setArrived(false);
    }
    return Scaffold(
      appBar: MeetingAppBar(
        text: appBarText,
        onPressed: appBarFunc,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const BigIcon(
                icon: Icons.price_change_outlined,
              ),
              Text(
                AppLocalizations.of(context)!.compensationPrice,
                style: Theme.of(context).textTheme.headline6!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
              ),
              if (meeting.disagreementCaseResult != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: NoteBox(
                    icon: Icons.gavel_rounded,
                    text: AppLocalizations.of(context)!.afterReviewingCaseToolWas(meeting.disagreementCaseResult!),
                  ),
                )
              else
                const SizedBox(height: 100),
              if (meeting.isUserTheOwner) ...[
                /////// Owner ///////

                Text(
                  AppLocalizations.of(context)!.setACompPrice,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: const EdgeInsets.all(10),
                  width: 150,
                  child: TextField(
                    controller: _priceController..text = meeting.compensationPrice?.toString() ?? _priceController.text,
                    textAlign: TextAlign.center,
                    // only digits
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}'))],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black12,
                      errorText: meeting.renterAcceptCompensationPrice ?? true
                          ? null
                          : AppLocalizations.of(context)!.renterRejected,
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    child: Text(AppLocalizations.of(context)!.set.toUpperCase()),
                    onPressed: () {
                      try {
                        final price = double.parse(_priceController.text);
                        meeting.setCompensationPrice(price);
                      } catch (e) {
                        _priceController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),

                if (meeting.compensationPrice != null && meeting.renterAcceptCompensationPrice == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      AppLocalizations.of(context)!.youSetPriceAt(
                        AppLocalizations.of(context)!.sar,
                        meeting.compensationPrice!,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (!(meeting.renterAcceptCompensationPrice ?? true)) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      AppLocalizations.of(context)!.renterRefuesdPrice(
                        AppLocalizations.of(context)!.sar,
                        meeting.compensationPrice!,
                      ),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(AppLocalizations.of(context)!.setAnotherPrice),
                ]
              ] else ...[
                /////// Renter ///////

                Text(
                  meeting.compensationPrice == null
                      ? AppLocalizations.of(context)!.waitingForOwnerToSetPrice
                      : !(meeting.renterAcceptCompensationPrice ?? true)
                          ? AppLocalizations.of(context)!.waitingForOwnerToSetNewPrice
                          : AppLocalizations.of(context)!.theOwnerSetPriceAt,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 20),
                Text(
                  meeting.compensationPrice == null || !(meeting.renterAcceptCompensationPrice ?? true)
                      ? '- - -'
                      : AppLocalizations.of(context)!.priceDisplay(
                          AppLocalizations.of(context)!.sar,
                          meeting.compensationPrice!,
                        ),
                  style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 50),
                if (meeting.compensationPrice != null && meeting.renterAcceptCompensationPrice == null) ...[
                  Text(AppLocalizations.of(context)!.doYouAgreeOnPrice),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.thumb_up),
                      label: Text(AppLocalizations.of(context)!.agree),
                      onPressed: () => meeting.setAcceptCompensationPrice(true),
                      style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.green)),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.thumb_down),
                      label: Text(AppLocalizations.of(context)!.disagree),
                      onPressed: () => meeting.setAcceptCompensationPrice(false),
                      style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                    ),
                  ),
                ] else if (!(meeting.renterAcceptCompensationPrice ?? true))
                  Text(AppLocalizations.of(context)!.youRejectedPriceOf(
                    AppLocalizations.of(context)!.sar,
                    meeting.compensationPrice!,
                  )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
