import 'package:flutter/material.dart';

class HomePageContainer extends StatelessWidget {
  const HomePageContainer({
    Key? key,
    required this.titleText,
    this.child,
    this.margin,
    this.elevation = 3,
  }) : super(key: key);

  final Widget? child;
  final String titleText;
  final EdgeInsetsGeometry? margin;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleText,
              style: Theme.of(context)
                  .textTheme
                  .subtitle2!
                  .copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
            ),
            const SizedBox(height: 10),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}
