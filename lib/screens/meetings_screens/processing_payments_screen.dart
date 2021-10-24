import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/widgets/big_icons.dart';

class ProcessingPaymentScreen extends StatelessWidget {
  const ProcessingPaymentScreen({Key? key, this.showAppBar = true}) : super(key: key);

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(AppLocalizations.of(context)!.processing_payments)) : null,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BigIcon(icon: Icons.attach_money_rounded),
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: 200,
              child: LinearProgressIndicator(
                color: Colors.green,
                backgroundColor: Colors.green.shade100,
              ),
            ),
            Text(
              AppLocalizations.of(context)!.processing_payments_may_take_min,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ],
        ),
      ),
    );
  }
}
