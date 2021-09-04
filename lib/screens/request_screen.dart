import 'package:flutter/material.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool_sdk/rentool_sdk.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ignore: must_be_immutable
class RequestScreen extends StatelessWidget {
  RequestScreen({Key? key}) : super(key: key);

  late ToolRequest request;
  late bool showAcceptButton;

  @override
  Widget build(BuildContext context) {
    assert(ModalRoute.of(context)?.settings.arguments != null, 'RequestScreen was pushed with no arguments');
    final args = ModalRoute.of(context)!.settings.arguments as RequestScreenArguments;
    request = args.request;
    showAcceptButton = args.showAcceptButton;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              primary: false,
              children: [
                Text(
                  AppLocalizations.of(context)!.number_of_days,
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 15),
                Text(request.numOfDays.toString()),
                const SizedBox(height: 25),
                Text(
                  AppLocalizations.of(context)!.description,
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 15),
                if (request.description.isNotEmpty)
                  Text(request.description)
                else
                  Text(
                    AppLocalizations.of(context)!.no_description,
                    style: TextStyle(color: Colors.red.shade300),
                  ),
                const SizedBox(height: 25),
                Text(
                  AppLocalizations.of(context)!.renter,
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 15),
                Text(request.renterUID),
                const SizedBox(height: 25),
                Text(
                  AppLocalizations.of(context)!.price,
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 15),
                Text(
                  AppLocalizations.of(context)!.rentPrice,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${request.numOfDays} ${AppLocalizations.of(context)!.days} × ${AppLocalizations.of(context)!.priceDisplay(
                    AppLocalizations.of(context)!.sar,
                    request.rentPrice,
                  )} = ${AppLocalizations.of(context)!.priceDisplay(
                    AppLocalizations.of(context)!.sar,
                    request.rentPrice * request.numOfDays,
                  )}',
                ),
                const SizedBox(height: 15),
                Text(
                  AppLocalizations.of(context)!.insurancePrice,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppLocalizations.of(context)!.priceDisplay(
                    AppLocalizations.of(context)!.sar,
                    request.insuranceAmount,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  AppLocalizations.of(context)!.total,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppLocalizations.of(context)!.priceDisplay(
                    AppLocalizations.of(context)!.sar,
                    request.rentPrice * request.numOfDays + request.insuranceAmount,
                  ),
                ),
              ],
            ),
          ),
          if (showAcceptButton) ...[
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    child: Text(AppLocalizations.of(context)!.reject.toUpperCase()),
                    onPressed: () {
                      FirestoreServices.deleteRequest(request.toolID, request.id);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    child: Text(AppLocalizations.of(context)!.accept.toUpperCase()),
                    onPressed: () {
                      FirestoreServices.acceptRequest(request.toolID, request.id);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class RequestScreenArguments {
  final ToolRequest request;
  final bool showAcceptButton;

  RequestScreenArguments(this.request, this.showAcceptButton);
}
