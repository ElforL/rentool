import 'package:flutter/material.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class PostScreen extends StatefulWidget {
  PostScreen({Key key, @required this.tool}) : super(key: key);

  final Tool tool;

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  PageController _mediaController;

  @override
  void initState() {
    _mediaController = PageController();
    super.initState();
  }

  @override
  void dispose() {
    _mediaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          // media
          Container(
            margin: const EdgeInsets.only(top: 5),
            constraints: BoxConstraints(maxHeight: 200),
            child: Stack(
              children: [
                PageView(
                  controller: _mediaController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (widget.tool.media != null && widget.tool.media.isNotEmpty)
                      for (var url in widget.tool.media) Image.network(url)
                    else
                      Center(
                        child: Text('No media'),
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IconButton(
                      onPressed: () {
                        _mediaController.previousPage(
                          duration: Duration(milliseconds: 200),
                          curve: Curves.ease,
                        );
                      },
                      icon: Icon(Icons.arrow_left),
                    ),
                    IconButton(
                      onPressed: () {
                        _mediaController.nextPage(
                          duration: Duration(milliseconds: 200),
                          curve: Curves.ease,
                        );
                      },
                      icon: Icon(Icons.arrow_right),
                    ),
                  ],
                )
              ],
            ),
          ),
          Divider(thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  widget.tool.name,
                  style: Theme.of(context).textTheme.headline5.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      'Price: ',
                      style: Theme.of(context).textTheme.bodyText1.apply(color: Colors.grey.shade600),
                    ),
                    Text(
                      'SAR ' + widget.tool.rentPrice.toString() + '/day',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: Theme.of(context).textTheme.bodyText1.apply(color: Colors.grey.shade600),
                    ),
                    Text(
                      (widget.tool.isAvailable ? '' : 'Not ') + 'Available',
                      style: TextStyle(color: widget.tool.isAvailable ? Colors.green : Colors.red),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      'Location: ',
                      style: Theme.of(context).textTheme.bodyText1.apply(color: Colors.grey.shade600),
                    ),
                    Text(widget.tool.location),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      'Owner: ',
                      style: Theme.of(context).textTheme.bodyText1.apply(color: Colors.grey.shade600),
                    ),
                    Text(widget.tool.ownerUID),
                    // TODO owner rating
                  ],
                ),
                SizedBox(height: 5),
                ElevatedButton.icon(
                  icon: Icon(Icons.shopping_cart),
                  label: Text('Request'),
                  onPressed: !widget.tool.isAvailable ? null : () {},
                ),
              ],
            ),
          ), // end of main details
          Divider(thickness: 1),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                SizedBox(height: 15),
                SelectableText(widget.tool.description),
              ],
            ),
          ), // end of Description
          Divider(thickness: 1),
        ],
      ),
    );
  }
}
