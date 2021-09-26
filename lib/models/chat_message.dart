import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String uid;
  String message;
  DateTime? sentTime;

  ChatMessage(
    this.id,
    this.uid,
    this.message,
    this.sentTime,
  );

  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? id}) {
    return ChatMessage(
      id ?? json['id'],
      json['uid'],
      json['message'],
      json['sentTime'] is Timestamp ? (json['sentTime'] as Timestamp).toDate() : json['sentTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'message': message,
      'sentTime': sentTime,
    };
  }
}
