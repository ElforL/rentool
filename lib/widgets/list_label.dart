import 'package:flutter/material.dart';

class ListLabel extends StatelessWidget {
  const ListLabel({
    Key? key,
    required this.text,
    this.color,
    this.hasLeadingSpace = true,
  }) : super(key: key);

  final String text;
  final Color? color;
  final bool hasLeadingSpace;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: hasLeadingSpace ? const Icon(null) : null,
      title: Text(
        text,
        style: TextStyle(color: color ?? Theme.of(context).colorScheme.primary),
      ),
      dense: true,
      enabled: false,
      visualDensity: const VisualDensity(vertical: -4),
    );
  }
}
