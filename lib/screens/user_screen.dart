import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/screens/reviews_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/loading_indicator.dart';
import 'package:rentool/widgets/rate_user.dart';
import 'package:rentool/widgets/rating.dart';
import 'package:rentool/widgets/tool_tile.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  RentoolUser? user;
  final _scrollController = ScrollController();

  /// is loading from Firestore?
  ///
  /// used to prevent multiple calls for Firestore.
  bool isLoadingTools = false;

  /// there is no more docs other than the one loaded
  ///
  /// defaults to `false` and turns `true` when [_getTools()] doesn't return any docs
  bool noMoreToolsDocs = false;
  List<Tool> tools = [];
  DocumentSnapshot<Object?>? previousToolDoc;

  Future<void> _getTools() async {
    if (isLoadingTools) return;
    isLoadingTools = true;
    final result = await FirestoreServices.getUserTool(user!.uid, previousDoc: previousToolDoc);
    if (result.docs.isEmpty) {
      noMoreToolsDocs = true;
    } else {
      for (var doc in result.docs) {
        final tool = Tool.fromJson((doc.data() as Map<String, dynamic>)..addAll({'id': doc.id}));
        tools.add(tool);
      }
      previousToolDoc = result.docs.last;
    }
    isLoadingTools = false;
  }

  Future<void> _refresh() async {
    user = await FirestoreServices.getUser(user!.uid);
    setState(() {
      tools.clear();
      noMoreToolsDocs = false;
      previousToolDoc = null;
      tools = [];
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as UserScreenArguments;

    if (user == null && args.user != null) {
      user = args.user;
    }
    Future<RentoolUser> future = user == null ? FirestoreServices.getUser(args.uid!) : Future.value(user);

    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
          future: future,
          builder: (context, AsyncSnapshot<RentoolUser> snapshot) {
            if (snapshot.hasError) print('error getting user info: ${snapshot.error}');

            user = snapshot.data;

            if (user == null) {
              return _buildLoadingContainer(context);
            }

            return RefreshIndicator(
              onRefresh: () => _refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                children: [
                  _buildUserTopTile(user!, context),
                  const Divider(color: Colors.black26, height: 20),

                  // Ratings

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      AppLocalizations.of(context)!.ratings_and_reviews,
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      children: [
                        Expanded(
                          child: RatingDisplay(
                            rating: user!.rating,
                            color: Colors.orange.shade700,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                ReviewsScreen.routeName,
                                arguments: ReviewsScreenArguments(user!),
                              );
                            },
                          ),
                        ),
                        if (user!.uid != AuthServices.currentUid) ...[
                          const SizedBox(width: 10),
                          RateUser(
                            user: user!,
                            afterChange: () => setState(() {}),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const Divider(color: Colors.black26),

                  // Tools

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      AppLocalizations.of(context)!.tools,
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ),
                  _buildToolsList(context),
                ],
              ),
            );
          }),
    );
  }

  Padding _buildUserTopTile(RentoolUser user, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            maxRadius: 35,
            backgroundImage: user.photoURL == null ? null : NetworkImage(user.photoURL!),
            child: user.photoURL == null
                ? Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onSurface,
                  )
                : null,
            backgroundColor: user.photoURL == null ? Colors.black12 : Colors.transparent,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(fontWeight: FontWeight.bold),
                ),
                if (user.uid == AuthServices.currentUid)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    height: 30,
                    child: OutlinedButton(
                      child: Text(AppLocalizations.of(context)!.account_settings.toUpperCase()),
                      onPressed: () {
                        // TODO push account settings
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsList(BuildContext context) {
    return FutureBuilder(
      future: _getTools(),
      builder: (context, snapshot) {
        if (noMoreToolsDocs && tools.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(pi),
                      child: Icon(
                        Icons.build,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Icon(
                      Icons.do_not_disturb,
                      size: 100,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
                Text(
                  AppLocalizations.of(context)!.no_tools,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.grey.shade400),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          controller: _scrollController,
          itemCount: tools.length + 1,
          separatorBuilder: (context, index) => const Divider(
            indent: 120,
            endIndent: 120,
            height: 2,
          ),
          itemBuilder: (context, index) {
            if (index >= tools.length) {
              if (!noMoreToolsDocs) {
                _getTools().then((value) {
                  setState(() {});
                });
              }
              return ListTile(
                title: noMoreToolsDocs ? null : const LinearProgressIndicator(),
              );
            }

            final tool = tools[index];
            return ToolTile(
              tool: tool,
              onTap: () async {
                final result = await Navigator.pushNamed(context, '/post', arguments: tool);
                setState(() {
                  if (result == 'Deleted') {
                    tools.remove(tool);
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  Center _buildLoadingContainer(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LoadingIndicator(height: 75, strokeWidth: 6),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.loading_user_info,
            style: Theme.of(context).textTheme.subtitle1!.copyWith(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class UserScreenArguments {
  final RentoolUser? user;
  final String? uid;

  UserScreenArguments({this.user, this.uid}) : assert(user != null || uid != null);
}
