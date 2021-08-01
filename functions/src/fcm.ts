import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const newNotification = functions.firestore
  .document('Users/{userID}/notifications/{notificationID}')
  .onCreate(async (snapshot, context) => {
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
      'data': {},
      'notification': {
        'title': 'Hi!',
        'body': 'This message was sent from the cloud ☁ 😲',
        'icons': 'https://www.gstatic.com/devrel-devsite/prod/v0492b3db79b8927fe2347ea2dc87c471b22f173331622ffd10334837d43ea37f/firebase/images/lockup.png',
      },
    };

    admin.messaging().sendToDevice(deviceTokens, payload);
  });
