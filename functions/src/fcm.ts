import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';


let prodAdmin: admin.app.App;
const isOnLocalEmulator = process.env.FUNCTIONS_EMULATOR == 'true';
if (isOnLocalEmulator) {
  console.log('function running in local emulator');
  const serviceAccount = require('../secret/rentool-5a78c-firebase-adminsdk.json');
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
      deviceTokens.push(docReference.data()!.token);
    });

    if (deviceTokens.length == 0) {
      // if there was no device tokens log it and end the function
      return functions.logger.log(
        'no device token found for user with UID:',
        userID,
      );
    }

    const bodyArgs = docData.data.notificationBodyArgs;

    const data = docData.data;
    delete data.notificationBodyArgs;
    data.code = docData.code;
    data.userID = context.params.userID;
    data.notificationID = context.params.notificationID;

    const payload2: admin.messaging.MulticastMessage = {
      tokens: deviceTokens,
      data: data,
      // Set Android priority to "high"
      android: {
        priority: "normal",
        notification: {
          titleLocKey: `title_${docData.code}`,
          bodyLocKey: `body_${docData.code}`,
          bodyLocArgs: bodyArgs,
        }
      },
      // Add APNS (Apple) config
      apns: {
        payload: {
          aps: {
            alert: {
              titleLocKey: `title_${docData.code}`,
              locKey: `body_${docData.code}`,
              locArgs: bodyArgs,
            },
            contentAvailable: true,
          },
        },
        headers: {
          "apns-push-type": "background",
          "apns-priority": "5", // Must be `5` when `contentAvailable` is set to true.
          "apns-topic": "io.flutter.plugins.firebase.messaging", // bundle identifier
        },
      },
    };

    if (isOnLocalEmulator && prodAdmin != null) {
      console.log('Sending fcm in local emulator');
      return prodAdmin.messaging().sendMulticast(payload2);
    }
    return admin.messaging().sendMulticast(payload2);
  });
