import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageServices {
  static FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Uploads [files] to Firebasde Storage for the tool with the given [toolID] and
  /// returns the list of URLs of the files.
  static Future<List<String>> uploadMediaOfTool(List<File> files, String toolID) async {
    var output = <String>[];
    for (var file in files) {
      var upload = await _storage.ref('/tools_media/$toolID/${file.uri.pathSegments.last}').putFile(file);
      output.add(await upload.ref.getDownloadURL());
    }
    return output;
  }

  static UploadTask uploadDeliverMeetingFile(File file, String toolID, String requestID, String uid) {
    final fileName = file.uri.pathSegments.last;
    return _storage.ref('/deliver_meetings/$toolID/$requestID/$uid/$fileName').putFile(file);
  }

  static UploadTask uploadReturnMeetingFile(File file, String toolID, String requestID, String uid) {
    final fileName = file.uri.pathSegments.last;
    return _storage.ref('/return_meetings/$toolID/$requestID/$uid/$fileName').putFile(file);
  }

  static UploadTask uploadUserPhoto(File file, String uid) {
    // final type = fileName.substring(fileName.lastIndexOf('.'));
    return _storage.ref('/userPhotos/$uid').putFile(file);
  }

  static Future<Uint8List?> getTOS() {
    return _storage.ref('/read_only/terms/terms_of_use.md').getData();
  }

  static Future<Uint8List?> getPrivacyPolicy() {
    return _storage.ref('/read_only/terms/privacy_policy.md').getData();
  }

  static Future<String> getTosUrl() {
    return _storage.ref('/read_only/terms/terms_of_use.md').getDownloadURL();
  }

  static Future<String> getPrivacyPolicyUrl() {
    return _storage.ref('/read_only/terms/privacy_policy.md').getDownloadURL();
  }
}
