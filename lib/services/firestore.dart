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
    // TODO add all the info not just the onwerUID then wait for media?
    var ref = await _toolsRef.add(<String, dynamic>{'ownerUID': AuthServices.auth.currentUser.uid});

    List<String> mediaURLs;

    if (media.isNotEmpty) {
      mediaURLs = await StorageServices.uploadMediaOfTool(media, ref.id);
    }

    // create model and post
    var tool = Tool(
      ref.id,
      AuthServices.auth.currentUser.uid,
      name,
      description,
      rentPrice,
      insuranceAmount,
      mediaURLs,
      location,
      true,
    );
    return await updateTool(tool);
  }

  static Future<Tool> updateTool(Tool updatedTool) async {
    var ref = _toolsRef.doc(updatedTool.id);
    await ref.update(updatedTool.toJson()..remove('id')..remove('requests'));
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
