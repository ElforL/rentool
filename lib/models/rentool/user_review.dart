class UserReview {
  final String creatorUID;
  final String targetUID;
  int value;
  String? description;

  UserReview(
    this.creatorUID,
    this.targetUID,
    this.value, [
    this.description,
  ])  : assert(creatorUID != targetUID, 'creatorUID must be different from targetUID: $creatorUID == $targetUID.'),
        assert(value >= 1 && value <= 5, 'Value must be between 1 and 5 inclusive: $value.'),
        assert(
          description == null ? true : description.length <= 500,
          'Description must be 500 characters max: ${description.length}',
        );

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      json['creatorUID'],
      json['targetUID'],
      json['value'],
      json['description'],
    );
  }

  Map<String, dynamic> toJson({List<String>? removedKeys, bool withUIDs = true}) {
    return {
      if (withUIDs) 'creatorUID': creatorUID,
      if (withUIDs) 'targetUID': targetUID,
      'value': value,
      'description': description,
    }..removeWhere((key, value) => removedKeys?.contains(key) ?? false);
  }
}
