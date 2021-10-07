import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';

class DisagreementCase {
  final String id;
  final String toolId;
  final String requestId;
  final String ownerUid;
  final String renterUid;
  List<String> ownerMedia;
  List<String> renterMedia;
  DateTime timeCreated;

  /// The UID of the admin assigned to this case
  String? admin;

  /// Did the admin decide that the tool is damaged.
  ///
  /// if `null` the case isn't resolved yet.
  bool? resultIsToolDamaged;

  /// The justification of the admin's decission
  String? resultDescription;

  DisagreementCase(
    this.id,
    this.toolId,
    this.requestId,
    this.ownerUid,
    this.timeCreated,
    this.renterUid, {
    this.ownerMedia = const [],
    this.renterMedia = const [],
    this.admin,
    this.resultIsToolDamaged,
    this.resultDescription,
  });

  factory DisagreementCase.fromJson(Map<String, dynamic> json, {String? id}) {
    return DisagreementCase(
      id ?? json['id'],
      json['toolID'],
      json['requestID'],
      json['ownerUID'],
      json['renterUID'],
      json['timeCreated'] is Timestamp ? json['timeCreated'].toDate() : json['timeCreated'],
      ownerMedia: json['ownerMedia'] == null ? [] : List<String>.from(json['ownerMedia']),
      renterMedia: json['renterMedia'] == null ? [] : List<String>.from(json['renterMedia']),
      admin: json['Admin'],
      resultIsToolDamaged: json['Result_IsToolDamaged'],
      resultDescription: json['ResultDescription'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toolID': toolId,
      'requestID': requestId,
      'ownerUID': ownerUid,
      'renterUID': renterUid,
      'ownerMedia': ownerMedia,
      'renterMedia': renterMedia,
      'Admin': admin,
      'Result_IsToolDamaged': resultIsToolDamaged,
      'ResultDescription': resultDescription,
      'timeCreated': timeCreated,
    };
  }

  Future<void> pushResult(bool result, String description) async {
    await FirestoreServices.setDisagreementCaseResult(id, result, description, AuthServices.currentUid!);
    resultIsToolDamaged = result;
    resultDescription = description;
    admin = AuthServices.currentUid!;
  }
}
