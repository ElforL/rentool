import 'package:cloud_firestore/cloud_firestore.dart';

class RentoolUser {
  final String uid;
  String name;
  double rating;
  CollectionReference reviews;
  CollectionReference tools;
  CollectionReference requests;

  RentoolUser(
    this.uid,
    this.name,
    this.rating,
    this.reviews,
    this.tools,
    this.requests,
  ) {
    if (rating > 5 || rating < 0) {
      throw ArgumentError('User rating must be between 0 and 5 inclusive. Recived $rating');
    }
  }

  factory RentoolUser.fromJson(Map<String, dynamic> json) {
    return RentoolUser(
      json['uid'],
      json['name'],
      json['rating'],
      json['reviews'],
      json['tools'],
      json['requests'],
      // (json['reviews'] as List).map((e) => UserReview.fromJson(e)).toList(),
      // (json['tools'] as List).map((e) => Tool.fromJson(e)).toList(),
      // (json['requests'] as List).map((e) => ToolRequest.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'rating': rating,
      'reviews': reviews,
      'tools': tools,
      'requests': requests,
    };
  }
}
