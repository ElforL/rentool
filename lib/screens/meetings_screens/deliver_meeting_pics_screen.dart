import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentool/models/deliver_meetings.dart';
import 'package:rentool/widgets/drag_indicator.dart';
import 'package:rentool/widgets/expandable_fab.dart';
import 'package:rentool/widgets/icon_alert_dialog.dart';
import 'package:rentool/widgets/media_container.dart';
import 'package:rentool/widgets/meeting_appbar.dart';

class DeliverMeetingPicsContainer extends StatelessWidget {
  const DeliverMeetingPicsContainer({
    Key? key,
    required this.meeting,
  }) : super(key: key);

  final DeliverMeeting meeting;

  _uploadMedia(bool isVideo) async {
    ImagePicker picker = ImagePicker();
    XFile? file;
    if (isVideo) {
      file = await picker.pickVideo(source: ImageSource.camera);
    } else {
      file = await picker.pickImage(source: ImageSource.camera);
    }

    if (file != null) {
      meeting.addMedia(File(file.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MeetingAppBar(
        text: AppLocalizations.of(context)!.backToArrival,
        onPressed: () => meeting.setArrived(false),
        actions: [
          IconButton(
            onPressed: () => showHelpDialog(context),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      floatingActionButton: ExpandableFab(
        distance: 100,
        children: [
          ActionButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              _uploadMedia(false);
            },
          ),
          ActionButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              _uploadMedia(true);
            },
          ),
        ],
      ),
      bottomSheet: DeliverMeetingPicsBottomSheet(meeting: meeting),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "The {other} pictures and videos"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                AppLocalizations.of(context)!.the_role_pics_n_vids(meeting.otherUserRole),
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            // The other user media
            SizedBox(
              height: min(MediaQuery.of(context).size.height / 3, 300),
              child: meeting.otherUserMediaUrls.isNotEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: meeting.otherUserMediaUrls.length,
                      itemBuilder: (context, index) {
                        return MediaContainer(
                          mediaURL: meeting.otherUserMediaUrls[index],
                          showDismiss: false,
                        );
                      },
                    )
                  : Center(child: Text(AppLocalizations.of(context)!.noPicsOrVids)),
            ),
            const Divider(),
            SizedBox(
              height: MediaQuery.of(context).size.height / 10,
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
                    backgroundColor: meeting.userMediaOk ? MaterialStateProperty.all(Colors.orange.shade900) : null,
                  ),
                  child: Text(
                    (meeting.userMediaOk ? AppLocalizations.of(context)!.disagree : AppLocalizations.of(context)!.agree)
                        .toUpperCase(),
                  ),
                  onPressed: () async {
                    var isSure = meeting.userMediaOk ? true : await showConfirmDialog(context);
                    if (isSure) meeting.setMediaOK(!meeting.userMediaOk);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> showConfirmDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => IconAlertDialog(
        icon: Icons.camera_alt,
        titleText: AppLocalizations.of(context)!.areYouSure,
        bodyText: AppLocalizations.of(context)!.deliverMeet_pics_confirm_body(meeting.otherUserRole),
        importantText: AppLocalizations.of(context)!.deliverMeet_pics_confirm_important(meeting.otherUserRole),
        noteText: AppLocalizations.of(context)!.deliverMeet_pics_confirm_note(meeting.otherUserRole),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.sure.toUpperCase()),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  Future<dynamic> showHelpDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => IconAlertDialog(
        icon: Icons.camera_alt,
        titleText: AppLocalizations.of(context)!.deliverMeet_pics_help_dialog_title,
        bodyText: AppLocalizations.of(context)!.deliverMeet_pics_help_dialog_body(meeting.otherUserRole),
        importantText: AppLocalizations.of(context)!.deliverMeet_pics_confirm_important(meeting.otherUserRole),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.ok.toUpperCase()),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class DeliverMeetingPicsBottomSheet extends StatelessWidget {
  const DeliverMeetingPicsBottomSheet({
    Key? key,
    required this.meeting,
  }) : super(key: key);

  final DeliverMeeting meeting;

  @override
  Widget build(BuildContext context) {
    Widget? child;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.11,
      minChildSize: 0.11,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        child ??= Container(
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
                      padding: const EdgeInsets.only(right: 15, left: 15, bottom: 8),
                      child: Text(
                        AppLocalizations.of(context)!.my_pics_and_vids,
                        style: Theme.of(context).textTheme.headline6,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: SizedBox(
                      height: min(MediaQuery.of(context).size.height / 4, 200),
                      child: meeting.userMediaUrls.isNotEmpty
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: meeting.userMediaUrls.length,
                              itemBuilder: (context, index) {
                                return MediaContainer(
                                  mediaURL: meeting.userMediaUrls[index],
                                  showDismiss: true,
                                  onDismiss: () => meeting.removeMedia(meeting.userMediaUrls[index]),
                                );
                              },
                            )
                          : Center(child: Text(AppLocalizations.of(context)!.noPicsOrVids)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
        return child!;
      },
    );
  }
}
