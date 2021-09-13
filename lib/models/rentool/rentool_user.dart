import 'package:rentool/models/rentool/rentool_models.dart';

class RentoolUser {
  final String uid;
  String? photoURL;
  String name;
  double rating;
  List<UserReview>? reviews;
  List<Tool>? tools;
  List<ToolRequest>? requests;

  RentoolUser(
    this.uid,
    this.name,
    this.rating, {
    this.photoURL,
    this.reviews,
    this.tools,
    this.requests,
  }) {
    if (rating > 5 || rating < 0) {
      throw ArgumentError('User rating must be between 0 and 5 inclusive. Recived $rating');
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
      json['name'],
      json['rating'].toDouble(),
      photoURL: json['photoURL'],
      reviews: _reviews,
      tools: _tools,
      requests: _requests,
    );
  }

  Map<String, dynamic> toJson([List<String>? removedKeys]) {
    return {
      'uid': uid,
      'name': name,
      'rating': rating,
      'photoURL': photoURL,
    }..removeWhere((key, value) => removedKeys?.contains(key) ?? false);
  }
}
