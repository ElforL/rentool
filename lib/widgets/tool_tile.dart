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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: tool.media.isNotEmpty ? Image.network(tool.media.first) : const Icon(Icons.image_not_supported),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tool name
                  Text(
                    tool.name,
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
          ],
        ),
      ),
    );
  }
}
