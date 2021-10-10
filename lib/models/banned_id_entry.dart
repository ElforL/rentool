import 'package:cloud_firestore/cloud_firestore.dart';

class BannedIdEntry {
  final String idNumber;
  final String uid;
  final String reason;
  final String admin;
  final DateTime banTime;

  BannedIdEntry(this.idNumber, this.uid, this.reason, this.admin, this.banTime);

  factory BannedIdEntry.fromJson(Map<String, dynamic> json) {
    return BannedIdEntry(
      json['idNumber'],
      json['uid'],
      json['reason'],
      json['admin'],
      (json['ban_time'] is Timestamp) ? json['ban_time'].toDate() : json['ban_time'],
    );
  }
}
