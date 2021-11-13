import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/services/storage_services.dart';
import 'package:rentool/models/rentool/rentool_models.dart';

class ReturnMeeting {
  final Tool tool;

  final String ownerUID;
  final String renterUID;

  /// did the owner arrive to the meeting place
  bool ownerArrived;

  /// did the renter arrive to the meeting place
  bool renterArrived;

  /// is the tool damaged. `toolChecked` must be `true` to give [toolDamaged] a value.
  bool? toolDamaged;

  /// does the renter admit the tool is damaged. Requires `toolDamaged` to be `true`.
  bool? renterAdmitDamage;

  double? compensationPrice;

  bool? renterAcceptCompensationPrice;

  /// did the owner confirm the handover
  bool ownerConfirmHandover;

  /// did the renter confirm the handover
  bool renterConfirmHandover;

  String? disagreementCaseID;

  /// was the disagreement case reviewed and given a result
  bool? disagreementCaseSettled;

  /// is the tool damage according to disagreement case result
  bool? disagreementCaseResult;

  /// did the owner arrive to the meeting place
  bool ownerMediaOK;

  /// did the renter arrive to the meeting place
  bool renterMediaOK;

  /// List of URLs to pictures/videos
  List<String> renterMediaUrls;
  List<String> ownerMediaUrls;

  Object? error;

  ReturnMeeting(
    this.tool,
    this.ownerUID,
    this.renterUID, {
    this.ownerArrived = false,
    this.renterArrived = false,
    this.toolDamaged,
    this.renterAdmitDamage,
    this.compensationPrice,
    this.renterAcceptCompensationPrice,
    this.ownerConfirmHandover = false,
    this.renterConfirmHandover = false,
    this.disagreementCaseID,
    this.disagreementCaseSettled,
    this.disagreementCaseResult,
    this.ownerMediaOK = false,
    this.renterMediaOK = false,
    this.renterMediaUrls = const [],
    this.ownerMediaUrls = const [],
    this.error,
  });

  factory ReturnMeeting.fromJson(Tool tool, Map<String, dynamic> json) {
    return ReturnMeeting(
      tool,
      json['ownerUID'],
      json['renterUID'],
      ownerArrived: json['ownerArrived'],
      renterArrived: json['renterArrived'],
      toolDamaged: json['toolDamaged'],
      renterAdmitDamage: json['renterAdmitDamage'],
      compensationPrice: json['compensationPrice'],
      renterAcceptCompensationPrice: json['renterAcceptCompensationPrice'],
      ownerConfirmHandover: json['ownerConfirmHandover'],
      renterConfirmHandover: json['renterConfirmHandover'],
      disagreementCaseID: json['disagreementCaseID'],
      disagreementCaseSettled: json['disagreementCaseSettled'],
      disagreementCaseResult: json['disagreementCaseResult'],
      ownerMediaOK: json['ownerMediaOK'],
      renterMediaOK: json['renterMediaOK'],
      renterMediaUrls: json['renterMediaUrls'] != null ? List<String>.from(json['renterMediaUrls']) : [],
      ownerMediaUrls: json['ownerMediaUrls'] != null ? List<String>.from(json['ownerMediaUrls']) : [],
      error: json['error'],
    );
  }

  /// return a JSON Map of the meeting __Without the [tool] attribute__.
  Map<String, dynamic> toJson() {
    return {
      'ownerUID': ownerUID,
      'renterUID': renterUID,
      'ownerArrived': ownerArrived,
      'renterArrived': renterArrived,
      'toolDamaged': toolDamaged,
      'renterAdmitDamage': renterAdmitDamage,
      'compensationPrice': compensationPrice,
      'renterAcceptCompensationPrice': renterAcceptCompensationPrice,
      'ownerConfirmHandover': ownerConfirmHandover,
      'renterConfirmHandover': renterConfirmHandover,
      'disagreementCaseID': disagreementCaseID,
      'disagreementCaseSettled': disagreementCaseSettled,
      'disagreementCaseResult': disagreementCaseResult,
      'ownerMediaOK': ownerMediaOK,
      'renterMediaOK': renterMediaOK,
      'renterMediaUrls': renterMediaUrls,
      'ownerMediaUrls': ownerMediaUrls,
      'error': error,
    };
  }

  bool get bothArrived => ownerArrived && renterArrived;
  bool get bothHandedOver => ownerConfirmHandover && renterConfirmHandover;

