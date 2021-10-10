import 'package:cloud_firestore/cloud_firestore.dart';

class BannedUserEntry {
  final String uid;
  final String reason;
  final String admin;
  final DateTime banTime;

  BannedUserEntry(this.uid, this.reason, this.admin, this.banTime);

  factory BannedUserEntry.fromJson(Map<String, dynamic> json) {
    return BannedUserEntry(
      json['uid'],
      json['reason'],
      json['admin'],
      (json['ban_time'] is Timestamp) ? json['ban_time'].toDate() : json['ban_time'],
    );
  }
}
