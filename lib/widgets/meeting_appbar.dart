import 'package:flutter/material.dart';

class MeetingAppBar extends AppBar {
  MeetingAppBar({
    this.actions,
    this.label,
    this.text,
    this.icon = const Icon(Icons.arrow_back),
    required this.onPressed,
    Key? key,
  }) : super(
          title: TextButton.icon(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
              ),
              padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 20)),
              backgroundColor: MaterialStateProperty.all(Colors.black26),
              foregroundColor: MaterialStateProperty.all(Colors.black),
              overlayColor: MaterialStateProperty.all(Colors.blue),
            ),
            label: label ?? Text(text!),
            icon: icon,
            onPressed: onPressed,
          ),
          automaticallyImplyLeading: false,
          key: key,
        ) {
    assert(text != null || label != null);
  }

  @override
  // ignore: overridden_fields
  final List<Widget>? actions;
  final Widget? label;
  final String? text;
  final Icon icon;
  final void Function() onPressed;
}