  bool get isUserTheOwner => AuthServices.currentUid == ownerUID;
  String get userRole => isUserTheOwner ? 'owner' : 'renter';
  String get otherUserRole => !isUserTheOwner ? 'owner' : 'renter';

  // Arrival methods

  Future<void> setArrived(bool arrived) {
    return FirestoreServices.setReturnMeetingField(tool, '${userRole}Arrived', arrived);
  }

  /// did the current user arrive to the meeting
  bool get userArrived => isUserTheOwner ? ownerArrived : renterArrived;

  /// did the other user arrive to the meeting.
  ///
  /// other user = the renter if the current user is the owner and vice versa
  bool get otherUserArrived => !isUserTheOwner ? ownerArrived : renterArrived;

  // Tool damage methods

  /// set _'toolDamaged'_ to [isDamaged]
  ///
  /// only available to the owner
  Future<void>? setToolDamaged(bool? isDamaged) {
    if (isUserTheOwner) return FirestoreServices.setReturnMeetingField(tool, 'toolDamaged', isDamaged);
  }

  /// set _'renterAdmitDamage'_ to [doAdmit]
  ///
  /// only available to the renter
  Future<void>? setAdmitDamage(bool? doAdmit) {
    if (!isUserTheOwner) return FirestoreServices.setReturnMeetingField(tool, 'renterAdmitDamage', doAdmit);
  }

  // Compensation price methods

  /// set _'compensationPrice'_ to [price]
  ///
  /// only available to the owner
  Future<void>? setCompensationPrice(double price) {
    if (isUserTheOwner) return FirestoreServices.setReturnMeetingField(tool, 'compensationPrice', price);
  }

  /// set _'renterAcceptCompensationPrice'_ to [accepts]
  ///
  /// only available to the renter
  Future<void>? setAcceptCompensationPrice(bool? accepts) {
    if (!isUserTheOwner) return FirestoreServices.setReturnMeetingField(tool, 'renterAcceptCompensationPrice', accepts);
  }

  // Handover methods

  /// Set the _'ConfirmHandover'_ of the current user to [confirm]
  Future<void> setConfirmHandover(bool confirm) {
    return FirestoreServices.setReturnMeetingField(tool, '${userRole}ConfirmHandover', confirm);
  }

  /// did the current user confirm the handover.
  bool get userConfirmedHandover => isUserTheOwner ? ownerConfirmHandover : renterConfirmHandover;

  /// did the other user confirm the handover.
  ///
  /// other user = the renter if the current user is the owner and vice versa.
  bool get otherUserConfirmedHandover => !isUserTheOwner ? ownerConfirmHandover : renterConfirmHandover;

  // Media methods

  /// Set the _'MediaOK'_ of the current user to [isOk]
  ///
  /// _'{user}MediaOK'_ is set `true` when the user finish uploading thier media.
  Future<void> setMediaOk(bool isOk) {
    return FirestoreServices.setReturnMeetingField(tool, '${userRole}MediaOK', isOk);
  }

  /// Returns the _'MediaOK'_ of the current user
  ///
  /// _'{user}MediaOK'_ is set `true` when the user finish uploading thier media.
  bool get userMediaOK => isUserTheOwner ? ownerMediaOK : renterMediaOK;

  /// Returns the _'MediaOK'_ of the other user
  /// (i.e., the renter if the current user is the owner and vice versa).
  ///
  /// _'{user}MediaOK'_ is set `true` when the user finish uploading thier media.
  bool get otherUserMediaOK => !isUserTheOwner ? ownerMediaOK : renterMediaOK;

  /// Returns the media urls of the current user
  List<String> get userMediaUrls => isUserTheOwner ? ownerMediaUrls : renterMediaUrls;

  /// Returns the media urls of the other user
  /// (i.e., the renter if the current user is the owner and vice versa).
  List<String> get otherUserMediaUrls => !isUserTheOwner ? ownerMediaUrls : renterMediaUrls;

  /// uploads [file] to Storage and adds its url to the user's `MediaUrls` field in Firestore
  Future<void> addMedia(File file) async {
    // upload file
    final upload = await StorageServices.uploadReturnMeetingFile(
      file,
      tool.id,
      tool.acceptedRequestID!,
      AuthServices.currentUid!,
    );
    final url = await upload.ref.getDownloadURL();

    // update Firestore
    return FirestoreServices.setReturnMeetingField(
      tool,
      '${userRole}MediaUrls',
      FieldValue.arrayUnion([url]),
    );
  }

