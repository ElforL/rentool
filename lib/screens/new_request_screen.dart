import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/models/rentool/rentool_models.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({Key? key}) : super(key: key);

  @override
  _NewRequestScreenState createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  late Tool tool;

  late TextEditingController _descriptionController;
  late TextEditingController _daysController;
  String? _descriptionErrorText;
  String? _daysErrorText;

  int get daysNum => _daysController.text.isNotEmpty ? int.parse(_daysController.text) : 0;

  @override
  void initState() {
    _daysController = TextEditingController(text: '1');
    _descriptionController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    tool = ModalRoute.of(context)!.settings.arguments as Tool;

    return Scaffold(
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context)!.request} ${tool.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                primary: false,
                children: [
                  TextField(
                    controller: _descriptionController,
                    minLines: 1,
                    maxLines: 20,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: AppLocalizations.of(context)!.description,
                      errorText: _descriptionErrorText,
                    ),
                    onChanged: (_) {
                      if (_descriptionErrorText != null) {
                        _descriptionErrorText = null;
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    maxLength: 3,
                    controller: _daysController,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      filled: true,
                      labelText: AppLocalizations.of(context)!.number_of_days,
                      counterText: '',
                      errorText: _daysErrorText,
                    ),
                    onChanged: (_) {
                      if (_daysErrorText != null) _daysErrorText = null;
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 45),
                  Text(
                    AppLocalizations.of(context)!.summary,
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    AppLocalizations.of(context)!.rentPrice,
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$daysNum ${AppLocalizations.of(context)!.days} × ${AppLocalizations.of(context)!.priceDisplay(
                      AppLocalizations.of(context)!.sar,
                      tool.rentPrice,
                    )} = ${AppLocalizations.of(context)!.priceDisplay(
                      AppLocalizations.of(context)!.sar,
                      _calcTotal(),
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
                      tool.insuranceAmount,
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
                      _calcTotal(true),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  child: Text(AppLocalizations.of(context)!.send.toUpperCase()),
                  onPressed: () async {
                    if (_daysController.text.isEmpty) {
                      setState(() {
                        _daysErrorText = AppLocalizations.of(context)!.you_cant_leave_this_empty;
                      });
                    } else if (daysNum < 1) {
                      setState(() {
                        _daysErrorText = AppLocalizations.of(context)!.days_must_be_more_than_0;
                      });
                    } else {
                      var request = ToolRequest(
                        'TEMP',
                        AuthServices.currentUid!,
                        tool.id,
                        _descriptionController.text,
                        daysNum,
                        tool.rentPrice,
                        tool.insuranceAmount,
                        false,
                        false,
                      );
                      await FirestoreServices.sendNewToolRequest(request, tool.id);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _calcTotal([bool withInsurance = false]) {
    if (_daysController.text.isNotEmpty) {
      return tool.rentPrice * daysNum + (withInsurance ? tool.insuranceAmount : 0);
    }
    return 0;
  }
}
