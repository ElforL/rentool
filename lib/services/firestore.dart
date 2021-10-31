import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentool/models/deliver_meetings.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/storage_services.dart';

class FirestoreServices {
  /// Firestore instance
  ///
  /// equivelant to `FirebaseFirestore.instance`
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// `CollectionReference` of the 'Users' collection in the database
  static final CollectionReference _usersRef = _db.collection('Users');

  /// `CollectionReference` of the 'Tools' collection in the database
  static final CollectionReference _toolsRef = _db.collection('Tools');

  /// The current user's ID number.
  ///
  /// could be `null` if the user is signed out or if the user didn't set an ID number.
  static bool? hasId;
  static bool? hasCard;

  /// Updates [FirestoreServices.hasId] and [FirestoreServices.hasCard]
  static Future<void> updateChecklist() async {
    if (AuthServices.currentUid == null) {
      hasId = null;
      hasCard = null;
      return;
    }

    final doc = await getCheckList(AuthServices.currentUid!);
    if (doc.exists && doc.data() is Map<String, dynamic>) {
      hasId = (doc.data() as Map)['hasId'];
      hasCard = (doc.data() as Map)['hasCard'];
    }
  }

  // ooooooooooooo                     oooo
  // 8'   888   `8                     `888
  //      888       .ooooo.   .ooooo.   888   .oooo.o
  //      888      d88' `88b d88' `88b  888  d88(  "8
  //      888      888   888 888   888  888  `"Y88b.
  //      888      888   888 888   888  888  o.  )88b
  //     o888o     `Y8bod8P' `Y8bod8P' o888o 8""888P'

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
      return _toolsRef.where('ownerUID', isEqualTo: uid).startAfterDocument(previousDoc).limit(limit).get();
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

