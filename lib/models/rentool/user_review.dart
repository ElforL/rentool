class UserReview {
  final String creatorUID;
  final String targetUID;
  int value;
  String description;

  UserReview(
    this.creatorUID,
    this.targetUID,
    this.value,
    this.description,
  );

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      json['creatorUID'],
      json['targetUID'],
      json['value'],
      json['description'],
    );
  }

  Map<String, dynamic> toJson([List<String>? removedKeys]) {
    return {
      'creatorUID': creatorUID,
      'targetUID': targetUID,
      'value': value,
      'description': description,
    }..removeWhere((key, value) => removedKeys?.contains(key) ?? false);
  }
}
