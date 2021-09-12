import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BigIcon extends StatelessWidget {
  const BigIcon({Key? key, this.icon, this.caption, this.child, this.color})
      : assert(icon != null || child != null),
        super(key: key);

  final IconData? icon;
  final Color? color;
  final Widget? child;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null)
          Icon(
            icon!,
            size: 150,
            color: color,
          ),
        if (child != null) child!,
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
      icon: Icons.deck,
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
      child: Stack(
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
      icon: Icons.emoji_people,
      caption:
          isUserTheOwner ? AppLocalizations.of(context)!.ownerArrived : AppLocalizations.of(context)!.renterArrived,
    );
  }
}
