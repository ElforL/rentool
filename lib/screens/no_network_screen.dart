import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/widgets/big_icons.dart';

class NoNetworkScreen extends StatelessWidget {
  const NoNetworkScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.no_network),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [const BigIcon(icon: Icons.cloud_off), Text(AppLocalizations.of(context)!.you_not_connected)],
        ),
      ),
    );
  }
}
