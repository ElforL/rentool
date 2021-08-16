import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class _RentoolSearchBar extends StatefulWidget {
  const _RentoolSearchBar({Key? key}) : super(key: key);

  @override
  _RentoolSearchBarState createState() => _RentoolSearchBarState();
}

class _RentoolSearchBarState extends State<_RentoolSearchBar> {
  late TextEditingController _searchController;
  late FocusNode _searchTfFocusNode;
  bool isSearching = false;

  @override
  void initState() {
    _searchTfFocusNode = FocusNode();
    _searchTfFocusNode.addListener(() {
      setState(() {});
    });
    _searchController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _searchTfFocusNode.dispose();
    _searchController.dispose();
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
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),

          // ---
          if (_searchController.text.isEmpty)
            Expanded(
              child: TextField(
                focusNode: _searchTfFocusNode,
                controller: _searchController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: AppLocalizations.of(context)!.search,
                ),
              ),
            )
          else
            Expanded(
              child: SizedBox(
                height: 13,
                child: Image.asset('assets/images/Logo/primary_typeface.png'),
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
        icon: const Icon(Icons.close),
        onPressed: () {},
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {},
      );
    }
  }
}

class RentoolSearchAppBar extends AppBar {
  RentoolSearchAppBar({Key? key}) : super(key: key);

  @override
  _RentoolSearchAppBarState createState() => _RentoolSearchAppBarState();
}

class _RentoolSearchAppBarState extends State<RentoolSearchAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      foregroundColor: Theme.of(context).primaryColor,
      title: const _RentoolSearchBar(),
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }
}
