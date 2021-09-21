import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rentool/models/rentool/rentool_models.dart';

class RentoolCircleAvatar extends StatelessWidget {
  const RentoolCircleAvatar({
    Key? key,
    required this.user,
    this.maxRadius,
    this.minRadius,
    this.onBackgroundImageError,
    this.onForegroundImageError,
    this.radius,
  }) : super(key: key);

  RentoolCircleAvatar.firebaseUser({
    Key? key,
    required User user,
    this.maxRadius,
    this.minRadius,
    this.onBackgroundImageError,
    this.onForegroundImageError,
    this.radius,
  })  : user = RentoolUser(user.uid, user.displayName ?? '', 0, 0),
        super(key: key);

  final RentoolUser? user;
  final double? maxRadius;
  final double? minRadius;
  final void Function(Object, StackTrace?)? onBackgroundImageError;
  final void Function(Object, StackTrace?)? onForegroundImageError;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: user?.photoURL == null ? Colors.black12 : null,
      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
      child: user?.photoURL == null
          ? const Icon(
              Icons.person,
              color: Colors.black,
            )
          : null,
      //
      maxRadius: maxRadius,
      minRadius: minRadius,
      onBackgroundImageError: onBackgroundImageError,
      onForegroundImageError: onForegroundImageError,
      radius: radius,
    );
  }
}
