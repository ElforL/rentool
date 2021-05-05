class UserReview {
  final String creatorUID;
  final String targetUID;
  double value;
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
}
