import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/return_meeting.dart';
import 'package:rentool/widgets/big_icons.dart';
import 'package:rentool/widgets/meeting_appbar.dart';
import 'package:rentool/widgets/note_box.dart';

class MeetingCompensationPriceScreen extends StatefulWidget {
  const MeetingCompensationPriceScreen({
    Key? key,
    required this.meeting,
  }) : super(key: key);

  final ReturnMeeting meeting;

  @override
  State<MeetingCompensationPriceScreen> createState() => _MeetingCompensationPriceScreenState();
}

class _MeetingCompensationPriceScreenState extends State<MeetingCompensationPriceScreen> {
  final _priceController = TextEditingController();
  String? errorText;

  ReturnMeeting get meeting => widget.meeting;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

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
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.black12,
                    ),
                  ),
                ),
                if (errorText != null)
                  Text(
                    errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    child: Text(AppLocalizations.of(context)!.set.toUpperCase()),
                    onPressed: () {
                      errorText = null;
                      try {
                        final price = double.parse(_priceController.text);
                        if (price <= meeting.tool.insuranceAmount) {
                          meeting.setCompensationPrice(price);
                        } else {
                          setState(() {
                            errorText = AppLocalizations.of(context)!.comp_price_must_be_less_than_insurance;
                          });
                        }
                      } catch (e) {
                        _priceController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                /////// Renter ///////

                Text(
                  AppLocalizations.of(context)!.waitingForOwnerToSetPrice,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 20),
                Text(
                  meeting.compensationPrice == null
                      ? '- - -'
                      : AppLocalizations.of(context)!.priceDisplay(
                          AppLocalizations.of(context)!.sar,
                          meeting.compensationPrice!,
                        ),
                  style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 50),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
