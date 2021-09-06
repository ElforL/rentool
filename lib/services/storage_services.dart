import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageServices {
  static FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Uploads [files] to Firebasde Storage for the tool with the given [toolID] and
  /// returns the list of URLs of the files.
  static Future<List<String>> uploadMediaOfTool(List<File> files, String toolID) async {
    var output = <String>[];
    for (var file in files) {
      var upload = await _storage.ref('/tools_media/$toolID/${files.indexOf(file)}').putFile(file);
      output.add(await upload.ref.getDownloadURL());
    }
    return output;
  }

  static UploadTask uploadDeliverMeetingFile(File file, String toolID, String requestID, String uid) {
    return _storage.ref('/deliver_meetings/$toolID/$requestID/$uid/${file.path}').putFile(file);
  }

  static UploadTask uploadReturnMeetingFile(File file, String toolID, String requestID, String uid) {
    return _storage.ref('/return_meetings/$toolID/$requestID/$uid/${file.path}').putFile(file);
  }
}
