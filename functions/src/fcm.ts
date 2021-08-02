import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const newNotification = functions.firestore
  .document('Users/{userID}/notifications/{notificationID}')
  .onCreate(async (snapshot, context) => {
    const docData = snapshot.data()!;
    if (docData.isRead ?? false) return null;

    const userID = context.params.userID;

    const devices = await admin.firestore().collection(`Users/${userID}/devices`).get();

    const deviceTokens: string[] = [];
    devices.docs.forEach((docReference, index, array) => {
      deviceTokens.push(docReference.id);
    });

    if (deviceTokens.length == 0) {
      // if there was no device tokens log it and end the function
      return functions.logger.log(
        'no device token found for user with UID:',
        userID,
      );
    }

    const payload = {
      'data': {
        'code': docData.code,
        'data': docData.data,
      },
    };

    admin.messaging().sendToDevice(deviceTokens, payload);
  });
