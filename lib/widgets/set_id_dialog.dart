import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SetIdDialog extends StatefulWidget {
  const SetIdDialog({
    Key? key,
  }) : super(key: key);

  @override
  State<SetIdDialog> createState() => _SetIdDialogState();
}

class _SetIdDialogState extends State<SetIdDialog> {
  final _idController = TextEditingController();
  String? errorText;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.set_id_number),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.you_cant_change_id_number,
            style: const TextStyle(color: Colors.red),
          ),
          TextField(
            controller: _idController,
            decoration: InputDecoration(
              label: Text(AppLocalizations.of(context)!.id_number),
              hintText: AppLocalizations.of(context)!.enter_your_id_number,
              errorText: errorText,
            ),
            maxLength: 10,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        TextButton(
          onPressed: () {
            if (_idController.text.trim().length == 10) {
              Navigator.pop(context, _idController.text.trim());
            } else {
              setState(() {
                errorText = AppLocalizations.of(context)!.id_number_must_be_10_digits;
              });
            }
          },
          child: const Text('SET'),
        ),
      ],
    );
  }
}
