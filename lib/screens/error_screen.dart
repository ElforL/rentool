import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    Key? key,
    required this.error,
    this.child,
  }) : super(key: key);

  final Object? error;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.error),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 100),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.unexpected_error_occured,
                style: Theme.of(context).textTheme.headline6,
              ),
              const SizedBox(height: 10),
              if (child != null) ...[
                child!,
                const SizedBox(height: 10),
              ],
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 4),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 15),
                  title: Text(AppLocalizations.of(context)!.errorInfo),
                  children: [SelectableText(error.toString())],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
