import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/services/storage_services.dart';
import 'package:rentool/widgets/media_tile.dart';

/// Screen to edit or create a new tool
///
/// if [isEditing] is `false` it's used to create a new tool
class EditPostScreen extends StatefulWidget {
  const EditPostScreen({Key? key, this.isEditing = false}) : super(key: key);

  final bool isEditing;

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  Tool? tool;

  final _nameContoller = TextEditingController();
  final _descriptionContoller = TextEditingController();
  final _priceContoller = TextEditingController();
  final _insuranceContoller = TextEditingController();
  final _locationContoller = TextEditingController();

  final List<File> media = [];

  @override
  void dispose() {
    _nameContoller.dispose();
    _descriptionContoller.dispose();
    _priceContoller.dispose();
    _insuranceContoller.dispose();
    _locationContoller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      assert(ModalRoute.of(context)?.settings.arguments != null);
      tool = ModalRoute.of(context)?.settings.arguments as Tool;
      _nameContoller.text = tool!.name;
      _descriptionContoller.text = tool!.description;
      _priceContoller.text = tool!.rentPrice.toString();
      _insuranceContoller.text = tool!.insuranceAmount.toString();
      _locationContoller.text = tool!.location;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.new_post),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            // name
            _buildTextField(
              controller: _nameContoller,
              labelText: AppLocalizations.of(context)!.tool_name,
              textInputAction: TextInputAction.next,
            ),
            // description
            _buildTextField(
              controller: _descriptionContoller,
              labelText: AppLocalizations.of(context)!.description,
              // textInputAction: TextInputAction.next,
              maxLines: 20,
            ),
            Row(
              children: [
                // rentPrice
                Expanded(
                  child: _buildTextField(
                    controller: _priceContoller,
                    labelText: AppLocalizations.of(context)!.rentPrice,
                    textInputAction: TextInputAction.next,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 10),
                // insuranceAmount
                Expanded(
                  child: _buildTextField(
                    controller: _insuranceContoller,
                    labelText: AppLocalizations.of(context)!.insurancePrice,
                    textInputAction: TextInputAction.next,
                    isNumber: true,
                  ),
                ),
              ],
            ),
            // location
            _buildTextField(
              controller: _locationContoller,
              labelText: AppLocalizations.of(context)!.location,
              textInputAction: TextInputAction.done,
            ),

            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 5),
              child: Text(
                AppLocalizations.of(context)!.media,
                style: Theme.of(context)
                    .textTheme
                    .subtitle1!
                    .copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
              ),
            ),
            // media
            MediaTile(
              media: media,
              tool: tool,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    child: Text(AppLocalizations.of(context)!.cancel),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    child: Text(
                        widget.isEditing ? AppLocalizations.of(context)!.edit : AppLocalizations.of(context)!.create),
                    onPressed: () async {
                      if (_nameContoller.text.trim().isEmpty ||
                          _descriptionContoller.text.trim().isEmpty ||
                          _priceContoller.text.trim().isEmpty ||
                          _insuranceContoller.text.trim().isEmpty ||
                          _locationContoller.text.trim().isEmpty) {
                        print('Missing fields');
                        return;
                      }
                      if (widget.isEditing) {
                        tool!.name = _nameContoller.text;
                        tool!.description = _descriptionContoller.text;
                        tool!.rentPrice = double.parse(_priceContoller.text);
                        tool!.insuranceAmount = double.parse(_insuranceContoller.text);
                        tool!.location = _locationContoller.text;

                        final urls = await StorageServices.uploadMediaOfTool(media, tool!.id);
                        tool!.media.addAll(urls);

                        await FirestoreServices.updateTool(tool!);
                      } else {
                        await FirestoreServices.createNewTool(
                          _nameContoller.text.trim(),
                          _descriptionContoller.text.trim(),
                          double.parse(_priceContoller.text.trim()),
                          double.parse(_insuranceContoller.text.trim()),
                          media,
                          _locationContoller.text.trim(),
                        );
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? labelText,
    TextInputAction? textInputAction,
    bool isNumber = false,
    int? maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: controller,
        textInputAction: textInputAction,
        keyboardType: isNumber ? TextInputType.number : null,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}'))] : null,
        minLines: 1,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          filled: true,
        ),
      ),
    );
  }
}
