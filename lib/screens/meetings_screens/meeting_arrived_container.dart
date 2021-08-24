import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/widgets/big_icons.dart';

class MeetingArrivedContainer extends StatelessWidget {
  const MeetingArrivedContainer({
    Key? key,
    required this.didUserArrive,
    required this.didOtherUserArrive,
    required this.onPressed,
    required this.isUserTheOwner,
  }) : super(key: key);

  final bool isUserTheOwner;
  final bool didUserArrive;
  final bool didOtherUserArrive;
  final void Function() onPressed;

  bool get noOneArrived => !didUserArrive && !didOtherUserArrive;

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
                onPressed: onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
