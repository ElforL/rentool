import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/services/storage_services.dart';
import 'package:rentool/widgets/location_dropdown.dart';
import 'package:rentool/widgets/media_tile.dart';

/// Screen to edit or create a new tool
///
/// if [isEditing] is `false` it's used to create a new tool
class EditPostScreen extends StatefulWidget {
  const EditPostScreen({Key? key, this.isEditing = false}) : super(key: key);

  static const routeNameNew = '/newPost';
  static const routeNameEdit = '/editPost';

  final bool isEditing;

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  Tool? tool;

  bool argsRead = false;
  final _nameContoller = TextEditingController();
  final _descriptionContoller = TextEditingController();
  final _priceContoller = TextEditingController();
  final _insuranceContoller = TextEditingController();
  String _location = '';
  bool? _isAvailable;

  String? _nameErrorText;
  String? _descriptionErrorText;
  String? _rentPriceErrorText;
  String? _insuranceErrorText;
  String? _locationErrorText;

  final List<File> media = [];

  @override
  void dispose() {
    _nameContoller.dispose();
    _descriptionContoller.dispose();
    _priceContoller.dispose();
    _insuranceContoller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing && !argsRead) {
      assert(ModalRoute.of(context)?.settings.arguments != null);
      tool = ModalRoute.of(context)?.settings.arguments as Tool;
      _nameContoller.text = tool!.name;
      _descriptionContoller.text = tool!.description;
      _priceContoller.text = tool!.rentPrice.toString();
      _insuranceContoller.text = tool!.insuranceAmount.toString();
      _location = tool!.location;
      _isAvailable = tool!.isAvailable;
      argsRead = true;
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
              errorText: _nameErrorText,
            ),
            // description
            _buildTextField(
              controller: _descriptionContoller,
              labelText: AppLocalizations.of(context)!.description,
              maxLines: 20,
              errorText: _descriptionErrorText,
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
                    errorText: _rentPriceErrorText,
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
                    errorText: _insuranceErrorText,
                  ),
                ),
              ],
            ),
            // location
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.location),
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.all(5),
              child: LocationDropDown(
                value: _location,
                onChanged: (city) => _location = city ?? '',
                errorText: _locationErrorText,
              ),
            ),

            if (widget.isEditing)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 3),
                  title: Text(AppLocalizations.of(context)!.allow_rent_requests),
                  subtitle: Text(_isAvailable!
                      ? AppLocalizations.of(context)!.available
                      : AppLocalizations.of(context)!.notAvailable),
                  trailing: Switch(
                    value: _isAvailable!,
                    onChanged: (val) {
                      setState(() {
                        _isAvailable = val;
                      });
                    },
                  ),
                ),
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
                      bool hasError = false;
                      if (_nameContoller.text.trim().isEmpty) {
                        _nameErrorText = AppLocalizations.of(context)!.you_cant_leave_this_empty;
                        hasError = true;
                      }
                      if (_descriptionContoller.text.trim().isEmpty) {
                        _descriptionErrorText = AppLocalizations.of(context)!.you_cant_leave_this_empty;
                        hasError = true;
                      }
                      if (_priceContoller.text.trim().isEmpty) {
                        _rentPriceErrorText = AppLocalizations.of(context)!.you_cant_leave_this_empty;
                        hasError = true;
                      } else if (double.parse(_priceContoller.text) <= 0) {
                        _rentPriceErrorText = AppLocalizations.of(context)!.rent_price_must_greater_than_zero;
                        hasError = true;
                      }
                      if (_insuranceContoller.text.trim().isEmpty) {
                        _insuranceErrorText = AppLocalizations.of(context)!.you_cant_leave_this_empty;
                        hasError = true;
                      } else if (double.parse(_insuranceContoller.text) <= 0) {
                        _insuranceErrorText = AppLocalizations.of(context)!.insurance_must_greater_than_zero;
                        hasError = true;
                      }
                      if (_location.trim().isEmpty) {
                        _locationErrorText = AppLocalizations.of(context)!.you_cant_leave_this_empty;
                        hasError = true;
                      }
                      if (hasError) {
                        setState(() {});
                        return;
                      }

                      showCircularLoadingIndicator(context);
                      if (widget.isEditing) {
                        tool!.name = _nameContoller.text.trim();
                        tool!.description = _descriptionContoller.text.trim();
                        tool!.rentPrice = double.parse(_priceContoller.text);
                        tool!.insuranceAmount = double.parse(_insuranceContoller.text);
                        tool!.location = _location.trim();
                        tool!.isAvailable = _isAvailable ?? tool!.isAvailable;

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
                          _location.trim(),
                        );
                      }
                      // Pop the loading indicator
                      Navigator.pop(context);
                      // Pop the page
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
    String? errorText,
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
          errorText: errorText,
        ),
      ),
    );
  }
}
