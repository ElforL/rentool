import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentool/models/chat_message.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/screens/user_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/message_bubble.dart';
import 'package:rentool/widgets/rentool_circle_avatar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  static const routeName = '/chat';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _initiated = false;

  RentoolUser? otherUser;
  String? otherUserUid;
  ToolRequest? request;
  final List<ChatMessage> _messages = [];
  final _inputMessageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  void sendMessage() async {
    final messageText = _inputMessageController.text.trim();
    if (messageText.isNotEmpty) {
      FirestoreServices.sendMessage(
        messageText,
        request!.toolID,
        request!.id,
      );

      // clear the textfield and scroll to botttom
      _inputMessageController.clear();
      scrollToBottom();
    }
  }

  _addMessages(AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
    _messages.clear();
    for (var doc in snapshot.data!.docs) {
      _messages.add(ChatMessage.fromJson(doc.data(), id: doc.id));
    }
    // return;
  }

  @override
  void dispose() {
    _inputMessageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Load arguments
    if (!_initiated) {
      _initiated = true;
      assert(ModalRoute.of(context)?.settings.arguments != null);
      final args = ModalRoute.of(context)!.settings.arguments as ChatScreenArguments;
      request = args.request;
      otherUserUid = args.otherUserUid;
      otherUser = args.otherUser;
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: FutureBuilder(
          future: otherUser == null ? FirestoreServices.getUser(otherUserUid!) : Future.value(otherUser),
          builder: (context, AsyncSnapshot<RentoolUser?> snapshot) {
            otherUser ??= snapshot.data;
            return InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  UserScreen.routeName,
                  arguments: UserScreenArguments(user: otherUser, uid: otherUserUid),
                );
              },
              child: Row(
                children: [
                  RentoolCircleAvatar(
                    user: otherUser,
                    radius: 15,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(otherUser?.name ?? ''),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder(
              // TODO pagination
              stream: FirestoreServices.getChatStream(request!.toolID, request!.id),
              builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                // update messages list
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.data != null) {
                    _addMessages(snapshot);
                  }
                }

                // build it
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final message = _messages[index];
                    return MessageBubble(
                      message,
                      isSent: message.uid == AuthServices.currentUid,
                      isFirstFromUser: (index + 1 < _messages.length) ? _messages[index + 1].uid != message.uid : true,
                    );
                  },
                );
              },
            ),
          ),

          // Input
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    minLines: 1,
                    maxLines: 3,
                    controller: _inputMessageController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      hintText: AppLocalizations.of(context)!.type_a_message,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.blue,
                  shape: const CircleBorder(),
                  child: IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.send),
                    onPressed: () => sendMessage(),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ChatScreenArguments {
  final ToolRequest request;
  final String otherUserUid;
  final RentoolUser? otherUser;

  ChatScreenArguments(this.request, this.otherUserUid, {this.otherUser});
}
