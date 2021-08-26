import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
              ),
              const Divider(thickness: 1, height: 2),
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
                    Row(
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.price}: ',
                          style: Theme.of(context).textTheme.bodyText1!.apply(color: Colors.grey.shade600),
                        ),
                        Text(
                          AppLocalizations.of(context)!.priceADay(
                            AppLocalizations.of(context)!.sar,
                            tool.rentPrice.toString(),
                          ),
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.status}: ',
                          style: Theme.of(context).textTheme.bodyText1!.apply(color: Colors.grey.shade600),
                        ),
                        Text(
                          tool.isAvailable
                              ? AppLocalizations.of(context)!.available
                              : AppLocalizations.of(context)!.notAvailable,
                          style: TextStyle(color: tool.isAvailable ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.location}: ',
                          style: Theme.of(context).textTheme.bodyText1!.apply(color: Colors.grey.shade600),
                        ),
                        Text(tool.location),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // TODO crerate future builder to read owner info from `db/Users`
                    Row(
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.owner}: ',
                          style: Theme.of(context).textTheme.bodyText1!.apply(color: Colors.grey.shade600),
                        ),
                        Text(tool.ownerUID),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ElevatedButton.icon(
                      icon: Icon(isUsersTool ? Icons.list_rounded : Icons.shopping_cart),
                      label: Text(
                        (isUsersTool
                                ? AppLocalizations.of(context)!.browseRequests
                                : AppLocalizations.of(context)!.request)
                            .toUpperCase(),
                      ),
                      onPressed: isUsersTool
                          ? /* widget.tool.acceptedRequestID != null
                              ? null
                              : */
                          () => Navigator.pushNamed(
                                context,
                                '/toolsRequests',
                                arguments: tool,
                              )
                          : (!tool.isAvailable
                              ? null
                              : () {
                                  Navigator.pushNamed(
                                    context,
                                    '/newRequest',
                                    arguments: tool,
                                  );
                                }),
                    ),
                    if (tool.acceptedRequestID != null)
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          child: const Text('Meet'),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/deliver',
                              arguments: tool,
                            );
                          },
                        ),
                      ),
                    if (tool.currentRent != null)
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          child: const Text('Return'),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/return',
                              arguments: tool,
                            );
                          },
                        ),
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
}
