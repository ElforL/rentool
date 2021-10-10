import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/models/rentool/rentool_models.dart';

class EditRequestScreen extends StatefulWidget {
  const EditRequestScreen({Key? key}) : super(key: key);

  static const routeName = '/editRequest';

  @override
  _EditRequestScreenState createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  late Tool? tool;
  late ToolRequest request;
  bool initiated = false;

  late TextEditingController _descriptionController;
  late TextEditingController _daysController;
  String? _descriptionErrorText;
  String? _daysErrorText;

  int get daysNum => _daysController.text.isNotEmpty ? int.parse(_daysController.text) : 0;

  Future<Tool> _getToolFromFirestore() async {
    final doc = await FirestoreServices.getTool(request.toolID);
    return Tool.fromJson((doc.data() as Map<String, dynamic>)..addAll({'id': doc.id}));
  }

  @override
  void initState() {
    tool = null;
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
    if (!initiated) {
      initiated = true;
      final args = ModalRoute.of(context)!.settings.arguments as EditRequestScreenArguments;
      if (args.tool != null) tool = args.tool;
      request = args.request;

      _descriptionController.text = request.description;
      _daysController.text = request.numOfDays.toString();
    }

    Future<Tool>? future;
    if (tool == null) {
      future = _getToolFromFirestore();
    } else {
      future = Future.value(tool);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.edit_request),
      ),
      body: FutureBuilder(
          future: future,
          builder: (context, AsyncSnapshot<Tool> snapshot) {
            tool ??= snapshot.data;

            if (tool == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(AppLocalizations.of(context)!.loading),
                  ],
                ),
              );
            }

            return Padding(
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
                          onChanged: (newText) {
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
                        ..._buildSummary(),
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
                        child: Text(AppLocalizations.of(context)!.edit.toUpperCase()),
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
                            try {
                              await FirestoreServices.updateToolRequest(
                                request
                                  ..description = _descriptionController.text
                                  ..numOfDays = daysNum,
                                tool!.id,
                              );

                              request.description = _descriptionController.text;
                              request.numOfDays = daysNum;
                              Navigator.pop(context);
                            } catch (e) {
                              print('An unexpected error occured: $e');
                              Widget? content;
                              if (e is FirebaseException) {
                                content = Text(AppLocalizations.of(context)!.permission_denied);
                              }
                              showErrorDialog(
                                context,
                                content: content,
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
    );
  }

  List<Widget> _buildSummary() {
    return [
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
          tool!.rentPrice,
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
          tool!.insuranceAmount,
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
    ];
  }

  _calcTotal([bool withInsurance = false]) {
    if (_daysController.text.isNotEmpty) {
      return tool!.rentPrice * daysNum + (withInsurance ? tool!.insuranceAmount : 0);
    }
    return 0;
  }
}

class EditRequestScreenArguments {
  final Tool? tool;
  final ToolRequest request;

  EditRequestScreenArguments(this.request, {this.tool});
}
