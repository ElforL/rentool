import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:rentool/services/storage_services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

class TermsScreen extends StatelessWidget {
  static const tosRouteName = '/tos';
  static const privacyPolicyRouteName = '/privacy_policy';
  const TermsScreen({
    Key? key,
    this.isTos = true,
  }) : super(key: key);

  final bool isTos;

  Future<String?> getAgreementBytes() async {
    final bytes = isTos ? await StorageServices.getTOS() : await StorageServices.getPrivacyPolicy();
    if (bytes == null) return null;
    return String.fromCharCodes(bytes);
  }

  Future<String?> getAgreementFromUrl() async {
    final url = isTos ? await StorageServices.getTosUrl() : await StorageServices.getPrivacyPolicyUrl();
    return await http.read(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final Future<String?> future;

    if (kIsWeb) {
      future = getAgreementFromUrl();
    } else {
      future = getAgreementBytes();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTos ? AppLocalizations.of(context)!.tos : AppLocalizations.of(context)!.privacy_policy,
        ),
      ),
      body: FutureBuilder(
        future: future,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            debugPrintStack(label: snapshot.error.toString(), stackTrace: snapshot.stackTrace);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 100),
                  Text(
                    AppLocalizations.of(context)!.unexpected_error_occured,
                    style: Theme.of(context).textTheme.headline6,
                  ),
                ],
              ),
            );
          }
          if (snapshot.data == null) return const Center(child: CircularProgressIndicator());

          return Directionality(
            textDirection: TextDirection.ltr,
            child: Markdown(
              selectable: true,
              data: snapshot.data,
            ),
          );
        },
      ),
    );
  }
}
