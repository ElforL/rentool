import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReviewsFilterChips extends StatefulWidget {
  const ReviewsFilterChips({
    Key? key,
    required this.selected,
    this.onChange,
  }) : super(key: key);

  final ReviewFilter selected;
  final void Function(ReviewFilter selected)? onChange;

  @override
  State<ReviewsFilterChips> createState() => _ReviewsFilterChipsState();
}

class _ReviewsFilterChipsState extends State<ReviewsFilterChips> {
  late ReviewFilter selected;

  _setSelected(ReviewFilter newVal) {
    selected = newVal;
    if (widget.onChange != null) {
      widget.onChange!(selected);
    }
  }

  @override
  void initState() {
    selected = widget.selected;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All chip
          _buildChip(
            (val) => _setSelected(ReviewFilter.all),
            selected == ReviewFilter.all,
            true,
          ),
          for (var i = 1; i <= 5; i++)
            _buildChip(
              (val) => _setSelected(ReviewFilter.values[i]),
              selected == ReviewFilter.values[i],
              false,
              number: i,
            ),
        ],
      ),
    );
  }

  Widget _buildChip(
    void Function(bool)? onSelected,
    bool selected,
    bool isAll, {
    int? number,
  }) {
    if (!isAll) assert(number != null);
    Widget label;
    if (isAll) {
      label = Text(
        AppLocalizations.of(context)!.all,
        style: TextStyle(
          color: selected ? Colors.blue.shade900 : Colors.black45,
        ),
      );
    } else {
      label = Row(
        children: [
          Text(
            number.toString(),
            style: TextStyle(color: selected ? Colors.blue.shade900 : Colors.black45),
          ),
          Icon(Icons.star, size: 14, color: selected ? Colors.blue.shade900 : Colors.black45),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: FilterChip(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        selected: selected,
        label: label,
        backgroundColor: Colors.transparent,
        selectedColor: Colors.blue.withAlpha(50),
        checkmarkColor: Colors.blue.shade900,
        shape: !selected ? const StadiumBorder(side: BorderSide(color: Colors.black26)) : null,
        onSelected: onSelected,
      ),
    );
  }
}

enum ReviewFilter {
  all,
  stars_1,
  stars_2,
  stars_3,
  stars_4,
  stars_5,
}
