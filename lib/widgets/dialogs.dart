import 'package:flutter/material.dart';

class IconAlertDialog extends StatelessWidget {
  const IconAlertDialog({
    Key? key,
    required this.icon,
    required this.titleText,
    this.bodyText,
    this.importantText,
    this.noteText,
    this.actions,
  }) : super(key: key);

  final IconData icon;
  final String titleText;
  final String? bodyText;
  final String? importantText;
  final String? noteText;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(icon, size: 90),
            ),
          ),
          Text(
            titleText,
            style: Theme.of(context).textTheme.headline6,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Body
            if (bodyText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(bodyText!),
              ),
            // Red text
            if (importantText != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  importantText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            // Note
            if (noteText != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  noteText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(140)),
                ),
              ),
          ],
        ),
      ),
      actions: actions,
    );
  }
}
