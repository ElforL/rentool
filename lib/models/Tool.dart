import 'package:cloud_firestore/cloud_firestore.dart';

class Tool {
  final String id;
  final String ownerUID;
  String name;
  String description;
  double rentPrice;
  double insuranceAmount;
  List<String> media;
  String location;
  bool isAvailable;
  CollectionReference requests;
  String? acceptedRequestID;

  Tool(
    this.id,
    this.ownerUID,
    this.name,
    this.description,
    this.rentPrice,
    this.insuranceAmount,
    this.media,
    this.location,
    this.isAvailable,
    this.requests, [
    this.acceptedRequestID,
  ]);

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      json['id'],
      json['ownerUID'],
      json['name'],
      json['description'],
      json['rentPrice'],
      json['insuranceAmount'],
      json['media'],
      json['location'],
      json['isAvailable'],
      json['requests'],
      // (json['requests'] as List).map((e) => ToolRequest.fromJson(e)).toList(),
      json['acceptedRequestID'],
    );
  }
}
