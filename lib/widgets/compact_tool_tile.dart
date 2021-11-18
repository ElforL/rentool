import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class CompactToolTile extends StatelessWidget {
  const CompactToolTile({
    Key? key,
    required this.tool,
    this.onTap,
  }) : super(key: key);

  final Tool tool;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    Widget? image;
    if (tool.media.isNotEmpty) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          tool.media.first,
          errorBuilder: (context, error, stackTrace) {
            return FutureBuilder(
              future: VideoThumbnail.thumbnailData(video: tool.media.first),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Image.memory(snapshot.data as Uint8List);
              },
            );
          },
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 150,
          minWidth: 100,
          minHeight: 100,
          maxHeight: 170,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: image ?? const Icon(Icons.image_not_supported),
            ),
            Text(tool.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              AppLocalizations.of(context)!.priceADay(
                AppLocalizations.of(context)!.sar,
                tool.rentPrice.toString(),
              ),
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
