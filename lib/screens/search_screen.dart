import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentool/screens/post_screen.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _controller;

  late List<QueryDocumentSnapshot<Object>> results;

  _search() async {
    var searchKey = _controller.text;
    _controller.text = '';
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
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _search(),
                ),
              ),
              IconButton(
                onPressed: () => _search(),
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          for (var result in results) _buildResultContainer(result)
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostScreen(tool: tool),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(),
        ),
        child: Text('${tool.name}: ${tool.rentPrice}'),
      ),
    );
  }
}
