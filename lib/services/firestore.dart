import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rentool/services/storage_services.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/models/rentool/rentool_models.dart';

class FirestoreServices {
  /// Firestore instance
  ///
  /// equivelant to `FirebaseFirestore.instance`
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// `CollectionReference` of the 'Users' collection in the database
  static final CollectionReference _usersRef = _db.collection('Users');

  /// `CollectionReference` of the 'Tools' collection in the database
  static final CollectionReference _toolsRef = _db.collection('Tools');

  // ////////////////////////////// Tools //////////////////////////////

  /// Create a tool document in Firestore and return a `Tool` object.
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
      AuthServices.currentUid!,
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

  /// Returns a `Stream` of the tool document in Firestore.
  ///
  /// Notifies of document updates.
  ///
  /// An initial event is immediately sent, and further events will be sent whenever the document is modified.
  static Stream<DocumentSnapshot<Object?>> getToolStream(String toolID) {
    return _toolsRef.doc(toolID).snapshots();
  }

  /// Update the tool document in Firestore.
  static Future<Tool> updateTool(Tool updatedTool) async {
    var ref = _toolsRef.doc(updatedTool.id);
    await ref.update(updatedTool.toJson(['id', 'requests']));
    return updatedTool;
  }

  /// Delete the tool document in Firestore.
  static Future<void> deleteTool(String toolID) {
    var ref = _toolsRef.doc(toolID);
    return ref.delete();
  }

  /// Get the tool document from Firestore.
  static Future<DocumentSnapshot<Object?>> getTool(String toolID) {
    return _toolsRef.doc(toolID).get();
  }

  static Future<QuerySnapshot<Object?>> getUserTool(String uid, {int limit = 10, DocumentSnapshot? previousDoc}) {
    if (previousDoc != null) {
      return _toolsRef.where('ownerUID', isEqualTo: uid).limit(limit).startAfterDocument(previousDoc).get();
    } else {
      return _toolsRef.where('ownerUID', isEqualTo: uid).limit(limit).get();
    }
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

  /// Get the content of the tool-request with given [requestID] document.
  static Future<DocumentSnapshot<Map<String, dynamic>>> getToolRequest(toolID, requestID) {
    return _toolsRef.doc(toolID).collection('requests').doc(requestID).get();
  }

  /// Get a number of tool-requests (default = 10)
  ///
  /// if [previousDoc] is provided the query will start after it.
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

  /// Get a user's sent requests
  static Future<QuerySnapshot<Map<String, dynamic>>> getUserRequests(
    String uid, {
    int limit = 10,
    DocumentSnapshot<Object?>? previousDoc,
  }) {
    if (previousDoc != null) {
      return _usersRef.doc(uid).collection('requests').limit(limit).startAfterDocument(previousDoc).get();
    } else {
      return _usersRef.doc(uid).collection('requests').limit(limit).get();
    }
  }

  /// Accept a tool-request with given [requestID] on tool with id [toolID].
  ///
  /// this will change the tool's _'acceptedRequestID'_ field to [requestID]
  static Future<void> acceptRequest(String toolID, String requestID) async {
    return await _toolsRef.doc(toolID).update({'acceptedRequestID': requestID});
  }

  /// Delete/reject a tool-request with given [requestID] on tool with id [toolID].
  static Future<void> deleteRequest(String toolID, String requestID) async {
    return await _toolsRef.doc(toolID).collection('requests').doc(requestID).delete();
  }

  /// Returns a `Stream` of the tool's delivery meeting document in Firestore.
  ///
  /// Notifies of document updates.
  ///
  /// An initial event is immediately sent, and further events will be sent whenever the document is modified.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getDeliverMeetingStream(Tool tool) {
    return _toolsRef.doc(tool.id).collection('deliver_meetings').doc(tool.acceptedRequestID).snapshots();
  }

  /// Set [field] of a tool's delivery meeting document to [value]
  ///
  /// Example:
  /// ```
  /// setDeliverMeetingField(tool, 'owner_arrived', true)
  /// ```
  /// sets **_'owner_arrived'_** field to true (i.e., owner arrived).
  static Future<void> setDeliverMeetingField(Tool tool, String field, dynamic value) {
    return _toolsRef.doc(tool.id).collection('deliver_meetings').doc(tool.acceptedRequestID).update(
      {field: value},
    );
  }

  /// Returns a `Stream` of the tool's return meeting document in Firestore.
  ///
  /// Notifies of document updates.
  ///
  /// An initial event is immediately sent, and further events will be sent whenever the document is modified.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getReturnMeetingStream(Tool tool) {
    return _toolsRef.doc(tool.id).collection('return_meetings').doc(tool.acceptedRequestID).snapshots();
  }

  /// Set [field] of a tool's return meeting document to [value]
  ///
  /// Example:
  /// ```
  /// setReturnMeetingField(tool, 'ownerArrived', true)
  /// ```
  /// sets **_'ownerArrived'_** field to true (i.e., owner arrived).
  static Future<void> setReturnMeetingField(Tool tool, String field, dynamic value) {
    return _toolsRef.doc(tool.id).collection('return_meetings').doc(tool.acceptedRequestID).update(
      {field: value},
    );
  }

  // ////////////////////////////// User //////////////////////////////

  /// Add [uuid] to the user's devices collection.
  ///
  /// Added to document `Users/uid/devices/uuid`.
  static Future<void> addDeviceToken(String token, String uid, String uuid, [String? deviceName]) {
    return _usersRef.doc(uid).collection('devices').doc(uuid).set({
      'token': token,
      'deviceName': deviceName ?? 'Unknown name',
    });
  }

  /// Delete [uuid] from the user's devices collection.
  static Future<void> deleteDeviceToken(String uuid, String uid) {
    return _usersRef.doc(uid).collection('devices').doc(uuid).update({
      'token': null,
    });
  }

  /// returns true if the user has a document in the Firestore database.
  ///
  /// A [FirebaseException] maybe thrown with the following error code:
  /// - **permission-denied**: Missing or insufficient permissions.
  static Future<bool> ensureUserExist(User user) async {
    var userExists = (await _usersRef.doc(user.uid).get()).exists;
    if (!userExists) {
      return await addUser(RentoolUser(user.uid, user.displayName ?? 'NOT-SET', 0, 0));
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

  /// Get the ID document of the user with the given [uid]
  static Future<DocumentSnapshot<Object>> getID(String uid) {
    return _usersRef.doc(uid).collection('private').doc('ID').get();
  }

  /// Sets _isRead_ field to [isRead] of the notification with the given [notificationId] of the user with the given [uid].
  static Future<void> setNotificationIsRead(String uid, String notificationId, {bool isRead = true}) {
    return _usersRef.doc(uid).collection('notifications').doc(notificationId).update({'isRead': isRead});
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> getNotifications(
    String uid, {
    int limit = 10,
    DocumentSnapshot<Object?>? previousDoc,
  }) {
    if (previousDoc != null) {
      return _usersRef
          .doc(uid)
          .collection('notifications')
          .orderBy('time', descending: true)
          .limit(limit)
          .startAfterDocument(previousDoc)
          .get();
    } else {
      return _usersRef.doc(uid).collection('notifications').orderBy('time', descending: true).limit(limit).get();
    }
  }

  static Future<RentoolUser> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    final user = RentoolUser.fromJson(
      (doc.data() as Map<String, dynamic>)..addAll({'uid': uid}),
    );
    return user;
  }
}
