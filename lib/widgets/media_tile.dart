import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/widgets/media_container.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaTile extends StatefulWidget {
  const MediaTile({Key? key, required this.media, this.tool}) : super(key: key);

  final Tool? tool;
  final List<File> media;

  @override
  _MediaTileState createState() => _MediaTileState();
}

class _MediaTileState extends State<MediaTile> {
  final picker = ImagePicker();

  /// Opens the camera or gallery to import media files (images and/or videos)
  Future _getMedia(MediaInput inputType) async {
    try {
      // ignore: prefer_typing_uninitialized_variables
      var res;
      if (inputType == MediaInput.gallery) {
        res = await FilePicker.platform.pickFiles(
          type: FileType.media,
          allowMultiple: true,
        );
      } else {
        res = inputType == MediaInput.cameraVideo
            ? await picker.pickVideo(source: ImageSource.camera)
            : await picker.pickImage(source: ImageSource.camera);
      }

      if (res != null) {
        List<File> files;
        if (res.runtimeType == FilePickerResult) {
          files = (res as FilePickerResult).paths.map((path) => File(path!)).toList();
        } else {
          files = [File(res.path)];
        }
        _addMedia(files);
      } else {
        debugPrint('No files were selected.');
      }
    } on PlatformException catch (e) {
      if (e.code == 'read_external_storage_denied') {
        debugPrint('Storage read denied');
        _showStorageDeniedDialog();
      } else {
        rethrow;
      }
    }
  }

  /// add [files] to `widget.media` and rebuilds the widget.
  _addMedia(Iterable<File> files) {
    setState(() {
      widget.media.addAll(files);
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.files_added),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.undo,
              onPressed: () {
                _removeMedia(files);
              },
            ),
          ),
        );
      } catch (_) {}
    });
  }

  /// removes [files] from the `widget.media`.
  _removeMedia(Iterable<File> files) {
    setState(() {
      for (var file in files) {
        widget.media.remove(file);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.media.length + (widget.tool?.media.length ?? 0) + 1,
        itemBuilder: (BuildContext context, int i) {
          var index = i - 1;
          if (i == 0) return _buildAddTile();
          if (index < widget.media.length) {
            final mediaFile = widget.media[index];
            return MediaContainer(
              mediaFile: mediaFile,
              showDismiss: true,
              onDismiss: () => _removeMedia([mediaFile]),
            );
          } else {
            final mediaUrl = widget.tool!.media[index - widget.media.length];
            return MediaContainer(
              mediaURL: mediaUrl,
              showDismiss: true,
              onDismiss: () {
                setState(() {
                  widget.tool!.media.remove(mediaUrl);
                });
              },
            );
          }
        },
      ),
    );
  }

  void showMediaDisabledSnackBar(context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.media_disabled_on_web),
        action: SnackBarAction(
          onPressed: () => launch('https://github.com/ElforL/rentool/issues/62'),
          label: AppLocalizations.of(context)!.learn_more,
        ),
      ),
    );
  }

  Widget _buildAddTile() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(8),
      ),
      width: 130,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.library_add),
            color: kIsWeb ? Colors.grey : null,
            onPressed: () {
              if (kIsWeb) return showMediaDisabledSnackBar(context);
              _getMedia(MediaInput.gallery);
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            color: kIsWeb ? Colors.grey : null,
            onPressed: () {
              if (kIsWeb) return showMediaDisabledSnackBar(context);
              _getMedia(MediaInput.cameraImage);
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            color: kIsWeb ? Colors.grey : null,
            onPressed: () {
              if (kIsWeb) return showMediaDisabledSnackBar(context);
              _getMedia(MediaInput.cameraVideo);
            },
          ),
        ],
      ),
    );
  }

  _showStorageDeniedDialog() {
    var dialog = AlertDialog(
      title: Column(
        children: [
          const Icon(Icons.folder),
          Text(AppLocalizations.of(context)!.storage_permission_denied),
        ],
      ),
      content: Text(
        AppLocalizations.of(context)!.storage_permission_denied_explanation,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    );
    showDialog(context: context, builder: (_) => dialog);
  }
}

enum MediaInput {
  cameraVideo,
  cameraImage,
  gallery,
}
