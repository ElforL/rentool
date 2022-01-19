import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/localization/cities_localization.dart';
import 'package:rentool/misc/constants.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/screens/chat_screen.dart';
import 'package:rentool/screens/deliver_meet_screen.dart';
import 'package:rentool/screens/edit_post_screen.dart';
import 'package:rentool/screens/new_request_screen.dart';
import 'package:rentool/screens/request_screen.dart';
import 'package:rentool/screens/requests_list_screen.dart';
import 'package:rentool/screens/return_meet_screen.dart';
import 'package:rentool/screens/user_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/media_container.dart';
import 'package:rentool/widgets/rating.dart';
import 'package:share_plus/share_plus.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({Key? key}) : super(key: key);

  static const routeName = '/post';

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
    debugPrint('Fetching accepted request: ${tool.acceptedRequestID}');
    var docData = await FirestoreServices.getToolRequest(tool.id, tool.acceptedRequestID);
    if (docData.data() != null) {
      setState(() {
        acceptedRequest = ToolRequest.fromJson(docData.data()!..addAll({'id': docData.id}));
        debugPrint('Request ${tool.acceptedRequestID} fetched');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    tool = ModalRoute.of(context)!.settings.arguments as Tool;

    return Scaffold(
      appBar: AppBar(
        actions: tool.rentPrice <= 0
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    Share.share(AppLocalizations.of(context)!.sharePostText(
                      tool.name,
                      '$siteDomain${PostScreen.routeName}/${tool.id}',
                    ));
                  },
                ),
                PopupMenuButton(
                  tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                  itemBuilder: (context) => [
                    if (AuthServices.isAdmin)
                      PopupMenuItem(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          trailing: const Icon(Icons.send_and_archive_rounded),
                          title: Text(AppLocalizations.of(context)!.browseRequests.toUpperCase()),
                          onTap: () => Navigator.pushNamed(context, RequestsListScreen.routeName, arguments: tool),
                        ),
                      ),
                    if (isUsersTool || AuthServices.isAdmin) ...[
                      PopupMenuItem(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          title: Text(AppLocalizations.of(context)!.edit),
                          onTap: () => Navigator.of(context).pushReplacementNamed(
                            EditPostScreen.routeNameEdit,
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
                              Navigator.of(context)
                                  .popUntil((route) => route.settings.name?.startsWith(PostScreen.routeName) ?? false);
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
            if (tool.acceptedRequestID == null && acceptedRequest != null) {
              acceptedRequest = null;
            }
          }

          if (snapshot.connectionState == ConnectionState.active && !(snapshot.data?.exists ?? true)) {
            return _build404(snapshot);
          }

          Future<RentoolUser?> ownerFuture;
          if (owner == null) {
            if (tool.ownerUID == '...') {
              ownerFuture = Future.value(null);
            } else {
              debugPrint('Call Firestore');
              ownerFuture = FirestoreServices.getUser(tool.ownerUID);
            }
          } else {
            ownerFuture = Future.value(owner);
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
                              text: CityLocalization.cityName(
                                tool.location,
                                AppLocalizations.of(context)!.localeName,
                              ),
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                          ]),
                    ),
                    const SizedBox(height: 5),
                    FutureBuilder(
                      future: ownerFuture,
                      builder: (context, AsyncSnapshot<RentoolUser?> snapshot) {
                        owner = snapshot.data;
                        if (owner == null) {
                          return const LinearProgressIndicator();
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () async {
                            final result = await Navigator.of(context).pushNamed(
                              UserScreen.routeName,
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
                    _buildMeetingButtons(context),
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

  Center _build404(AsyncSnapshot<DocumentSnapshot<Object?>> snapshot) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Text(
            '404',
            style: Theme.of(context).textTheme.headline1?.copyWith(fontFamily: 'Roboto', fontWeight: FontWeight.w100),
          ),
          Text(
            AppLocalizations.of(context)!.couldnt_find_tool,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 150),
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.back.toUpperCase()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingButtons(BuildContext context) {
    bool isUserAuthorized =
        acceptedRequest?.renterUID == AuthServices.currentUid || tool.ownerUID == AuthServices.currentUid;
    return Wrap(
      children: [
        if (acceptedRequest != null && isUserAuthorized) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: Text(AppLocalizations.of(context)!.chat_with_role(isUsersTool ? 'renter' : 'owner').toUpperCase()),
            onPressed: () {
              Navigator.of(context).pushNamed(
                ChatScreen.routeName,
                arguments: ChatScreenArguments(
                  acceptedRequest!,
                  isUsersTool ? acceptedRequest!.renterUID : tool.ownerUID,
                  otherUser: isUsersTool ? null : owner,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
        if (!kIsWeb && tool.acceptedRequestID != null && isUserAuthorized && tool.currentRent == null)
          SizedBox(
            width: 100,
            child: ElevatedButton(
              child: Text(AppLocalizations.of(context)!.deliver.toUpperCase()),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  DeliverMeetScreen.routeName,
                  arguments: tool,
                );
              },
            ),
          ),
        if (!kIsWeb && tool.currentRent != null && isUserAuthorized)
          SizedBox(
            width: 100,
            child: ElevatedButton(
              child: Text(AppLocalizations.of(context)!.returnn.toUpperCase()),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  ReturnMeetScreen.routeName,
                  arguments: tool,
                );
              },
            ),
          ),
      ],
    );
  }

  Future<ToolRequest?> _getUserRequest() async {
    if (AuthServices.currentUser == null) return null;
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
        onPressed: () => Navigator.pushNamed(context, RequestsListScreen.routeName, arguments: tool),
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
              onPressed: tool.isAvailable
                  ? () async {
                      if (AuthServices.currentUser == null) {
                        Navigator.of(context).pushNamed('/', arguments: true);
                      }
                      if (!AuthServices.currentUser!.emailVerified) {
                        showEmailNotVerifiedDialog(context);
                        return;
                      }
                      if (FirestoreServices.hasId != true) {
                        showIdMissingDialog(context);
                        return;
                      }
                      if (FirestoreServices.hasCard != true) {
                        showMissingCardDialog(context);
                        return;
                      }
                      final result = await Navigator.pushNamed(context, NewRequestScreen.routeName, arguments: tool);
                      if (result is ToolRequest) {
                        setState(() {
                          userRequest = result;
                        });
                      }
                    }
                  : null,
            );
          } else {
            return ElevatedButton(
              child: Text(AppLocalizations.of(context)!.my_request.toUpperCase()),
              onPressed: () async {
                final request = await Navigator.of(context).pushNamed(
                  RequestScreen.routeName,
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
                for (var url in tool.media) MediaContainerPage(url: url)
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

class MediaContainerPage extends StatefulWidget {
  const MediaContainerPage({
    Key? key,
    required this.url,
  }) : super(key: key);

  final String url;

  @override
  State<MediaContainerPage> createState() => _MediaContainerPageState();
}

class _MediaContainerPageState extends State<MediaContainerPage>
    with AutomaticKeepAliveClientMixin<MediaContainerPage> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: MediaContainer(
        mediaURL: widget.url,
        showDismiss: false,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
