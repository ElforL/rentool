import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/screens/request_screen.dart';
import 'package:rentool/screens/user_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/media_container.dart';
import 'package:rentool/widgets/rating.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({Key? key}) : super(key: key);

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  RentoolUser? owner;
  late Tool tool;
  ToolRequest? acceptedRequest;
  late PageController _mediaController;
  ToolRequest? userRequest;
  bool loadedUserRequest = false;

  /// returns `true` if the tool belongs to the user (i.e., user = owner).
  bool get isUsersTool => AuthServices.currentUid == tool.ownerUID;

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

  _getRequest() async {
    print('Fetching accepted request: ${tool.acceptedRequestID}');
    var docData = await FirestoreServices.getToolRequest(tool.id, tool.acceptedRequestID);
    if (docData.data() != null) {
      setState(() {
        acceptedRequest = ToolRequest.fromJson(docData.data()!..addAll({'id': docData.id}));
        print('Request ${tool.acceptedRequestID} fetched');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    tool = ModalRoute.of(context)!.settings.arguments as Tool;

    Future<RentoolUser> ownerFuture = owner == null ? FirestoreServices.getUser(tool.ownerUID) : Future.value(owner);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO implement share and url parsing
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              if (isUsersTool) ...[
                PopupMenuItem(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(AppLocalizations.of(context)!.edit),
                    onTap: () => Navigator.of(context).pushReplacementNamed(
                      '/editPost',
                      arguments: tool,
                    ),
                  ),
                ),
                PopupMenuItem(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(AppLocalizations.of(context)!.delete),
                    onTap: () async {
                      if (tool.currentRent != null) {
                        return showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(AppLocalizations.of(context)!.error),
                            content: Text(AppLocalizations.of(context)!.cant_delete_rented_tool + '.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(AppLocalizations.of(context)!.ok),
                              )
                            ],
                          ),
                        );
                      }
                      final isSure = await showConfirmDialog(context);
                      if (isSure ?? false) {
                        FirestoreServices.deleteTool(tool.id);
                        Navigator.of(context).popUntil(ModalRoute.withName('/post'));
                        Navigator.pop(context, 'Deleted');
                      }
                    },
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirestoreServices.getToolStream(tool.id),
        builder: (context, AsyncSnapshot<DocumentSnapshot<Object?>> snapshot) {
          if (snapshot.data != null && snapshot.data!.data() is Map) {
            var map = (snapshot.data!.data() as Map<String, dynamic>)..addAll({'id': snapshot.data!.id});
            tool = Tool.fromJson(map);
            if (tool.acceptedRequestID != null && tool.acceptedRequestID != acceptedRequest?.id) {
              _getRequest();
            }
          }
          return ListView(
            primary: false,
            children: [
              // media
              _buildMediaList(context),
              const Divider(thickness: 1, height: 2),
              // Tool info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tool name
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SelectableText(
                        tool.name,
                        style: Theme.of(context).textTheme.headline5!.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Tool info
                    RichText(
                      text: TextSpan(
                          text: '${AppLocalizations.of(context)!.price}: ',
                          style: Theme.of(context).textTheme.bodyText1!.apply(color: Colors.grey.shade600),
                          children: [
                            TextSpan(
                              text: AppLocalizations.of(context)!.priceADay(
                                AppLocalizations.of(context)!.sar,
                                tool.rentPrice.toString(),
                              ),
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ]),
                    ),
                    const SizedBox(height: 5),
                    RichText(
                      text: TextSpan(
                          text: '${AppLocalizations.of(context)!.status}: ',
                          style: Theme.of(context).textTheme.bodyText1!.apply(color: Colors.grey.shade600),
                          children: [
                            TextSpan(
                              text: tool.isAvailable
                                  ? AppLocalizations.of(context)!.available
                                  : AppLocalizations.of(context)!.notAvailable,
                              style: TextStyle(color: tool.isAvailable ? Colors.green : Colors.red),
                            ),
                          ]),
                    ),
                    const SizedBox(height: 5),
                    RichText(
                      text: TextSpan(
                          text: '${AppLocalizations.of(context)!.location}: ',
                          style: Theme.of(context).textTheme.bodyText1!.apply(color: Colors.grey.shade600),
                          children: [
                            TextSpan(
                              text: tool.location,
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                          ]),
                    ),
                    const SizedBox(height: 5),
                    FutureBuilder(
                      future: ownerFuture,
                      builder: (context, AsyncSnapshot<RentoolUser> snapshot) {
                        owner = snapshot.data;
                        if (owner == null) {
                          return const LinearProgressIndicator();
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            final result = await Navigator.of(context).pushNamed(
                              '/user',
                              arguments: UserScreenArguments(user: owner),
                            );
                            if (result is RentoolUser) {
                              setState(() {
                                owner = result;
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)!.owner}: ',
                                  style: Theme.of(context).textTheme.bodyText1!.apply(color: Colors.grey.shade600),
                                ),
                                Text(
                                  owner!.name,
                                  style: Theme.of(context).textTheme.bodyText2,
                                ),
                                const Spacer(),
                                Text(
                                  owner!.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                ...RatingDisplay.getStarsIcons(
                                  owner!.rating,
                                  iconSize: 20,
                                  fullColor: Colors.orange.shade700,
                                  emptyColor: Colors.orange.shade700,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    _buildMainButton(context),
                    ..._buildMeetingButtons(context),
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
                      AppLocalizations.of(context)!.description,
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(fontWeight: FontWeight.bold),
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

  List<Widget> _buildMeetingButtons(BuildContext context) {
    bool isUserAuthorized =
        acceptedRequest?.renterUID == AuthServices.currentUid || tool.ownerUID == AuthServices.currentUid;
    return [
      if (tool.acceptedRequestID != null && isUserAuthorized && tool.currentRent == null)
        SizedBox(
          width: 100,
          child: ElevatedButton(
            child: Text(AppLocalizations.of(context)!.deliver.toUpperCase()),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/deliver',
                arguments: tool,
              );
            },
          ),
        ),
      if (tool.currentRent != null && isUserAuthorized)
        SizedBox(
          width: 100,
          child: ElevatedButton(
            child: Text(AppLocalizations.of(context)!.returnn.toUpperCase()),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/return',
                arguments: tool,
              );
            },
          ),
        ),
    ];
  }

  Future<ToolRequest?> _getUserRequest() async {
    if (loadedUserRequest) return userRequest;
    loadedUserRequest = true;
    final result = await FirestoreServices.getUserToolRequest(tool.id, AuthServices.currentUid!);
    if (result.docs.isNotEmpty) {
      final doc = result.docs.first;
      final request = ToolRequest.fromJson(doc.data()..addAll({'id': doc.id}));
      return request;
    } else {
      return null;
    }
  }

  Widget _buildMainButton(BuildContext context) {
    if (isUsersTool) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.send_and_archive_rounded),
        label: Text(AppLocalizations.of(context)!.browseRequests.toUpperCase()),
        onPressed: () => Navigator.pushNamed(context, '/toolsRequests', arguments: tool),
      );
    } else {
      return FutureBuilder(
        future: userRequest != null ? Future.value(userRequest) : _getUserRequest(),
        builder: (context, AsyncSnapshot<ToolRequest?> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LinearProgressIndicator();
          }

          userRequest = snapshot.data;

          if (userRequest == null) {
            return ElevatedButton.icon(
              icon: const Icon(Icons.shopping_cart),
              label: Text(AppLocalizations.of(context)!.request.toUpperCase()),
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/newRequest', arguments: tool);
                if (result is ToolRequest) {
                  setState(() {
                    userRequest = result;
                  });
                }
              },
            );
          } else {
            return ElevatedButton(
              child: Text(AppLocalizations.of(context)!.my_request.toUpperCase()),
              onPressed: () async {
                final request = await Navigator.of(context).pushNamed(
                  '/request',
                  arguments: RequestScreenArguments(userRequest!, false),
                );
                if (request == 'Deleted') {
                  setState(() {
                    userRequest = null;
                  });
                }
              },
            );
          }
        },
      );
    }
  }

  Container _buildMediaList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      constraints: const BoxConstraints(maxHeight: 200),
      child: Stack(
        children: [
          PageView(
            controller: _mediaController,
            scrollDirection: Axis.horizontal,
            children: [
              if (tool.media.isNotEmpty)
                for (var url in tool.media)
                  Center(
                    child: MediaContainer(
                      mediaURL: url,
                      showDismiss: false,
                    ),
                  )
              else
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.noPicsOrVids,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ),
            ],
          ),
          if (tool.media.isNotEmpty)
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
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                IconButton(
                  onPressed: () {
                    _mediaController.nextPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.ease,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            )
        ],
      ),
    );
  }
}
