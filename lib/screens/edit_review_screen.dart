import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/loading_indicator.dart';
import 'package:rentool/widgets/logo_image.dart';

class EditReviewScreen extends StatefulWidget {
  /// the route name of EditReviewScreen when [isNew] == `true`
  /// ```
  /// '/newReview'
  /// ```
  static const routeNameNew = '/newReview';

  /// the route name of EditReviewScreen when [isNew] == `false`
  /// ```
  /// '/editReview'
  /// ```
  static const routeNameEdit = '/editReview';

  const EditReviewScreen({Key? key, required this.isNew}) : super(key: key);

  final bool isNew;

  @override
  _EditReviewScreenState createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends State<EditReviewScreen> {
  bool areArgumentsRead = false;
  late RentoolUser target;
  UserReview? oldReview;
  int rating = 0;

  late TextEditingController _descriptionController;

  bool _didChange() {
    if (widget.isNew) return true;
    return rating != oldReview!.value || _description != oldReview!.description;
  }

  String get _description => _descriptionController.text.trim();

  bool get _isValidRating => rating >= 1 && rating <= 5;

  void _setRating(int newVal) {
    setState(() {
      rating = newVal;
    });
  }

  @override
  void initState() {
    _descriptionController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _readArguments(BuildContext context) {
    if (areArgumentsRead) return;
    areArgumentsRead = true;
    assert(ModalRoute.of(context)?.settings.arguments != null, 'EditReviewScreen was not given an argument.');
    final args = ModalRoute.of(context)?.settings.arguments as EditReviewScreenArguments;
    target = args.targetUser;
    if (widget.isNew) {
      rating = args.rating ?? 0;
    } else {
      oldReview = args.oldReview;
      rating = args.oldReview!.value;
      _descriptionController.text = oldReview!.description!;
    }
  }

  void _post() async {
    final newReview = UserReview(
      AuthServices.currentUid!,
      target.uid,
      rating,
      _description,
    );

    FirestoreServices.createReview(newReview).then((_) {
      Navigator.of(context).popUntil(ModalRoute.withName(
        widget.isNew ? EditReviewScreen.routeNameNew : EditReviewScreen.routeNameEdit,
      ));
      Navigator.pop(context, true);
    }).onError((error, stackTrace) {
      Navigator.of(context).popUntil(ModalRoute.withName(
        widget.isNew ? EditReviewScreen.routeNameNew : EditReviewScreen.routeNameEdit,
      ));
      // TODO show error dialog
    });

    // Shows loading dialog while creating the review
    showDialog(
      context: context,
      barrierDismissible: false,
      // WillPopScope prevent the user from popping the dialog with back button
      // source: https://stackoverflow.com/a/59755386/12571630
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoadingIndicator(logoColor: LogoColor.white),
              const SizedBox(height: 30),
              Text(
                AppLocalizations.of(context)!.posting_review,
                style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _readArguments(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          tooltip: AppLocalizations.of(context)!.discard,
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.close),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(target.name),
            Text(
              AppLocalizations.of(context)!.rate_this_user,
              style: Theme.of(context).textTheme.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.post.toUpperCase()),
            onPressed: _isValidRating && _didChange() ? _post : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(AppLocalizations.of(context)!.give_username_rating(target.name)),
              FittedBox(
                child: Row(
                  children: [
                    for (var i = 0; i < 5; i++) _buildStarButton(i, i < rating),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 500),
                child: TextField(
                  controller: _descriptionController,
                  maxLength: 500,
                  minLines: 1,
                  maxLines: 20,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: AppLocalizations.of(context)!.descripe_your_expierence,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  AppLocalizations.of(context)!.your_review_may_take_while_note,
                  style: Theme.of(context).textTheme.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconButton _buildStarButton(int i, bool full) {
    return IconButton(
      tooltip: '${i + 1}/5',
      iconSize: 45,
      icon: Icon(full ? Icons.star : Icons.star_border),
      color: full ? Colors.orange.shade700 : null,
      onPressed: () => _setRating(i + 1),
    );
  }
}

class EditReviewScreenArguments {
  final UserReview? oldReview;
  final int? rating;
  final RentoolUser targetUser;

  EditReviewScreenArguments(
    this.targetUser, {
    this.oldReview,
    this.rating,
  });
}
