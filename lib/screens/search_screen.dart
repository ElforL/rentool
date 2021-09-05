import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/logo_image.dart';
import 'package:rentool/widgets/rentool_search_bar.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

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
    print('searching for $searchKey');
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
          textFieldText: _controller.text,
          onSubmitted: (searchText) {
            _controller.text = searchText;
            _search();
          },
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
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

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/post',
          arguments: tool,
        );
      },
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
                  // owner
                  Text(
                    '${AppLocalizations.of(context)!.owner}: ',
                    style: Theme.of(context).textTheme.overline,
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
