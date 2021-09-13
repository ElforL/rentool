import 'package:flutter/material.dart';
import 'package:rentool/widgets/logo_image.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    Key? key,
    this.height = 100,
    this.strokeWidth = 8,
    this.strokeColor,
    this.backgroundColor,
    this.value,
    this.logoColor = LogoColor.primary,
  }) : super(key: key);

  final LogoColor logoColor;

  final double height;
  final double strokeWidth;

  final Color? strokeColor;
  final Color? backgroundColor;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: height,
          width: height,
          child: FittedBox(
            child: _logo(),
          ),
        ),
        SizedBox(
          height: height + strokeWidth - 1,
          width: height + strokeWidth - 1,
          child: CircularProgressIndicator(
            value: value,
            color: strokeColor ?? _strokeColor(),
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor,
          ),
        ),
      ],
    );
  }

  LogoImage _logo() {
    switch (logoColor) {
      case LogoColor.primary:
        return LogoImage.primaryIcon();
      case LogoColor.black:
        return LogoImage.blackIcon();
      case LogoColor.white:
        return LogoImage.whiteIcon();
    }
  }

  Color _strokeColor() {
    switch (logoColor) {
      case LogoColor.primary:
        return Colors.grey;
      case LogoColor.black:
        return Colors.grey.shade300;
      case LogoColor.white:
        return Colors.grey.shade800;
    }
  }
}
