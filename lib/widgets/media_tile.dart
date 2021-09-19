import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/widgets/media_container.dart';

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
        print('No files were selected.');
      }
    } on PlatformException catch (e) {
      if (e.code == 'read_external_storage_denied') {
        print('Storage read denied');
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
            // TODO localize
            content: const Text('files added'),
            action: SnackBarAction(
              label: 'Undo',
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

  Widget _buildAddTile() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(8),
      ),
      width: 130,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.library_add),
            onPressed: () {
              _getMedia(MediaInput.gallery);
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              _getMedia(MediaInput.cameraImage);
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
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
        children: const [
          Icon(Icons.folder),
          // TODO localize
          Text('Storage permission denied'),
        ],
      ),
      // TODO localize
      content: const Text(
        "The app was denied access to the gallery. To allow the app to upload media from your device, it needs to have access to the device storage.\n\n"
        "You can give access if a permission dialog pops up, or in the app settings.",
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
