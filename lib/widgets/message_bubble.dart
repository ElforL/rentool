import 'package:flutter/material.dart';
import 'package:rentool/models/chat_message.dart';

/* 
 * Imported from another project of mine: ElfChat
 * https://github.com/ElforL/ElfChat/blob/master/lib/widgets/MessageBubble.dart
*/

class MessageBubble extends StatelessWidget {
  const MessageBubble(
    this.message, {
    this.isSent = false,
    this.isFirstFromUser = true,
    Key? key,
  }) : super(key: key);

  final ChatMessage message;

  /// true if the message is from the current user
  final bool isSent;

  /// if this message is the first from the user who sent it
  ///
  /// this affects the top padding of the bubble.
  /// `top: isFirstFromUser ? 5 : 1`
  final bool isFirstFromUser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        right: 5,
        left: 5,
        bottom: 2,
        top: isFirstFromUser ? 5 : 1,
      ),
      // TODO change [Column] to [Align]
      child: Column(
        // Alignment
        crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            // set max width
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              color: isSent ? Colors.blue.shade300 : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              message.message,
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }
}
