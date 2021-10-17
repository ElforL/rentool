import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/services/functions.dart';
import 'package:rentool/widgets/note_box.dart';

class BanUserScreen extends StatefulWidget {
  const BanUserScreen({Key? key}) : super(key: key);

  static const routeName = '/banUser';

  @override
  _BanUserScreenState createState() => _BanUserScreenState();
}

class _BanUserScreenState extends State<BanUserScreen> {
  bool argsRead = false;
  String? uid;
  RentoolUser? user;
  late TextEditingController _controller;
  late FocusNode focusNode;

  @override
  void initState() {
    focusNode = FocusNode();
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String get reason => _controller.text.trim();

  @override
  Widget build(BuildContext context) {
    _readArgs();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.ban_user),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.enter_reason_for_ban,
                style: Theme.of(context).textTheme.subtitle1,
              ),
              const SizedBox(height: 20),
              NoteBox(
                text: AppLocalizations.of(context)!.write_desc_in_ar_and_en,
                icon: Icons.error,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: AppLocalizations.of(context)!.the_reason,
                ),
                minLines: 10,
                maxLines: null,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    child: Text(AppLocalizations.of(context)!.ban_user.toUpperCase()),
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                    onPressed: () async {
                      focusNode.unfocus();
                      final isSure = await showConfirmDialog(
                        context,
                        content: Text(
                          AppLocalizations.of(context)!.are_you_sure_to_ban_user(
                            user?.name ?? AppLocalizations.of(context)!.this_user,
                          ),
                        ),
                      );
                      if (isSure ?? false) {
                        _showLoadingDialog();
                        final result = await FunctionsServices.banUser(uid!, reason);
                        if (result.isSuccess) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          return;
                        }
                        Navigator.pop(context);
                        _showErrorDialog('${result.statusCode} - ${result.error}');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _readArgs() {
    if (argsRead) return;
    argsRead = true;
    var args = ModalRoute.of(context)?.settings.arguments;
    assert(args != null, 'BanUserScreen was pushed with null arguments: $args');
    assert(args is BanUserScreenArguments);
    args = args as BanUserScreenArguments;
    uid = args.uid;
    user = args.user;
  }

  void _showLoadingDialog() {
    const dialog = Center(child: CircularProgressIndicator());
    showDialog(context: context, builder: (context) => dialog);
  }

  void _showErrorDialog(String response) {
    final dialog = AlertDialog(
      title: Text(AppLocalizations.of(context)!.error),
      content: Text('${AppLocalizations.of(context)!.errorInfo}:\n$response'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(AppLocalizations.of(context)!.ok.toUpperCase()),
        )
      ],
    );
    showDialog(context: context, builder: (context) => dialog);
  }
}

class BanUserScreenArguments {
  final String? uid;
  final RentoolUser? user;

  BanUserScreenArguments({String? uid, this.user})
      : assert(uid != null || user != null),
        uid = user?.uid ?? uid;
}
