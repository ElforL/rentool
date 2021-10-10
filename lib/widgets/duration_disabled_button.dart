import 'package:flutter/material.dart';

/// a Text button that stays disabled for [seconds]
class DurationDisabledButton extends StatefulWidget {
  const DurationDisabledButton({
    Key? key,
    required this.seconds,
    required this.child,
    required this.onPressed,
  }) : super(key: key);

  final int seconds;
  final Widget child;
  final void Function()? onPressed;

  @override
  State<DurationDisabledButton> createState() => _DurationDisabledButtonState();
}

class _DurationDisabledButtonState extends State<DurationDisabledButton> {
  int currentSecond = 0;

  late TextButton button;

  Future<void> _nextSecond() async {
    if (currentSecond < widget.seconds) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        currentSecond++;
      });
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _nextSecond(),
      builder: (context, snapshot) {
        if (currentSecond != widget.seconds) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(
                colors: [Colors.black12, Theme.of(context).colorScheme.primary.withAlpha(90)],
                stops: [1 - currentSecond / widget.seconds, 1 - currentSecond / widget.seconds],
              ),
            ),
            child: TextButton(
              style: const ButtonStyle(visualDensity: VisualDensity(vertical: -3)),
              onPressed: null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.surface,
                        spreadRadius: 10,
                        blurRadius: 9,
                      )
                    ]),
                    child: Text(
                      (widget.seconds - currentSecond).toString(),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  widget.child
                ],
              ),
            ),
          );
        }
        return TextButton(
          child: widget.child,
          onPressed: widget.onPressed,
        );
      },
    );
  }
}
