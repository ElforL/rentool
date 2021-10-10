import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentool/models/banned_user_entry.dart';

class BannedIdEntry extends BannedUserEntry {
  final String idNumber;

  BannedIdEntry(this.idNumber, uid, reason, admin, banTime) : super(uid, reason, admin, banTime);

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
