import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/rentool_search_bar.dart';
import 'package:rentool/widgets/tool_tile.dart';
import 'package:rentool/models/rentool/rentool_models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool readArguments = false;
  late TextEditingController _controller;

  late List<QueryDocumentSnapshot<Object>> results;

  _search() async {
    var searchKey = _controller.text;
    var res = await FirestoreServices.searchForTool(searchKey);
    setState(() {
      if (res is List<QueryDocumentSnapshot<Object>>) results = res;
    });
  }

  @override
  void initState() {
    _controller = TextEditingController();
    results = [];

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!readArguments) {
      final searchText = ModalRoute.of(context)?.settings.arguments;
      readArguments = true;
      if (searchText != null && searchText is String) {
        _controller.text = searchText;
        _search();
      }
    }

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Theme.of(context).primaryColor,
        title: RentoolSearchBar(
          textFieldContoller: _controller,
          onSubmitted: (searchText) {
            _controller.text = searchText;
            _search();
          },
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        primary: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              AppLocalizations.of(context)!.results.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          for (var result in results) ...[
            _buildResultContainer(result),
            const Divider(),
          ],
        ],
      ),
    );
  }

  Widget _buildResultContainer(QueryDocumentSnapshot<Object> result) {
    Tool tool = Tool.fromJson(
      Map.from(result.data() as Map<dynamic, dynamic>)..addAll({'id': result.id}),
    );

    return ToolTile(
      tool: tool,
      onTap: () {
        Navigator.pushNamed(context, '/post', arguments: tool);
      },
    );
  }
}
