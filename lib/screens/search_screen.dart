import 'package:algolia/algolia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/misc/constants.dart';
import 'package:rentool/screens/post_screen.dart';
import 'package:rentool/widgets/rentool_search_bar.dart';
import 'package:rentool/widgets/tool_tile.dart';
import 'package:rentool/models/rentool/rentool_models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  static const routeName = '/search';

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool readArguments = false;
  late TextEditingController _controller;

  late List<Widget> results;

  final algolia = const Algolia.init(
    applicationId: angoliaAppId,
    apiKey: angoliaApiKey,
  );

  _search() async {
    var searchKey = _controller.text.trim();
    if (searchKey.isEmpty) return;
    var res = await algolia.index('tools').query(searchKey).getObjects();
    results.clear();
    for (var item in res.hits) {
      final widget = _buildResultContainer(item);
      results.add(widget);
    }
    setState(() {});
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
            result,
            const Divider(),
          ],
        ],
      ),
    );
  }

  Widget _buildResultContainer(AlgoliaObjectSnapshot result) {
    Tool tool = Tool.fromJson(
      Map.from(result.data)..addAll({'id': result.objectID}),
    );

    print('Tool: ${tool.toJson()}');

    return ToolTile(
      tool: tool,
      onTap: () {
        Navigator.pushNamed(context, PostScreen.routeName, arguments: tool);
      },
    );
  }
}
