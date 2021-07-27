// TODO change name
class ReturnMeeting {
  final String ownerUID;
  final String renterUID;

  /// did the owner arrive to the meeting place
  bool ownerArrived;

  /// did the renter arrive to the meeting place
  bool renterArrived;

  /// did the tool get checked for damages.
  bool toolChecked;

  /// is the tool damaged. `toolChecked` must be `true` to give [toolDamaged] a value.
  bool toolDamaged;

  /// does the renter admit the tool is damaged. Requires `toolDamaged` to be `true`.
  bool renterAdmitDamage;

  double compensationPrice;

  bool renterAcceptCompensationPrice;

  /// did the owner confirm the handover
  bool ownerConfirmHandover;

  /// did the renter confirm the handover
  bool renterConfirmHandover;

  String disagreementCaseID;

  /// was the disagreement case reviewed and given a result
  bool disagreementCaseSettled;

  /// is the tool damage according to disagreement case result
  bool disagreementCaseResult;

  /// did the owner arrive to the meeting place
  bool ownerMediaOK;

  /// did the renter arrive to the meeting place
  bool renterMediaOK;

  /// List of URLs to pictures/videos
  // TODO maybe move to disagreement case
  List<String> mediaUrls;

  ReturnMeeting(
    this.ownerUID,
    this.renterUID, {
    this.ownerArrived = false,
    this.renterArrived = false,
    this.toolChecked = false,
    this.toolDamaged,
    this.renterAdmitDamage,
    this.compensationPrice,
    this.renterAcceptCompensationPrice,
    this.ownerConfirmHandover = false,
    this.renterConfirmHandover = false,
    this.disagreementCaseID,
    this.disagreementCaseSettled,
    this.disagreementCaseResult,
    this.ownerMediaOK,
    this.renterMediaOK,
    this.mediaUrls,
  });

  factory ReturnMeeting.fromJson(Map<String, dynamic> json) {
    return ReturnMeeting(
      json['ownerUID'],
      json['renterUID'],
      ownerArrived: json['ownerArrived'],
      renterArrived: json['renterArrived'],
      toolChecked: json['toolChecked'],
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
      mediaUrls: json['mediaUrls'] != null ? List<String>.from(json['mediaUrls']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerUID': ownerUID,
      'renterUID': renterUID,
      'ownerArrived': ownerArrived,
      'renterArrived': renterArrived,
      'toolChecked': toolChecked,
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
      'mediaUrls': mediaUrls,
    };
  }

  bool get bothArrived => ownerArrived && renterArrived;
  bool get bothHandedOver => ownerConfirmHandover && renterConfirmHandover;

  bool isTheOwner(String uid) {
    return uid == ownerUID;
  }
}
