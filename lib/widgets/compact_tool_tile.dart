import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/rentool/rentool_models.dart';

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
              child: _image(),
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

  Widget _image() {
    if (tool.media.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: tool.media.first,
          fit: BoxFit.cover,
          placeholder: (context, string) {
            return const Center(child: CircularProgressIndicator());
          },
        ),
      );
    } else {
      return const Icon(Icons.image_not_supported);
    }
  }
}
