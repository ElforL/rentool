import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/models/return_meeting.dart';
import 'package:rentool/widgets/expandable_fab.dart';
import 'package:rentool/widgets/icon_alert_dialog.dart';
import 'package:rentool/widgets/media_container.dart';
import 'package:rentool/widgets/meeting_appbar.dart';
import 'package:rentool/widgets/note_box.dart';

class DisagreementMediaScreen extends StatelessWidget {
  const DisagreementMediaScreen({
    Key? key,
    required this.meeting,
  }) : super(key: key);

  final ReturnMeeting meeting;

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
        text: meeting.isUserTheOwner
            ? AppLocalizations.of(context)!.backToInspect
            : AppLocalizations.of(context)!.backToClaim,
        onPressed: () {
          if (meeting.isUserTheOwner) {
            meeting.setToolDamaged(null);
          } else {
            meeting.setAdmitDamage(null);
          }
        },
        actions: [
          IconButton(
            onPressed: () => showDisagreementCasesHelpDialog(context, meeting.isUserTheOwner),
            icon: const Icon(Icons.help_outline_outlined),
          )
        ],
      ),
      floatingActionButton: ExpandableFab(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.black,
        distance: 100,
        children: [
          ActionButton(
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              _uploadMedia(false);
            },
          ),
          ActionButton(
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.videocam),
            onPressed: () {
              _uploadMedia(true);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: NoteBox(
                icon: Icons.info,
                text: meeting.isUserTheOwner
                    ? AppLocalizations.of(context)!.disagreementMediaUploadInfoOwner
                    : AppLocalizations.of(context)!.disagreementMediaUploadInfoRenter,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                AppLocalizations.of(context)!.my_pics_and_vids,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            Expanded(
              flex: 3,
              child: meeting.userMediaUrls.isNotEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: meeting.userMediaUrls.length,
                      itemBuilder: (context, index) {
                        return MediaContainer(
                          mediaURL: meeting.userMediaUrls[index],
                          showDismiss: true,
                        );
                      },
                    )
                  : Center(
                      child: Text(AppLocalizations.of(context)!.noPicsOrVids),
                    ),
            ),
            const Divider(),
            const Spacer(),
            Center(
              child: Container(
                margin: const EdgeInsets.all(10),
                width: 200,
                child: ElevatedButton(
                  child: Text(
                    (meeting.userMediaOK
                            ? AppLocalizations.of(context)!.notFinished
                            : AppLocalizations.of(context)!.finished)
                        .toUpperCase(),
                  ),
                  style: ButtonStyle(
                    backgroundColor: meeting.userMediaOK ? MaterialStateProperty.all(Colors.orange.shade900) : null,
                  ),
                  onPressed: () async {
                    final isSure = meeting.userMediaOK ? true : await showConfirmDialog(context);
                    if (isSure) meeting.setMediaOk(!meeting.userMediaOK);
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
        bodyText: AppLocalizations.of(context)!.caseMediaCofirmBody,
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
}
