import 'package:flutter/material.dart';

class NoteBox extends StatelessWidget {
  const NoteBox({
    Key? key,
    required this.text,
    required this.icon,
    this.mainColor = Colors.black54,
    this.textStyle,
  }) : super(key: key);

  final IconData icon;
  final Color mainColor;
  final String text;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: mainColor),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Icon(icon, color: mainColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: mainColor).merge(textStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
