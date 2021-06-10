import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    List<String> media,
    String location,
  ) async {
    // create a new document to get an ID
    var ref = await _toolsRef.add(<String, dynamic>{});
    var tool = Tool(
      ref.id,
      AuthServices.auth.currentUser.uid,
      name,
      description,
      rentPrice,
      insuranceAmount,
      media,
      location,
      true,
    );
    return await updateTool(tool);
  }

  static Future<Tool> updateTool(Tool updatedTool) async {
    var ref = _toolsRef.doc(updatedTool.id);
    await ref.set(updatedTool.toJson()..remove('id'));
    return updatedTool;
  }

  // ////////////////////////////// User //////////////////////////////

  /// returns true if the user has a document in the Firestore database.
  ///
  /// A [FirebaseException] maybe thrown with the following error code:
  /// - **permission-denied**: Missing or insufficient permissions.
  static Future<bool> ensureUserExist(User user) async {
    var userExists = (await _usersRef.doc(user.uid).get()).exists;
    if (!userExists) {
      return await addUser(RentoolUser(user.uid, user.displayName, 0));
    }
    return true;
  }

  /// Creates a Document for [user] in the Firestore database.
  ///
  /// returns true if successful
  static Future<bool> addUser(RentoolUser user) async {
    var userJson = user.toJson();
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
}
