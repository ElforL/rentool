import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:rentool/screens/media_view_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class MediaContainer extends StatelessWidget {
  const MediaContainer({
    Key? key,
    this.mediaFile,
    this.mediaURL,
    required this.showDismiss,
    this.onDismiss,
  })  : assert((mediaFile != null) ^ (mediaURL != null)),
        super(key: key);

  final File? mediaFile;
  final String? mediaURL;

  /// show the red __x__ button
  ///
  /// [onDismiss] is called when the button is pressed
  final bool showDismiss;

  /// The callback that is called when the red __x__ button is pressed
  ///
  /// [showDismiss] must be `true` for the button to show
  final void Function()? onDismiss;

  Future<Uint8List?> _getUrlBytes() async {
    assert(mediaURL != null);
    final response = await http.get(Uri.parse(mediaURL!));
    final bytes = response.bodyBytes;
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    // get the image bytes as a `Future<Uint8List?>`
    Future<Uint8List?> future;
    String? type;

    if (mediaFile != null) {
      type = lookupMimeType(mediaFile!.path)?.split('/')[0];
    } else {
      // get rid of all the paramaters on the http request in the url
      // and stick to the base GET request (i.e., all before '?')
      // which ends in the file extension (e.g., .png or .mp4) which is what `lookupMimeType()` looks at
      int? indexOfQ = mediaURL!.indexOf('?');
      if (indexOfQ == -1) indexOfQ = null;
      final baseURL = mediaURL!.substring(0, indexOfQ);
      type = lookupMimeType(baseURL)?.split('/')[0];
    }

    if (type == 'image') {
      future = mediaFile?.readAsBytes() ?? _getUrlBytes();
    } else if (type == 'video') {
      future = VideoThumbnail.thumbnailData(video: mediaURL ?? mediaFile!.path);
    } else {
      print('Media type is not an image nor a video: $type.');
      return _buildError(context);
    }

    // build using `FutureBuilder`
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FutureBuilder(
          future: future,
          builder: (context, AsyncSnapshot<Uint8List?> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _buildLoading();
            }
            if (snapshot.data == null) {
              print('Image bytes were null for file "${mediaFile?.path ?? mediaURL}"');
              return _buildError(context);
            }

            return Stack(
              children: [
                InkWell(
                  onTap: () {
                    _pushMediaViewScreen(context, type, snapshot.data);
                  },
                  child: Image.memory(
                    snapshot.data!,
                    errorBuilder: (context, error, stackTrace) => _buildError(context),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (showDismiss)
                      _buildIconOnFog(
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(maxHeight: 35),
                          icon: const Icon(
                            Icons.close,
                            size: 19,
                            color: Colors.red,
                          ),
                          onPressed: onDismiss,
                        ),
                        spreadRadius: -3,
                      )
                    else
                      const Spacer(),
                    _buildIconOnFog(
                      Icon(
                        type == 'image'
                            ? Icons.camera_alt
                            : type == 'video'
                                ? Icons.videocam
                                : Icons.image_not_supported,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _pushMediaViewScreen(BuildContext context, String? type, Uint8List? data) {
    ImageProvider? imageProvider;
    VideoPlayerController? videoController;

    if (type == 'image') {
      if (data != null) {
        imageProvider = MemoryImage(data);
      } else if (mediaURL != null) {
        imageProvider = NetworkImage(mediaURL!);
      } else if (mediaFile != null) {
        imageProvider = FileImage(mediaFile!);
      }
    } else {
      if (mediaURL != null) {
        videoController = VideoPlayerController.network(mediaURL!);
      } else if (mediaFile != null) {
        videoController = VideoPlayerController.file(mediaFile!);
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaViewScreen(
          imageProvider: imageProvider,
          videoController: videoController,
        ),
      ),
    );
  }

  /// Returns a container with `CircularProgressIndicator`
  Widget _buildLoading() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      width: 100,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Returns a container with an error icon and "Error" underneath it
  Widget _buildError(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      width: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error),
          FittedBox(child: Text(AppLocalizations.of(context)!.error)),
        ],
      ),
    );
  }
}

Widget _buildIconOnFog(Widget icon, {double spreadRadius = 0}) {
  return Container(
    margin: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          spreadRadius: spreadRadius,
          blurRadius: 10,
        ),
      ],
    ),
    child: icon,
  );
}
