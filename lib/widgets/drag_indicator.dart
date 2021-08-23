import 'package:flutter/material.dart';

class DragIndicator extends StatelessWidget {
  const DragIndicator({
    Key? key,
    this.width = 40,
    this.height = 7,
    this.color = Colors.black26,
  }) : super(key: key);

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(360)),
    );
  }
}
