import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/localization/cities_localization.dart';

// ignore: must_be_immutable
class LocationDropDown extends StatefulWidget {
  LocationDropDown({
    Key? key,
    required this.value,
    this.onChanged,
    this.errorText,
  }) : super(key: key);

  final String value;
  final Function(String? city)? onChanged;
  String? errorText;

  @override
  State<LocationDropDown> createState() => _LocationDropDownState();
}

class _LocationDropDownState extends State<LocationDropDown> {
  static const _otherCityValue = '_OTHER_';
  final _otherCityController = TextEditingController();
  String? value;

  @override
  void initState() {
    if (widget.value == '') {
      value = null;
    } else if (CityLocalization.hasCity(widget.value)) {
      value = widget.value;
    } else {
      value = _otherCityValue;
      _otherCityController.text = widget.value;
    }
    super.initState();
  }

  @override
  void dispose() {
    _otherCityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cities = CityLocalization.cities(AppLocalizations.of(context)!.localeName);
    final entries = cities.entries.toList()..sort((a, b) => a.value.compareTo(b.value));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value: value,
          hint: Text(AppLocalizations.of(context)!.choose_a_city),
          menuMaxHeight: 400,
          // isExpanded: true,
          items: [
            for (var entry in entries)
              DropdownMenuItem(
                child: Text(entry.value),
                value: entry.key,
              ),
            DropdownMenuItem(
              child: Text(AppLocalizations.of(context)!.other),
              value: _otherCityValue,
            ),
          ],
          onChanged: (newValue) {
            widget.errorText = null;
            setState(() {
              value = newValue;
            });
            // if [newValue == _otherCityValue] then we don't want the tool's location to be set to _otherCityValue ('_OTHER_')
            // instead, [widget.onChanged()] will be called from [textField.onChanged()]
            if (widget.onChanged != null && newValue != _otherCityValue) {
              widget.onChanged!(newValue);
            }
          },
        ),
        if (value == _otherCityValue)
          TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enter_the_location,
              errorText: widget.errorText,
            ),
            controller: _otherCityController,
            onChanged: (newValue) {
              if (widget.errorText != null) {
                setState(() {
                  widget.errorText = null;
                });
              }
              if (widget.onChanged != null) widget.onChanged!(newValue);
            },
          )
        else if (widget.errorText != null)
          Text(
            widget.errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
