import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/review_tile.dart';
import 'package:rentool/widgets/reviews_filter_chips.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({Key? key}) : super(key: key);

  static const routeName = '/userReviews';

  @override
  _ReviewsScreenState createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  /// is loading from Firestore?
  ///
  /// used to prevent multiple calls for Firestore.
  bool isLoading = false;

  /// there is no more docs other than the one loaded
  ///
  /// defaults to `false` and turns `true` when [_getRequests()] doesn't return any docs
  bool noMoreDocs = false;
  List<UserReview> reviews = [];
  List<ReviewTile> widgets = [];
  DocumentSnapshot<Object?>? previousDoc;
  late RentoolUser user;

  ReviewFilter selectedFilter = ReviewFilter.all;

  late final ScrollController _scrollController;

  Future<void> _getReviews() async {
    if (isLoading) return;
    isLoading = true;
    try {
      final result = await FirestoreServices.getReviewsOnUser(
        user.uid,
        previousDoc: previousDoc,
        reviewValueFilter: selectedFilter == ReviewFilter.all ? null : ReviewFilter.values.indexOf(selectedFilter),
      );
      if (result.docs.isEmpty) {
        noMoreDocs = true;
      } else {
        for (var doc in result.docs) {
          try {
            final review = UserReview.fromJson(doc.data());
            reviews.add(review);
            widgets.add(ReviewTile(review: review));
          } catch (e) {
            print('Failed to create UserReview object for doc(${doc.reference.path}): $e');
          }
        }
        previousDoc = result.docs.last;
      }
    } catch (e) {
      debugPrint('An error occured while getting user(${user.uid})\'s reviews from Firestore: $e');
      noMoreDocs = true;
    }
    isLoading = false;
  }

  _refresh() {
    setState(() {
      reviews.clear();
      widgets.clear();
      noMoreDocs = false;
      previousDoc = null;
    });
  }

  _changeFilter(ReviewFilter selectedVal) {
    selectedFilter = selectedVal;
    _refresh();
  }

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    assert(
      routeArgs != null,
      'ReviewsScreen was pushed with no arguments.\nuse ReviewsScreenArguments when pushing ReviewsScreen to the navigator',
    );
    assert(
      routeArgs is ReviewsScreenArguments,
      'Arguments pushed with ReviewsScreen must be of type ReviewsScreenArguments: ${routeArgs.runtimeType}',
    );
    final args = ModalRoute.of(context)!.settings.arguments as ReviewsScreenArguments;
    user = args.user;

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(user.name),
                const SizedBox(width: 10),
                Text(
                  user.rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.caption,
                ),
                Icon(
                  Icons.star,
                  size: 12,
                  color: Theme.of(context).textTheme.caption?.color,
                ),
              ],
            ),
            Text(
              AppLocalizations.of(context)!.ratings_and_reviews,
              style: Theme.of(context).textTheme.caption,
            ),
          ],
        ),
      ),
      body: FutureBuilder(
        future: _getReviews(),
        builder: (context, snapshot) {
          if (noMoreDocs && reviews.isEmpty && selectedFilter == ReviewFilter.all) {
            return _buildNoReviews(context);
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: PrimaryScrollController(
              controller: _scrollController,
              child: ListView(
                primary: true,
                children: [
                  ReviewsFilterChips(
                    selected: selectedFilter,
                    onChange: _changeFilter,
                  ),
                  const Divider(),
                  ListView.separated(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: reviews.length + 1,
                    itemBuilder: (context, index) {
                      if (noMoreDocs && reviews.isEmpty) {
                        return _buildNoReviews(context);
                      }

                      if (index >= reviews.length) {
                        if (!noMoreDocs && !isLoading) {
                          _getReviews().then((value) {
                            setState(() {});
                          });
                        }
                        return ListTile(
                          title: noMoreDocs ? null : const LinearProgressIndicator(),
                        );
                      }
                      return widgets[index];
                    },
                    separatorBuilder: (context, index) {
                      return Row(children: const [
                        SizedBox(
                          width: 100,
                          child: Divider(
                            thickness: 1,
                            indent: 20,
                          ),
                        ),
                      ]);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Center _buildNoReviews(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_rounded,
            size: 100,
            color: Colors.grey.shade700,
          ),
          Text(
            AppLocalizations.of(context)!.no_reviews,
            style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class ReviewsScreenArguments {
  final RentoolUser user;

  ReviewsScreenArguments(
    this.user,
  );
}
