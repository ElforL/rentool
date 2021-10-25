import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RatingDisplay extends StatelessWidget {
  const RatingDisplay({
    Key? key,
    required this.rating,
    required this.numberOfReview,
    this.color,
    this.onTap,
  }) : super(key: key);

  final double rating;
  final Color? color;
  final int numberOfReview;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            FittedBox(
              child: Text(
                rating.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            FittedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: getStarsIcons(
                  rating,
                  iconSize: 12,
                  fullColor: color,
                  emptyColor: color,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 70),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: AlignmentDirectional.topStart,
              child: Text(
                NumberFormat.compact().format(numberOfReview).toString(),
                textScaleFactor: .6,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Return a list of stars [Icon] widgets to represent the [rating]
  static List<Widget> getStarsIcons(
    double rating, {
    double? iconSize,
    Color? fullColor,
    Color? emptyColor,
  }) {
    final fullStars = rating.floor();
    final halfStars = rating - fullStars > 0;
    final emptyStars = 5 - fullStars - (halfStars ? 1 : 0);

    return [
      for (var i = 0; i < fullStars; i++)
        Icon(
          Icons.star,
          size: iconSize,
          color: fullColor,
        ),
      if (halfStars)
        Icon(
          Icons.star_half,
          size: iconSize,
          color: fullColor,
        ),
      for (var i = 0; i < emptyStars; i++)
        Icon(
          Icons.star_border,
          size: iconSize,
          color: emptyColor,
        ),
    ];
  }
}