  /// Get the content of the tool-request of the renter with [uid]
  static Future<QuerySnapshot<Map<String, dynamic>>> getUserToolRequest(String toolID, String uid) {
    return _toolsRef.doc(toolID).collection('requests').where('renterUID', isEqualTo: uid).limit(1).get();
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
      return await _toolsRef.doc(toolID).collection('requests').startAfterDocument(previousDoc).limit(limit).get();
    }
  }

  /// Get a user's sent requests
  static Future<QuerySnapshot<Map<String, dynamic>>> getUserRequests(
    String uid, {
    int limit = 10,
    DocumentSnapshot<Object?>? previousDoc,
  }) {
    if (previousDoc != null) {
      return _usersRef.doc(uid).collection('requests').startAfterDocument(previousDoc).limit(limit).get();
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

  /// Cancel the accepted tool-request on tool with id [toolID].
  ///
  /// this will change the tool's _'acceptedRequestID'_ field to `null`
  static Future<void> cancelRequest(String toolID) async {
    return await _toolsRef.doc(toolID).update({'acceptedRequestID': null});
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

  static Future<DocumentReference<Map<String, dynamic>>> sendMessage(String message, String toolId, String requestId) {
    return _toolsRef.doc(toolId).collection('requests').doc(requestId).collection('messages').add({
      'uid': AuthServices.currentUid!,
      'message': message,
      'sentTime': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getChatStream(String toolId, String requestId) {
    return _toolsRef
        .doc(toolId)
        .collection('requests')
        .doc(requestId)
        .collection('messages')
        .orderBy('sentTime', descending: true)
        .snapshots();
  }

  static Future<DocumentSnapshot<Object?>> getDeliverMeetingPrivateDoc(DeliverMeeting meeting) {
    return _toolsRef
        .doc('${meeting.tool.id}/deliver_meetings/${meeting.requestID}/private/${AuthServices.currentUid}')
        .get();
  }

  // ooooo     ooo
  // `888'     `8'
  //  888       8   .oooo.o  .ooooo.  oooo d8b  .oooo.o
  //  888       8  d88(  "8 d88' `88b `888""8P d88(  "8
  //  888       8  `"Y88b.  888ooo888  888     `"Y88b.
  //  `88.    .8'  o.  )88b 888    .o  888     o.  )88b
  //    `YbodP'    8""888P' `Y8bod8P' d888b    8""888P'

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

  static Future<DocumentSnapshot<Map<String, dynamic>>> getDeviceTokenDoc(String uuid, String uid) {
    return _usersRef.doc(uid).collection('devices').doc(uuid).get();
  }

  /// Creates a Document for [user] in the Firestore database.
  ///
  /// returns true if successful
  static Future<bool> addUser(RentoolUser user) async {
    final uid = user.uid;
    final userJson = user.toJson(['reviews', 'tools', 'requests', 'uid']);

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

  /// Get the card document of the user with the given [uid]
  ///
  /// Doc format:
  /// ```
  /// 'expiry_month': expiry_month,
  /// 'expiry_year': expiry_year,
  /// 'name': car holder name,
  /// 'scheme': scheme (e.g., Visa),
  /// 'last4': last4,
  /// 'bin': bin,
  /// ```
  static Future<DocumentSnapshot<Map<String, dynamic>>> getCard(String uid) {
    return _usersRef.doc(uid).collection('private').doc('card').get();
  }

  static Future<void> setID(String idNumber) async {
    await _usersRef.doc(AuthServices.currentUid!).collection('private').doc('ID').set({'idNumber': idNumber});
    hasId = true;
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
          .startAfterDocument(previousDoc)
          .limit(limit)
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

  static Future<bool> canUserRateUser(String reviewerUid, String targetUid) async {
    final result = await _usersRef.doc(reviewerUid).collection('previous_users').doc(targetUid).get();
    return result.exists;
  }

  static Future<UserReview?> getReviewOnUser(String reviewerUid, String targetUid) async {
    final result = await _usersRef.doc(targetUid).collection('reviews').doc(reviewerUid).get();
    if (result.data() != null) {
      final review = UserReview.fromJson(result.data()!
        ..addAll({
          'targetUID': targetUid,
          'creatorUID': reviewerUid,
        }));
      return review;
    }
    return null;
  }

  /// Create review doc in Firestore
  static Future<void> createReview(UserReview review) {
    return _usersRef.doc(review.targetUID).collection('reviews').doc(review.creatorUID).set(review.toJson());
  }

  /// Create review doc in Firestore
  static Future<void> deleteReview(UserReview review) {
    return _usersRef.doc(review.targetUID).collection('reviews').doc(review.creatorUID).delete();
  }

  /// Get the reviews on the user with given [uid].
  static Future<QuerySnapshot<Map<String, dynamic>>> getReviewsOnUser(
    String uid, {
    int limit = 10,
    DocumentSnapshot<Object?>? previousDoc,
    int? reviewValueFilter,
  }) {
    final collection = _usersRef.doc(uid).collection('reviews');
    Query<Map<String, dynamic>> query;
    if (reviewValueFilter != null) {
      query = collection.where('value', isEqualTo: reviewValueFilter);
    } else {
      query = collection;
    }

    if (previousDoc != null) {
      return query.startAfterDocument(previousDoc).limit(limit).get();
    } else {
      return query.limit(limit).get();
    }
  }

  static Future<DocumentSnapshot<Object?>> getCheckList(String uid) {
    return _usersRef.doc('$uid/private/checklist').get();
  }

  //       .o.             .o8                     o8o
  //      .888.           "888                     `"'
  //     .8"888.      .oooo888  ooo. .oo.  .oo.   oooo  ooo. .oo.
  //    .8' `888.    d88' `888  `888P"Y88bP"Y88b  `888  `888P"Y88b
  //   .88ooo8888.   888   888   888   888   888   888   888   888
  //  .8'     `888.  888   888   888   888   888   888   888   888
  // o88o     o8888o `Y8bod88P" o888o o888o o888o o888o o888o o888o

  static Future<DocumentSnapshot<Map<String, dynamic>>> getOneDisagreemtnCase(String id) {
    return _db.doc('disagreementCases/$id').get();
  }

  /// Updates the disagreement case with [caseID] document to the result and the sets the [adminUid]
  static Future<void> setDisagreementCaseResult(String caseID, bool result, String description, String adminUid) {
    return _db.doc('disagreementCases/$caseID').update({
      'Admin': adminUid,
      'Result_IsToolDamaged': result,
      'ResultDescription': description,
    });
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> getDisagreemtnCases({
    int limit = 10,
    DocumentSnapshot<Object?>? previousDoc,
  }) {
    if (previousDoc != null) {
      return _db
          .collection('disagreementCases')
          .orderBy('timeCreated', descending: true)
          .startAfterDocument(previousDoc)
          .limit(limit)
          .get();
    } else {
      return _db.collection('disagreementCases').orderBy('timeCreated', descending: true).limit(limit).get();
    }
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getOneBannedId(String id) {
    return _db.doc('bannedList/$id').get();
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> getBannedIds({
    int limit = 10,
    DocumentSnapshot<Object?>? previousDoc,
  }) {
    if (previousDoc != null) {
      return _db
          .collection('bannedList')
          .orderBy('ban_time', descending: true)
          .startAfterDocument(previousDoc)
          .limit(limit)
          .get();
    } else {
      return _db.collection('bannedList').orderBy('ban_time', descending: true).limit(limit).get();
    }
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getOneBannedUser(String uid) {
    return _db.doc('bannedUsers/$uid').get();
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> getBannedUsers({
    int limit = 10,
    DocumentSnapshot<Object?>? previousDoc,
  }) {
    if (previousDoc != null) {
      return _db
          .collection('bannedUsers')
          .orderBy('ban_time', descending: true)
          .startAfterDocument(previousDoc)
          .limit(limit)
          .get();
    } else {
      return _db.collection('bannedUsers').orderBy('ban_time', descending: true).limit(limit).get();
    }
  }
}
