import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import 'package:flutter/rendering.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/screens/user_screen.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/rating.dart';
import 'package:rentool/widgets/rentool_circle_avatar.dart';

// ignore: must_be_immutable
class ReviewTile extends StatelessWidget {
  ReviewTile({Key? key, required this.review}) : super(key: key);

  final UserReview review;
  RentoolUser? user;

  /// was [_getUser] called?
  ///
  /// used to prevent multiple calls to Firestore
  bool calledFirestore = false;

  Future<RentoolUser?> _getUser() async {
    if (calledFirestore) return null;

    calledFirestore = true;
    return user ??= await FirestoreServices.getUser(review.creatorUID);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            UserScreen.routeName,
            arguments: UserScreenArguments(
              uid: review.creatorUID,
              user: user,
            ),
          );
        },
        child: FutureBuilder(
          future: _getUser(),
          builder: (context, AsyncSnapshot<RentoolUser?> snapshot) {
            user ??= snapshot.data;
            return Row(
              children: [
                RentoolCircleAvatar(user: user),
                const SizedBox(width: 20),
                if (user != null)
                  Text(user!.name)
                else
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(),
                  )
              ],
            );
          },
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                ...RatingDisplay.getStarsIcons(
                  review.value.toDouble(),
                  iconSize: 15,
                  fullColor: Colors.orange.shade700,
                ),
                const SizedBox(width: 10),
                Text(review.value.toStringAsFixed(1)),
              ],
            ),
          ),
          if (review.description != null)
            Text(
              review.description!,
              textDirection:
                  intl.Bidi.detectRtlDirectionality(review.description!) ? TextDirection.rtl : TextDirection.ltr,
            ),
        ],
      ),
    );
  }
}
