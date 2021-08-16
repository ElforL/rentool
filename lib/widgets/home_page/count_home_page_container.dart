import 'package:flutter/material.dart';
import 'package:rentool/widgets/home_page/home_page_container.dart';

class CountHomePageContainer extends StatelessWidget {
  const CountHomePageContainer({
    Key? key,
    this.margin,
    this.elevation = 3,
    required this.titleText,
    required this.subtitle,
  }) : super(key: key);

  final String titleText;
  final String subtitle;
  final EdgeInsetsGeometry? margin;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    return HomePageContainer(
      titleText: titleText,
      child: Text(
        subtitle,
        style: Theme.of(context)
            .textTheme
            .headline4!
            .copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(255)),
      ),
    );
  }
}
