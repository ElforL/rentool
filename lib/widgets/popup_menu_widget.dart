import 'package:flutter/material.dart';

/// A `PopupMenuEntry` that is not pressable.
///
/// Useful for placing buttons or plain text in it.
class PopupMenuWidget<T> extends PopupMenuEntry<T> {
  const PopupMenuWidget({
    Key? key,
    this.height = 1,
    this.child,
    this.padding = const EdgeInsets.all(0),
  }) : super(key: key);

  final Widget? child;
  final EdgeInsetsGeometry padding;

  @override
  final double height;

  @override
  _PopupMenuWidgetState createState() => new _PopupMenuWidgetState();

  @override
  bool represents(T? value) {
    throw UnimplementedError();
  }
}

class _PopupMenuWidgetState extends State<PopupMenuWidget> {
  @override
  Widget build(BuildContext context) => Padding(padding: widget.padding, child: widget.child);
}
