import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';


let prodAdmin: admin.app.App;
const isOnLocalEmulator = process.env.FUNCTIONS_EMULATOR == 'true';
const isOnGithubActions = process.env.GITHUB_ACTIONS == 'true';
if (isOnLocalEmulator && !isOnGithubActions) {
  console.log('function running in local emulator');
  const serviceAccount = require('../secret/rentool-5a78c-firebase-adminsdk.json');
  prodAdmin = admin.initializeApp(
    {
      credential: admin.credential.cert(serviceAccount),
    },
    'Production',
  );
}

export const newNotification = functions.region('europe-west3').firestore
  .document('Users/{userID}/notifications/{notificationID}')
  .onCreate(async (snapshot, context) => {
    const docData = snapshot.data()!;
    if (docData.isRead ?? false) return null;

    const userID = context.params.userID;

    const devices = await admin.firestore().collection(`Users/${userID}/devices`).get();

    const deviceTokens: string[] = [];
    devices.docs.forEach((docReference, index, array) => {
      const deviceToken = docReference.data()!.token;
      if (deviceToken != null)
        deviceTokens.push(deviceToken);
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


/**
* create a new doc in the user's notification collections which also invokes `newNotification()` and sends the user an FCM message
* @param userUID the user's uid
* @param code
* Notifications codes:
* - `REQ_REC`: request received
* - `REQ_ACC`: request accepted
* - `REQ_DEL`: request deleted
* - `REN_START`: rent started
* - `REN_END`: rent ended
* - `DC_DAM`: disagreement case settled and tool is damaged
* - `DC_NDAM`: disagreement case settled and tool is not damaged
* @param data the notification data required for each code
* - `REQ_REC`: toolID, requestID, toolName, renterName
* - `REQ_ACC`: toolID, requestID, toolName,
* - `REQ_DEL`: toolID, requestID, toolName,
* - `REN_START`: toolID, toolName, renterName, ownerName, renterUID
* - `REN_END`: toolID, toolName, renterName, ownerName, renterUID
* - `DC_DAM`: toolID, toolName
* - `DC_NDAM`: toolID, toolName
* @returns A Promise resolved with a DocumentReference pointing to the newly created document after it has been written to the backend.
*/
export function addNotification(userUID: string, code: string, data: any)
  : Promise<FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>> {
  const notifsCollection = admin.firestore().collection(`Users/${userUID}/notifications`);
  return notifsCollection.add({
    'code': code,
    'data': data,
    'time': admin.firestore.FieldValue.serverTimestamp(),
    'isRead': false,
  });
}