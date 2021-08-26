import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/services/storage_services.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class DeliverMeeting {
  final Tool tool;

  final String ownerUID;
  final String renterUID;

  bool ownerArrived;
  bool renterArrived;

  bool ownerPicsOk;
  bool renterPicsOk;

  List<String> ownerPicsUrls;
  List<String> renterPicsUrls;

  String? ownerID;
  String? renterID;

  bool ownerIdsOk;
  bool renterIdsOk;

  /// if the meeting was done and succesful and a rent object/doc was created
  bool rentStarted;

  /// any errors that could occur with the meeting e.g., payment fail, database error... etc
  Object? error;

  DeliverMeeting(
    this.tool,
    this.ownerUID,
    this.renterUID,
    this.ownerArrived,
    this.renterArrived,
    this.ownerPicsOk,
    this.renterPicsOk,
    this.ownerPicsUrls,
    this.renterPicsUrls,
    this.ownerIdsOk,
    this.renterIdsOk,
    this.rentStarted, {
    this.ownerID,
    this.renterID,
    this.error,
  });

  factory DeliverMeeting.fromJson(Tool tool, Map<String, dynamic> json) {
    return DeliverMeeting(
      tool,
      json['ownerUID'],
      json['renterUID'],
      json['owner_arrived'],
      json['renter_arrived'],
      json['owner_pics_ok'],
      json['renter_pics_ok'],
      json['owner_pics_urls'] != null ? List<String>.from(json['owner_pics_urls']) : [],
      json['renter_pics_urls'] != null ? List<String>.from(json['renter_pics_urls']) : [],
      json['owner_ids_ok'],
      json['renter_ids_ok'],
      json['rent_started'],
      ownerID: json['owner_id'],
      renterID: json['renter_id'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerUID': ownerUID,
      'renterUID': renterUID,
      'owner_arrived': ownerArrived,
      'renter_arrived': renterArrived,
      'owner_pics_ok': ownerPicsOk,
      'renter_pics_ok': renterPicsOk,
      'owner_pics_urls': ownerPicsUrls,
      'renter_pics_urls': renterPicsUrls,
      'owner_ids_ok': ownerIdsOk,
      'renter_ids_ok': renterIdsOk,
      'rent_started': rentStarted,
      'owner_id': ownerID,
      'renter_id': renterID,
      'error': error,
    };
  }

  bool get isUserTheOwner => AuthServices.currentUid == ownerUID;
  String get userRole => isUserTheOwner ? 'owner' : 'renter';
  String get otherUserRole => !isUserTheOwner ? 'owner' : 'renter';

  // Arrival methods

  /// update the current user `arrived` field in Firestore to [didArrive]
  Future<void> setArrived(bool didArrive) {
    return FirestoreServices.setDeliverMeetingField(tool, '${userRole}_arrived', didArrive);
  }

  /// did both the owner and renter arrive to the meeting
  bool get bothArrived => ownerArrived && renterArrived;

  /// did the current user arrive to the meeting
  bool get userArrived => isUserTheOwner ? ownerArrived : renterArrived;

  /// did the other user arrive to the meeting
  ///
  /// other user = the renter if the current user is the owner and vice versa.
  bool get otherUserArrived => !isUserTheOwner ? ownerArrived : renterArrived;

  // Media methods

  /// update the current user `pics_ok` field in Firestore to [mediaOk]
  Future<void> setMediaOK(bool mediaOk) {
    return FirestoreServices.setDeliverMeetingField(tool, '${userRole}_pics_ok', mediaOk);
  }

  /// did both the owner and renter finish uploading thier pictures and videos
  bool get bothMediaOk => ownerPicsOk && renterPicsOk;

  /// did the current user finish uploading thier pictures and videos
  bool get userMediaOk => isUserTheOwner ? ownerPicsOk : renterPicsOk;

  /// did the other user finish uploading thier pictures and videos
  ///
  /// other user = the renter if the current user is the owner and vice versa.
  bool get otherUserMediaOk => !isUserTheOwner ? ownerPicsOk : renterPicsOk;

  /// the current user's pictures and videos urls
  List<String> get userMediaUrls => isUserTheOwner ? ownerPicsUrls : renterPicsUrls;

  /// did the other user's pictures and videos urls
  ///
  /// other user = the renter if the current user is the owner and vice versa.
  List<String> get otherUserMediaUrls => !isUserTheOwner ? ownerPicsUrls : renterPicsUrls;

  /// uploads [file] to Storage and adds its url to the user's `_pics_urls` field in Firestore
  Future<void> addMedia(File file) async {
    // upload file
    final upload = await StorageServices.uploadDeliverMeetingFile(
      file,
      tool.id,
      tool.acceptedRequestID!,
      AuthServices.currentUid!,
    );
    final url = await upload.ref.getDownloadURL();

    // update Firestore
    return FirestoreServices.setDeliverMeetingField(
      tool,
      '${userRole}_pics_urls',
      FieldValue.arrayUnion([url]),
    );
  }

  /// removes [url] from the user's `_pics_urls` field in Firestore
  Future<void> removeMedia(String url) {
    return FirestoreServices.setReturnMeetingField(
      tool,
      '${userRole}_pics_urls',
      FieldValue.arrayRemove([url]),
    );
  }

  // ID confirmation methods

  /// the current user's civil ID number
  String? get userID => isUserTheOwner ? ownerID : renterID;

  /// the other user's civil ID number
  ///
  /// other user = the renter if the current user is the owner and vice versa.
  String? get otherUserID => !isUserTheOwner ? ownerID : renterID;

  /// update the current user `ids_ok` field in Firestore to [idOk]
  Future<void> setIdOK(bool idOk) {
    return FirestoreServices.setDeliverMeetingField(tool, '${userRole}_pics_ok', idOk);
  }

  /// did the current user confirm the other's id
  bool get userIdsOk => isUserTheOwner ? ownerIdsOk : renterIdsOk;

  /// did the other user confirm the current user's id
  ///
  /// other user = the renter if the current user is the owner and vice versa.
  bool get otherUserIdsOk => !isUserTheOwner ? ownerIdsOk : renterIdsOk;

  /// did both the owner and renter confirm each other's IDs
  bool get bothIdsOk => ownerIdsOk && renterIdsOk;
}
