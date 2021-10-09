import 'package:cloud_functions/cloud_functions.dart';

class FunctionsServices {
  static Future<UpdateUsernameResponse> updateUsername(String newName) async {
    final callable = FirebaseFunctions.instance.httpsCallable('updateUsername');
    final result = await callable.call(newName);
    return UpdateUsernameResponse.fromJson(result.data);
  }

  static Future<UpdatePhotoResponse> updateUserPhoto(String newName) async {
    final callable = FirebaseFunctions.instance.httpsCallable('updateUserPhoto');
    final result = await callable.call(newName);
    return UpdatePhotoResponse.fromJson(result.data);
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

/// an abstract class for the response for some cloud functions e.g., `updateUsername()` and `updateUserPhoto()`
///
/// Some decendants:
/// * UpdateUsernameResponse
/// * UpdatePhotoUrlResponse
class FunctionResponse {
  final bool isSuccess;
  final String response;
  final Object? value;

  FunctionResponse(this.isSuccess, this.response, [this.value]);

  FunctionResponse.fromJson(Map<String, dynamic> json)
      : isSuccess = json['success'],
        response = json['response'],
        value = json['value'];
}

/// a class for the response of the cloud function `updateUsername()`
class UpdateUsernameResponse extends FunctionResponse {
  final String? username;

  UpdateUsernameResponse(bool isSuccess, String response, this.username) : super(isSuccess, response);

  UpdateUsernameResponse.fromJson(Map<String, dynamic> json)
      : username = json['username'],
        super.fromJson(json);
}

/// a class for the response of the cloud function `updateUserPhoto()`
class UpdatePhotoResponse extends FunctionResponse {
  final String? photoUrl;

  UpdatePhotoResponse(bool isSuccess, String response, this.photoUrl) : super(isSuccess, response);

  UpdatePhotoResponse.fromJson(Map<String, dynamic> json)
      : photoUrl = json['photoUrl'],
        super.fromJson(json);
}
