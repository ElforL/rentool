import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/widgets/drag_indicator.dart';

class DeliverMeetingPicsContainer extends StatelessWidget {
  const DeliverMeetingPicsContainer({
    Key? key,
    required this.didUserAgree,
    required this.didOtherUserAgree,
    required this.isUserTheOwner,
    required this.onPressed,
  }) : super(key: key);

  final bool didUserAgree;
  final bool didOtherUserAgree;
  final bool isUserTheOwner;
  final Function onPressed;

  String get userRole => isUserTheOwner ? 'owner' : 'renter';
  String get otherUserRole => !isUserTheOwner ? 'owner' : 'renter';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {},
      ),
      bottomSheet: const DeliverMeetingPicsBottomSheet(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "The {other} pictures and videos"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                AppLocalizations.of(context)!.the_role_pics_n_vids(otherUserRole),
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            // The other user media
            SizedBox(
              height: min(MediaQuery.of(context).size.height / 3, 300),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 12,
                itemBuilder: (context, index) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Placeholder(
                      fallbackWidth: 100,
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 5,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                AppLocalizations.of(context)!.deliver_pics_explanation,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            Center(
              child: SizedBox(
                width: 120,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: didUserAgree ? MaterialStateProperty.all(Colors.orange.shade900) : null,
                  ),
                  child: Text(
                    (didUserAgree ? AppLocalizations.of(context)!.disagree : AppLocalizations.of(context)!.agree)
                        .toUpperCase(),
                  ),
                  onPressed: () => onPressed(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeliverMeetingPicsBottomSheet extends StatelessWidget {
  const DeliverMeetingPicsBottomSheet({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                spreadRadius: -3,
              ),
            ],
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Stack(
            children: [
              ListView(
                controller: scrollController,
                children: [
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: DragIndicator(),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // scrollController.animateTo(100, duration: Duration(seconds: 1), curve: Curves.ease);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: Text(
                        AppLocalizations.of(context)!.my_pics_and_vids,
                        style: Theme.of(context).textTheme.headline6,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: SizedBox(
                      height: 200,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          SizedBox(width: 10),
                          Placeholder(),
                          Placeholder(),
                          Placeholder(),
                          Placeholder(),
                          Placeholder(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
