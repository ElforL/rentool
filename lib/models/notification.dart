import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/screens/post_screen.dart';
import 'package:rentool/screens/user_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';

class RentoolNotification {
  final String id;
  final String code;

  /// - `REQ_REC`: toolID, requestID, toolName, renterName
  /// - `REQ_ACC`: toolID, requestID, toolName,
  /// - `REQ_DEL`: toolID, requestID, toolName,
  /// - `REN_START`: toolID, toolName, renterName, ownerName, renterUID
  /// - `REN_END`: toolID, toolName, otherUserName, otherUserId, notificationBodyArgs
  /// - `DC_DAM`: toolID, toolName
  /// - `DC_NDAM`: toolID, toolName
  final Map<String, dynamic> data;
  bool isRead;
  final DateTime time;

  RentoolNotification(this.id, this.code, this.data, this.isRead, this.time);

  factory RentoolNotification.fromJson(String id, Map<String, dynamic> json) {
    return RentoolNotification(
      id,
      json['code'],
      json['data'],
      json['isRead'],
      (json['time'] as Timestamp).toDate(),
    );
  }

  Future<void> setIsRead([bool isRead = true]) {
    this.isRead = isRead;
    return FirestoreServices.setNotificationIsRead(AuthServices.currentUid!, id, isRead: isRead);
  }

  String getTitle(BuildContext context) {
    switch (code) {
      case 'REQ_REC':
        return AppLocalizations.of(context)!.title_REQ_REC;
      case 'REQ_ACC':
        return AppLocalizations.of(context)!.title_REQ_ACC;
      case 'REQ_DEL':
        return AppLocalizations.of(context)!.title_REQ_DEL;
      case 'REN_START':
        return AppLocalizations.of(context)!.title_REN_START;
      case 'REN_END':
        return AppLocalizations.of(context)!.title_REN_END;
      case 'DC_DAM':
        return AppLocalizations.of(context)!.title_DC_DAM;
      case 'DC_NDAM':
        return AppLocalizations.of(context)!.title_DC_NDAM;
      default:
        throw ArgumentError("Code doesn't match any notification code: $code");
    }
  }

  String getBody(BuildContext context) {
    switch (code) {
      case 'REQ_REC':
        return AppLocalizations.of(context)!.body_REQ_REC(data['toolName'], data['renterName']);
      case 'REQ_ACC':
        return AppLocalizations.of(context)!.body_REQ_ACC(data['toolName']);
      case 'REQ_DEL':
        return AppLocalizations.of(context)!.body_REQ_DEL(data['toolName']);
      case 'REN_START':
        return AppLocalizations.of(context)!.body_REN_START(data['toolName'], data['otherUserName']);
      case 'REN_END':
        return AppLocalizations.of(context)!.body_REN_END(data['toolName'], data['otherUserName']);
      case 'DC_DAM':
        return AppLocalizations.of(context)!.body_DC_DAM(data['toolName']);
      case 'DC_NDAM':
        return AppLocalizations.of(context)!.body_DC_NDAM(data['toolName']);
      default:
        throw ArgumentError("Code doesn't match any notification code: $code");
    }
  }

  Function() getOnPressHandler(BuildContext context) {
    switch (code) {
      case 'REQ_REC':
        return () => Navigator.of(context).pushNamed(PostScreen.routeName + '/${data['toolID']}');
      case 'REQ_ACC':
        return () => Navigator.of(context).pushNamed(PostScreen.routeName + '/${data['toolID']}');
      case 'REQ_DEL':
        return () => Navigator.of(context).pushNamed(PostScreen.routeName + '/${data['toolID']}');
      case 'REN_START':
        return () => Navigator.of(context).pushNamed(PostScreen.routeName + '/${data['toolID']}');
      case 'REN_END':
        return () => Navigator.of(context).pushNamed(UserScreen.routeName + '/${data['otherUserId']}');
      case 'DC_DAM':
        return () => Navigator.of(context).pushNamed(PostScreen.routeName + '/${data['toolID']}');
      case 'DC_NDAM':
        return () => Navigator.of(context).pushNamed(PostScreen.routeName + '/${data['toolID']}');
      default:
        throw ArgumentError("Code doesn't match any notification code: $code");
    }
  }
}
