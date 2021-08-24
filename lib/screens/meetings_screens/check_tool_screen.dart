import 'package:flutter/material.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/big_icons.dart';
import 'package:rentool_sdk/rentool_sdk.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MeetingCheckToolScreen extends StatelessWidget {
  const MeetingCheckToolScreen({
    Key? key,
    required this.isUserTheOwner,
    required this.tool,
  }) : super(key: key);

  final Tool tool;
  final bool isUserTheOwner;

  @override
  Widget build(BuildContext context) {
    const buttonWidth = 170.0;
    const buttonPadding = EdgeInsets.symmetric(horizontal: 10);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const BigIcon(
                icon: Icons.build_circle,
              ),
              if (isUserTheOwner) ...[
                // "Inspect the tool"
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(AppLocalizations.of(context)!.inspect_the_tool),
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 7),
                // "Was the tool damaged?"
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    AppLocalizations.of(context)!.was_tool_damaged,
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: buttonWidth,
                      padding: buttonPadding,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.red),
                        ),
                        child: Text(AppLocalizations.of(context)!.damaged(false).toUpperCase()),
                        onPressed: () {
                          FirestoreServices.setReturnMeetingField(tool, 'toolDamaged', true);
                        },
                      ),
                    ),
                    Container(
                      width: buttonWidth,
                      padding: buttonPadding,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.green),
                        ),
                        child: Text(AppLocalizations.of(context)!.not_damaged(false).toUpperCase()),
                        onPressed: () {
                          FirestoreServices.setReturnMeetingField(tool, 'toolDamaged', false);
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(AppLocalizations.of(context)!.let_owner_inspect_tool),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
