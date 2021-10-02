import 'package:flutter/material.dart';

class TextEditListTile extends StatefulWidget {
  const TextEditListTile({
    Key? key,
    required this.defaultValue,
    required this.title,
    required this.onSet,
  }) : super(key: key);

  final Widget? title;
  final String defaultValue;
  final void Function(String newValue)? onSet;

  @override
  State<TextEditListTile> createState() => _TextEditListTileState();
}

class _TextEditListTileState extends State<TextEditListTile> {
  bool isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.defaultValue);
    super.initState();
  }

  _cancel() {
    setState(() {
      _controller.text = widget.defaultValue;
      isEditing = false;
    });
  }

  _isEditing(bool isEditing) {
    setState(() {
      this.isEditing = isEditing;
    });
  }

  _set() {
    final name = _controller.text.trim();
    if (name != widget.defaultValue) {
      if (widget.onSet != null) widget.onSet!(name);
    }
    _isEditing(false);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: isEditing
          ? TextField(
              controller: _controller,
            )
          : widget.title,
      trailing: isEditing
          ? FittedBox(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    onPressed: () => _cancel(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.done),
                    onPressed: () => _set(),
                  ),
                ],
              ),
            )
          : IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
      visualDensity: const VisualDensity(vertical: -4),
    );
  }
}