  /// removes [url] from the user's `MediaUrls` field in Firestore
  Future<void> removeMedia(String url) {
    return FirestoreServices.setReturnMeetingField(
      tool,
      '${userRole}MediaUrls',
      FieldValue.arrayRemove([url]),
    );
  }
}

// Code below is the permissions for the renter and owner for each state of the meeting
// The code is then converted form if-else to optional operator (?:) to paste in firestore.rules

// class ResR {
//   late ReturnMeeting data;
// }
// late ResR resource;
// onlyAllow(List x) {}
// bothArrived() {}

// owner() {
//   if (resource.data.disagreementCaseSettled != null) {
//     if (resource.data.disagreementCaseSettled == false) {
//       // 👮⏳ Disagreement case still processing
//       false;
//     } else {
//       // 👮✅
//       if (bothArrived() == true) {
//         // 🤝 both arrived
//         onlyAllow(['ownerArrived', 'ownerConfirmHandover']);
//       } else {
//         // 🧍 didn't both arrive
//         onlyAllow(['ownerArrived']);
//       }
//     }
//   } else {
//     // No disagreement case
//     if (bothArrived() == false) {
//       // 🧍
//       onlyAllow(['ownerArrived']);
//     } else {
//       // 🤝
//       if (resource.data.toolDamaged == null) {
//         // ❓ Tool unchecked
//         onlyAllow(['ownerArrived', 'toolDamaged']);
//       } else {
//         if (resource.data.toolDamaged == true) {
//           // 💔 Tool Damaged
//           if (resource.data.renterAdmitDamage != null) {
//             // Renter responded to claims
//             if (resource.data.renterAdmitDamage == true) {
//               // 😞 Admit damage
//               onlyAllow(['ownerArrived', 'toolDamaged']);
//             } else {
//               // 😡 Deny damage
//               if (resource.data.ownerMediaOK == true) {
//                 onlyAllow(['ownerArrived', 'toolDamaged', 'ownerMediaOK']);
//               } else {
//                 onlyAllow(['ownerArrived', 'toolDamaged', 'ownerMediaUrls', 'ownerMediaOK']);
//               }
//             }
//           } else {
//             // Renter hasn't responded to claims yet
//             onlyAllow(['ownerArrived', 'toolDamaged']);
//           }
//         } else {
//           // 💖 Tool Undamaged
//           onlyAllow(['ownerArrived', 'toolDamaged', 'ownerConfirmHandover']);
//         }
//       }
//     }
//   }
// }

// void renter() {
//   if (resource.data.disagreementCaseSettled != null) {
//     if (resource.data.disagreementCaseSettled == false) {
//       // 👮⏳ Disagreement case still processing
//       false;
//     } else {
//       // 👮✅
//       if (bothArrived() == true) {
//         // 🤝 both arrived
//         onlyAllow(['renterArrived', 'renterConfirmHandover']);
//       } else {
//         // 🧍 didn't both arrive
//         onlyAllow(['renterArrived']);
//       }
//     }
//   } else {
//     // No disagreement case
//     if (bothArrived() == false) {
//       // 🧍
//       onlyAllow(['renterArrived']);
//     } else {
//       // 🤝 bothArrived
//       if (resource.data.toolDamaged == null) {
//         // ❓ Tool unchecked
//         onlyAllow(['renterArrived']);
//       } else {
//         if (resource.data.toolDamaged == true) {
//           // 💔 Tool Damaged
//           if (resource.data.renterAdmitDamage != null) {
//             // Renter responded to claims
//             if (resource.data.renterAdmitDamage == true) {
//               // 😞 Admit damage
//               onlyAllow(['renterArrived']);
//             } else {
//               // 😡 Deny damage
//               if (resource.data.renterMediaOK == true) {
//                 onlyAllow(['renterArrived', 'renterAdmitDamage', 'renterMediaOK']);
//               } else {
//                 onlyAllow(['renterArrived', 'renterAdmitDamage', 'renterMediaUrls', 'renterMediaOK']);
//               }
//             }
//           } else {
//             // Renter hasn't responded to claims yet
//             onlyAllow(['renterArrived', 'renterAdmitDamage']);
//           }
//         } else {
//           // 💖 Tool Undamaged
//           onlyAllow(['renterArrived', 'renterConfirmHandover']);
//         }
//       }
//     }
//   }
// }
