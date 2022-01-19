import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/rentool/rentool_models.dart';

class ToolTile extends StatelessWidget {
  const ToolTile({
    Key? key,
    required this.tool,
    this.onTap,
  }) : super(key: key);

  final Tool tool;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    Widget? image;
    if (tool.media.isNotEmpty) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: tool.media.first,
          fit: BoxFit.cover,
          errorWidget: (context, string, obj) {
            return const Center(
              child: Icon(Icons.error_outline),
            );
          },
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: image ?? const Icon(Icons.image_not_supported),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: size.width >= 960
                  ? 9
                  : size.width >= 500
                      ? 4
                      : 2,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tool name
                      Text(
                        tool.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      // price
                      Text(
                        AppLocalizations.of(context)!.priceADay(
                          AppLocalizations.of(context)!.sar,
                          tool.rentPrice.toString(),
                        ),
                        style: Theme.of(context).textTheme.caption,
                      ),
                      // available
                      Text(
                        tool.isAvailable
                            ? AppLocalizations.of(context)!.available
                            : AppLocalizations.of(context)!.notAvailable,
                        style: TextStyle(
                          color: tool.isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
