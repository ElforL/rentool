import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentool/screens/PostScreen.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _controller;

  List<QueryDocumentSnapshot<Object>> results;

  _search() async {
    var searchKey = _controller.text;
    _controller.text = '';
    var res = await FirestoreServices.searchForTool(searchKey);
    setState(() {
      results = res;
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
                icon: Icon(Icons.search),
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
      Map.from(result.data())..remove('media'),
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
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(),
        ),
        child: Text('${tool.name}: ${tool.rentPrice}'),
      ),
    );
  }
}
