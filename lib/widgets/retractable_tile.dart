import 'package:flutter/material.dart';

/// a widget that displays a [ListTile] when compact is set to `false`
/// and displays an [IconButton] when it's set to `true`
class RetractableTile extends StatelessWidget {
  const RetractableTile({
    Key? key,
    required this.compact,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  final bool compact;
  final Widget icon;
  final Widget? title;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        icon: icon,
        color: Colors.black54,
        onPressed: onTap,
      );
    }
    return ListTile(
      leading: icon,
      iconColor: Colors.black54,
      title: title,
      onTap: onTap,
    );
  }
}
