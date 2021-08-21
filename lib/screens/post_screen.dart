import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentool/screens/deliver_meet_screen.dart';
import 'package:rentool/screens/new_request_screen.dart';
import 'package:rentool/screens/requests_list_screen.dart';
import 'package:rentool/screens/return_meet_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({Key? key}) : super(key: key);

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  late Tool tool;
  late PageController _mediaController;

  /// returns `true` if the tool belongs to the user (i.e., user = owner).
  bool get isUsersTool => AuthServices.auth.currentUser!.uid == tool.ownerUID;

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
    tool = ModalRoute.of(context)!.settings.arguments as Tool;
    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder(
        stream: FirestoreServices.getToolStream(tool.id),
        builder: (context, AsyncSnapshot<DocumentSnapshot<Object?>> snapshot) {
          if (snapshot.data != null && snapshot.data!.data() is Map) {
            var map = (snapshot.data!.data() as Map<String, dynamic>)..addAll({'id': snapshot.data!.id});
            tool = Tool.fromJson(map);
          }
          return ListView(
            children: [
              // media
              Container(
                margin: const EdgeInsets.only(top: 5),
                constraints: const BoxConstraints(maxHeight: 200),
                child: Stack(
                  children: [
                    PageView(
                      controller: _mediaController,
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (tool.media.isNotEmpty)
                          for (var url in tool.media) Image.network(url)
                        else
                          const Center(
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
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.ease,
                            );
                          },
                          icon: const Icon(Icons.keyboard_arrow_left),
                        ),
                        IconButton(
                          onPressed: () {
                            _mediaController.nextPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.ease,
                            );
                          },
                          icon: const Icon(Icons.keyboard_arrow_right),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const Divider(thickness: 1, height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SelectableText(
                        tool.name,
                        style: Theme.of(context).textTheme.headline5!.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          'Price: ',
                          style: Theme.of(context).textTheme.bodyText1!.apply(color: Colors.grey.shade600),
                        ),
                        Text(
                          'SAR ' + tool.rentPrice.toString() + '/day',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          'Status: ',
                          style: Theme.of(context).textTheme.bodyText1!.apply(color: Colors.grey.shade600),
                        ),
                        Text(
                          (tool.isAvailable ? '' : 'Not ') + 'Available',
                          style: TextStyle(color: tool.isAvailable ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          'Location: ',
                          style: Theme.of(context).textTheme.bodyText1!.apply(color: Colors.grey.shade600),
                        ),
                        Text(tool.location),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          'Owner: ',
                          style: Theme.of(context).textTheme.bodyText1!.apply(color: Colors.grey.shade600),
                        ),
                        Text(tool.ownerUID),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ElevatedButton.icon(
                      icon: Icon(isUsersTool ? Icons.list_rounded : Icons.shopping_cart),
                      label: Text(isUsersTool ? 'VIEW REQUESTS' : 'REQUEST'),
                      onPressed: isUsersTool
                          ? /* widget.tool.acceptedRequestID != null
                              ? null
                              : */
                          () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => RequestsListScreen(tool: tool)),
                              )
                          : (!tool.isAvailable
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => NewRequestScreen(tool: tool),
                                    ),
                                  );
                                }),
                    ),
                    if (tool.acceptedRequestID != null)
                      ElevatedButton(
                        child: const Text('Meet'),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/deliver',
                            arguments: tool,
                          );
                        },
                      ),
                    if (tool.currentRent != null)
                      ElevatedButton(
                        child: const Text('Return'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ReturnMeetScreen(tool: tool),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ), // end of main details
              const Divider(thickness: 1),
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.subtitle2,
                    ),
                    const SizedBox(height: 15),
                    SelectableText(tool.description),
                  ],
                ),
              ), // end of Description
              const Divider(thickness: 1),
            ],
          );
        },
      ),
    );
  }
}
