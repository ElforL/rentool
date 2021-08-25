import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class MediaContainer extends StatelessWidget {
  const MediaContainer({
    Key? key,
    required this.mediaFile,
    required this.showDismiss,
    this.onDismiss,
  }) : super(key: key);

  final File mediaFile;
  final bool showDismiss;
  final void Function()? onDismiss;

  @override
  Widget build(BuildContext context) {
    // get the image bytes as a `Future<Uint8List?>`
    Future<Uint8List?> future;
    var type = lookupMimeType(mediaFile.path)!.split('/')[0];
    if (type == 'image') {
      future = mediaFile.readAsBytes();
    } else if (type == 'video') {
      future = VideoThumbnail.thumbnailData(video: mediaFile.path);
    } else {
      throw Exception('Media type is not an image nor a video: $type.');
    }

    // build using `FutureBuilder`
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FutureBuilder(
          future: Future(() => null),
          builder: (context, snapshot) {
            return FutureBuilder(
              future: future,
              builder: (context, AsyncSnapshot<Uint8List?> snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.data == null) throw Exception('Image bytes were null for file "${mediaFile.path}"');
                return Stack(
                  children: [
                    Image.memory(snapshot.data!),
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
                            type == 'image' ? Icons.camera_alt : Icons.videocam,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
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
