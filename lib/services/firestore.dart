import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rentool/services/StorageServices.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class FirestoreServices {
  /// Firestore instance
  ///
  /// equivelant to `FirebaseFirestore.instance`
  static FirebaseFirestore _db = FirebaseFirestore.instance;

  /// `CollectionReference` of the 'Users' collection in the database
  static CollectionReference _usersRef = _db.collection('Users');

  /// `CollectionReference` of the 'Tools' collection in the database
  static CollectionReference _toolsRef = _db.collection('Tools');

  // ////////////////////////////// Tools //////////////////////////////

  static Future<Tool> createNewTool(
    String name,
    String description,
    double rentPrice,
    double insuranceAmount,
    List<File> media,
    String location,
  ) async {
    // create a new document to get an ID
    var tool = Tool(
      'tempID',
      AuthServices.auth.currentUser!.uid,
      name,
      description,
      rentPrice,
      insuranceAmount,
      [],
      location,
      true,
    );
    var toolJson = tool.toJson(['id', 'requests']);
    var ref = await _toolsRef.add(toolJson);

    List<String>? mediaURLs;

    if (media.isNotEmpty) {
      mediaURLs = await StorageServices.uploadMediaOfTool(media, ref.id);
    }

    // create model and post
    tool = Tool.fromJson(
      tool.toJson()
        ..['id'] = ref.id
        ..['media'] = mediaURLs,
    );
    return await updateTool(tool);
  }

  static Future<Tool> updateTool(Tool updatedTool) async {
    var ref = _toolsRef.doc(updatedTool.id);
    await ref.update(updatedTool.toJson(['id', 'requests']));
    return updatedTool;
  }

  static Future<void> deleteTool(String toolID) {
    var ref = _toolsRef.doc(toolID);
    return ref.delete();
  }

  static Future<List<QueryDocumentSnapshot<Object?>>> searchForTool(String searchkey) async {
    // https://stackoverflow.com/a/56747021/12571630
    var out = await _toolsRef.orderBy('name').startAt([searchkey]).endAt([searchkey + '\uf8ff']).limit(10).get();

    return out.docs;
  }

  /// updates or creates the tool [request] of the user for the tool with the given [toolID]
  static Future<ToolRequest> sendNewToolRequest(ToolRequest request, String toolID) async {
    var requestJson = request.toJson(['id']);
    var doc = await _toolsRef.doc(toolID).collection('requests').add(requestJson);
    return ToolRequest.fromJson(
      requestJson
        ..addAll({
          'id': doc.id,
        }),
    );
  }

  /// updates or creates the tool [request] of the user for the tool with the given [toolID]
  static Future<void> updateToolRequest(ToolRequest request, String toolID) {
    var requestJson = request.toJson(['id']);
    return _toolsRef.doc(toolID).collection('requests').doc(request.id).set(requestJson);
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> fetchToolRequests(
    String toolID, {
    int limit = 10,
    DocumentSnapshot? previousDoc,
  }) async {
    if (previousDoc == null) {
      return await _toolsRef.doc(toolID).collection('requests').limit(limit).get();
    } else {
      return await _toolsRef.doc(toolID).collection('requests').limit(limit).startAfterDocument(previousDoc).get();
    }
  }

  static Future<void> acceptRequest(String toolID, String requestID) async {
    return await _toolsRef.doc(toolID).update({'acceptedRequestID': requestID});
  }

  static Future<void> deleteRequest(String toolID, String requestID) async {
    return await _toolsRef.doc(toolID).collection('requests').doc(requestID).delete();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> getDeliverMeetingStream(Tool tool) {
    return _toolsRef.doc(tool.id).collection('deliver_meetings').doc(tool.acceptedRequestID).snapshots();
  }

  static Future<void> setDeliverMeetingField(Tool tool, String field, dynamic value) async {
    return await _toolsRef.doc(tool.id).collection('deliver_meetings').doc(tool.acceptedRequestID).update(
      {field: value},
    );
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> getReturnMeetingStream(Tool tool) {
    return _toolsRef.doc(tool.id).collection('return_meetings').doc(tool.acceptedRequestID).snapshots();
  }

  static Future<void> setReturnMeetingField(Tool tool, String field, dynamic value) async {
    return await _toolsRef.doc(tool.id).collection('return_meetings').doc(tool.acceptedRequestID).update(
      {field: value},
    );
  }

  // ////////////////////////////// User //////////////////////////////

  static Future<void> addDeviceToken(String token, String uid, String uuid, [String? deviceName]) {
    return _usersRef.doc(uid).collection('devices').doc(uuid).set({
      'token': token,
      'deviceName': deviceName ?? 'Unknown name',
    });
  }

  static Future<void> deleteDeviceToken(String token, String uid) {
    return _usersRef.doc(uid).collection('devices').doc(token).delete();
  }

  /// returns true if the user has a document in the Firestore database.
  ///
  /// A [FirebaseException] maybe thrown with the following error code:
  /// - **permission-denied**: Missing or insufficient permissions.
  static Future<bool> ensureUserExist(User user) async {
    var userExists = (await _usersRef.doc(user.uid).get()).exists;
    if (!userExists) {
      return await addUser(RentoolUser(user.uid, user.displayName ?? 'NOT-SET', 0));
    }
    return true;
  }

  /// Creates a Document for [user] in the Firestore database.
  ///
  /// returns true if successful
  static Future<bool> addUser(RentoolUser user) async {
    var userJson = user.toJson(['reviews', 'tools', 'requests']);
    var uid = userJson['uid'];
    userJson.remove('uid');

    try {
      await _usersRef.doc(uid).set(userJson);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<void> updateID(String uid, String newID) {
    return _usersRef.doc(uid).collection('private').doc('ID').set({'idNumber': newID});
  }

  static Future<DocumentSnapshot<Object>> getID(String uid) {
    return _usersRef.doc(uid).collection('private').doc('ID').get();
  }
}
