import 'package:flutter/material.dart';

class RatingDisplay extends StatelessWidget {
  const RatingDisplay({
    Key? key,
    required this.rating,
    this.color,
    this.onTap,
  }) : super(key: key);

  final double rating;
  final Color? color;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final halfStars = rating - fullStars > 0;
    final emptyStars = 5 - fullStars - (halfStars ? 1 : 0);
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
                children: [
                  for (var i = 0; i < fullStars; i++) _buildIcon(Icons.star),
                  if (halfStars) _buildIcon(Icons.star_half),
                  for (var i = 0; i < emptyStars; i++) _buildIcon(Icons.star_border),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(IconData? icon) => Icon(
        icon,
        size: 12,
        color: color,
      );
}
