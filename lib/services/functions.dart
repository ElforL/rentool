import 'package:cloud_functions/cloud_functions.dart';

class FunctionsServices {
  static Future<FunctionResponse> updateUsername(String newName) async {
    final callable = FirebaseFunctions.instance.httpsCallable('updateUsername');
    final result = await callable.call(newName);
    return FunctionResponse.fromJson(result.data);
  }

  static Future<FunctionResponse> updateUserPhoto(String newName) async {
    final callable = FirebaseFunctions.instance.httpsCallable('updateUserPhoto');
    final result = await callable.call(newName);
    return FunctionResponse.fromJson(result.data);
  }

  static Future<FunctionResponse> banUser(String uid, String reason) async {
    final msg = {'uid': uid, 'reason': reason};
    final callable = FirebaseFunctions.instance.httpsCallable('banUser');
    final result = await callable.call(msg);
    return FunctionResponse.fromJson(result.data);
  }
}

//   .oooooo.   oooo
//  d8P'  `Y8b  `888
// 888           888   .oooo.    .oooo.o  .oooo.o  .ooooo.   .oooo.o
// 888           888  `P  )88b  d88(  "8 d88(  "8 d88' `88b d88(  "8
// 888           888   .oP"888  `"Y88b.  `"Y88b.  888ooo888 `"Y88b.
// `88b    ooo   888  d8(  888  o.  )88b o.  )88b 888    .o o.  )88b
//  `Y8bood8P'  o888o `Y888""8o 8""888P' 8""888P' `Y8bod8P' 8""888P'

class FunctionResponse {
  final int statusCode;
  final bool isSuccess;
  final String? message;
  final Object? value;
  final Object? error;

  FunctionResponse(this.statusCode, this.isSuccess, {this.message, this.value, this.error});

  factory FunctionResponse.fromJson(Map<String, dynamic> json) {
    return FunctionResponse(
      json['statusCode'],
      json['success'],
      message: json['message'],
      value: json['value'],
      error: json['error'],
    );
  }
}
