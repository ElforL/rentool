import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/screens/edit_review_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';

// ignore: must_be_immutable
class RateUser extends StatelessWidget {
  RateUser({
    Key? key,
    required this.user,
    this.afterChange,
  }) : super(key: key);

  final RentoolUser user;
  UserReview? review;
  void Function()? afterChange;

  bool? canRate;

  Future<bool> _getCanRate() async {
    if (AuthServices.currentUid == user.uid) return canRate = false;
    return canRate = await FirestoreServices.canUserRateUser(
      AuthServices.currentUid!,
      user.uid,
    );
  }

  Future<UserReview?> _getReview() async {
    if (AuthServices.currentUid == user.uid) return review = null;
    return review = await FirestoreServices.getReviewOnUser(
      AuthServices.currentUid!,
      user.uid,
    );
  }

  Future _future() async {
    await _getReview();
    if (review != null) {
      canRate = true;
    } else {
      await _getCanRate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _future(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          if (!(canRate ?? false)) return Container();

          return Expanded(
            flex: 3,
            child: Column(
              children: [
                Text(
                  review == null
                      ? AppLocalizations.of(context)!.rate_this_user
                      : AppLocalizations.of(context)!.your_review,
                  style: Theme.of(context)
                      .textTheme
                      .overline!
                      .copyWith(color: review != null ? Colors.orange.shade700 : null),
                ),
                if (review == null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 5; i++)
                        Expanded(
                          child: IconButton(
                            icon: const Icon(Icons.star_border),
                            iconSize: 32,
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            splashRadius: 25,
                            onPressed: () async {
                              final didChange = await Navigator.of(context).pushNamed(
                                EditReviewScreen.routeNameNew,
                                arguments: EditReviewScreenArguments(
                                  user,
                                  rating: i + 1,
                                ),
                              );
                              if (didChange == true && afterChange != null) afterChange!();
                            },
                          ),
                        )
                    ],
                  )
                else
                  InkWell(
                    onTap: () async {
                      final didChange = await Navigator.of(context).pushNamed(
                        EditReviewScreen.routeNameEdit,
                        arguments: EditReviewScreenArguments(
                          user,
                          oldReview: review,
                        ),
                      );
                      if (didChange == true && afterChange != null) afterChange!();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < review!.value; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.star,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        for (var i = 0; i < 5 - review!.value; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.star_border,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        });
  }
}
