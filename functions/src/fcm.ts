import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';


let prodAdmin: admin.app.App;
const isOnLocalEmulator = process.env.FUNCTIONS_EMULATOR == 'true';
if (isOnLocalEmulator) {
  console.log('function running in local emulator');
  const serviceAccount = require('../secret/rentool-5a78c-firebase-adminsdk-q4wqx-6c6f8750b2.json');
  prodAdmin = admin.initializeApp(
    {
      credential: admin.credential.cert(serviceAccount),
    },
    'Production',
  );
}

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

    if (isOnLocalEmulator && prodAdmin != null) {
      console.log('Sending fcm in local emulator');
      return prodAdmin.messaging().sendToDevice(deviceTokens, payload);
    }
    return admin.messaging().sendToDevice(deviceTokens, payload);
  });
