import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// 404 screen
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.not_found),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Text(
              '404',
              style: Theme.of(context).textTheme.headline1?.copyWith(fontFamily: 'Roboto', fontWeight: FontWeight.w100),
            ),
            Text(
              AppLocalizations.of(context)!.couldnt_find_page,
              style: Theme.of(context).textTheme.subtitle1,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 150),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.back.toUpperCase()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
