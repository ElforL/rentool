import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _searchController = TextEditingController();

  Size get _size => MediaQuery.of(context).size;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_size.width > 530)
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text('Rentool'),
              ),
            Flexible(
              child: Center(
                child: buildSearchBar(),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            iconSize: 30,
            splashRadius: 20,
            icon: Icon(Icons.language),
            onPressed: () {
              // ChangeLanguage
            },
          ),
          IconButton(
            iconSize: 30,
            splashRadius: 20,
            icon: CircleAvatar(),
            onPressed: () {},
          ),
          SizedBox(width: 20),
        ],
      ),
      body: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text('${kIsWeb ? "web" : "notWeb"} $defaultTargetPlatform'),
          );
        },
      ),
    );
  }

  Container buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.blue[300],
      ),
      width: 500,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          icon: Icon(Icons.search),
          border: InputBorder.none,
        ),
      ),
    );
  }
}