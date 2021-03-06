import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/widgets/logo_image.dart';

class RentoolSearchBar extends StatefulWidget {
  const RentoolSearchBar({
    Key? key,
    this.textFieldContoller,
    this.onSubmitted,
  }) : super(key: key);

  final TextEditingController? textFieldContoller;
  final void Function(String)? onSubmitted;

  @override
  _RentoolSearchBarState createState() => _RentoolSearchBarState();
}

class _RentoolSearchBarState extends State<RentoolSearchBar> {
  late TextEditingController _searchController;
  late FocusNode _searchTfFocusNode;
  bool isSearching = false;

  @override
  void initState() {
    _searchTfFocusNode = FocusNode();
    _searchTfFocusNode.addListener(() {
      setState(() {});
    });
    _searchController = widget.textFieldContoller ?? TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _searchTfFocusNode.dispose();
    if (widget.textFieldContoller == null) _searchController.dispose();
    super.dispose();
  }

  bool get isFocused => _searchTfFocusNode.hasFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            offset: Offset(0.0, 1.0),
            blurRadius: 2.0,
          ),
        ],
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
        color: Colors.white,
      ),
      child: Row(
        children: [
          if (Scaffold.of(context).hasDrawer)
            IconButton(
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            )
          else if (Navigator.of(context).canPop())
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

          Expanded(
            child: TextField(
              focusNode: _searchTfFocusNode,
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: AppLocalizations.of(context)!.search,
                contentPadding: EdgeInsets.zero,
                label: (_searchController.text.isEmpty && !isFocused)
                    ? Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchTfFocusNode.requestFocus();
                            });
                          },
                          child: SizedBox(
                            height: 13,
                            child: LogoImage.primaryTypeface(),
                          ),
                        ),
                      )
                    : null,
              ),
              onSubmitted: widget.onSubmitted,
            ),
          ),

          // ---

          _buildLast()
        ],
      ),
    );
  }

  Widget _buildLast() {
    if (isFocused || _searchController.text.isNotEmpty) {
      return IconButton(
        tooltip: AppLocalizations.of(context)!.cancel,
        icon: const Icon(Icons.close),
        onPressed: () {
          _searchController.clear();
        },
      );
    } else {
      return IconButton(
        tooltip: AppLocalizations.of(context)!.search,
        icon: const Icon(Icons.search),
        onPressed: () {},
      );
    }
  }
}

class RentoolSearchAppBar extends AppBar {
  RentoolSearchAppBar({
    Key? key,
    this.textFieldContoller,
    this.onSubmitted,
  }) : super(key: key);

  final TextEditingController? textFieldContoller;
  final void Function(String)? onSubmitted;

  @override
  _RentoolSearchAppBarState createState() => _RentoolSearchAppBarState();
}

class _RentoolSearchAppBarState extends State<RentoolSearchAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      foregroundColor: Theme.of(context).primaryColor,
      title: RentoolSearchBar(
        textFieldContoller: widget.textFieldContoller,
        onSubmitted: widget.onSubmitted,
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }
}
