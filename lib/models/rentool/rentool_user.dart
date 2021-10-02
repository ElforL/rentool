import 'package:rentool/models/rentool/rentool_models.dart';

class RentoolUser {
  final String uid;
  String? photoURL;
  String name;
  double rating;
  int numOfReviews;
  List<UserReview>? reviews;
  List<Tool>? tools;
  List<ToolRequest>? requests;

  RentoolUser(
    this.uid,
    this.name,
    this.rating,
    this.numOfReviews, {
    this.photoURL,
    this.reviews,
    this.tools,
    this.requests,
  }) {
    if (rating > 5 || rating < 0) {
      throw ArgumentError('User rating must be between 0 and 5 inclusive. Received $rating');
    }
  }

  factory RentoolUser.fromJson(Map<String, dynamic> json) {
    List<UserReview>? _reviews;
    List<Tool>? _tools;
    List<ToolRequest>? _requests;
    if (json['reviews'] != null) _reviews = (json['reviews'] as List).map((e) => UserReview.fromJson(e)).toList();
    if (json['tools'] != null) _tools = (json['tools'] as List).map((e) => Tool.fromJson(e)).toList();
    if (json['requests'] != null) _requests = (json['requests'] as List).map((e) => ToolRequest.fromJson(e)).toList();
    return RentoolUser(
      json['uid'],
      json['name'] ?? '',
      json['rating'].toDouble(),
      json['numOfReviews'],
      photoURL: json['photoURL'],
      reviews: _reviews,
      tools: _tools,
      requests: _requests,
    );
  }

  Map<String, dynamic> toJson([List<String>? removedKeys, bool withLists = false]) {
    return {
      'uid': uid,
      'name': name,
      'rating': rating,
      'photoURL': photoURL,
      'numOfReviews': numOfReviews,
      if (reviews != null && withLists) 'reviews': reviews,
      if (tools != null && withLists) 'tools': tools,
      if (requests != null && withLists) 'requests': requests,
    }..removeWhere((key, value) => removedKeys?.contains(key) ?? false);
  }
}
