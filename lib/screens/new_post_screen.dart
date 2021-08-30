import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/media_tile.dart';

class NewPostScreen extends StatelessWidget {
  NewPostScreen({Key? key}) : super(key: key);

  final _nameContoller = TextEditingController();
  final _descriptionContoller = TextEditingController();
  final _priceContoller = TextEditingController();
  final _insuranceContoller = TextEditingController();
  final _locationContoller = TextEditingController();

  final List<File> media = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            // name
            _buildTextField(
              controller: _nameContoller,
              labelText: 'Tool name',
              textInputAction: TextInputAction.next,
            ),
            // description
            _buildTextField(
              controller: _descriptionContoller,
              labelText: 'Description',
              // textInputAction: TextInputAction.next,
              maxLines: 20,
            ),
            Row(
              children: [
                // rentPrice
                Expanded(
                  child: _buildTextField(
                    controller: _priceContoller,
                    labelText: 'Price',
                    textInputAction: TextInputAction.next,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 10),
                // insuranceAmount
                Expanded(
                  child: _buildTextField(
                    controller: _insuranceContoller,
                    labelText: 'Insurance Price',
                    textInputAction: TextInputAction.next,
                    isNumber: true,
                  ),
                ),
              ],
            ),
            // location
            _buildTextField(
              controller: _locationContoller,
              labelText: 'City/Location',
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
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    child: const Text('CANCEL'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    child: const Text('CREATE'),
                    onPressed: () async {
                      if (_nameContoller.text.trim().isEmpty ||
                          _descriptionContoller.text.trim().isEmpty ||
                          _priceContoller.text.trim().isEmpty ||
                          _insuranceContoller.text.trim().isEmpty ||
                          _locationContoller.text.trim().isEmpty) {
                        print('Missing fields');
                        return;
                      }
                      await FirestoreServices.createNewTool(
                        _nameContoller.text.trim(),
                        _descriptionContoller.text.trim(),
                        double.parse(_priceContoller.text.trim()),
                        double.parse(_insuranceContoller.text.trim()),
                        media,
                        _locationContoller.text.trim(),
                      );
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
