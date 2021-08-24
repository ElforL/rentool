import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BigIcon extends StatelessWidget {
  const BigIcon({Key? key, required this.icon, this.caption}) : super(key: key);

  final Widget icon;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        icon,
        if (caption != null)
          Text(
            caption!,
            style: Theme.of(context).textTheme.subtitle2,
          ),
      ],
    );
  }
}

class NoOneArrivedIcon extends StatelessWidget {
  const NoOneArrivedIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BigIcon(
      icon: const Icon(
        Icons.deck,
        size: 150,
      ),
      caption: AppLocalizations.of(context)!.noOneHereYet,
    );
  }
}

class UserArrivedIcon extends StatelessWidget {
  const UserArrivedIcon({Key? key, required this.isUserTheOwner}) : super(key: key);

  final bool isUserTheOwner;

  @override
  Widget build(BuildContext context) {
    return BigIcon(
      icon: Stack(
        alignment: Alignment.topRight,
        children: const [
          Icon(
            Icons.search,
            size: 150,
          ),
          Icon(
            Icons.emoji_people,
            size: 50,
          ),
        ],
      ),
      caption: isUserTheOwner
          ? AppLocalizations.of(context)!.waitingForRenter
          : AppLocalizations.of(context)!.waitingForOwner,
    );
  }
}

class OtherArrivedIcon extends StatelessWidget {
  const OtherArrivedIcon({Key? key, required this.isUserTheOwner}) : super(key: key);

  final bool isUserTheOwner;

  @override
  Widget build(BuildContext context) {
    return BigIcon(
      icon: const Icon(
        Icons.emoji_people,
        size: 150,
      ),
      caption:
          isUserTheOwner ? AppLocalizations.of(context)!.ownerArrived : AppLocalizations.of(context)!.renterArrived,
    );
  }
}
