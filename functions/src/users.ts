import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const authChange = functions.auth.user().onCreate((user, context) => {
  admin.firestore().doc(`Users/${user.uid}`).set({
    'name': user.displayName,
    'photoURL': user.photoURL,
    'rating': 0,
    'numOfReviews': 0,
  });
});

export const userDocChange = functions.firestore.document('Users/{userID}').onUpdate(async (change, context) => {
  const uid = context.params.userID;
  const afterData = change.after.data();

  console.log(afterData);

  return admin.auth().updateUser(uid, {
    displayName: afterData.name,
    photoURL: afterData.photoURL,
  });
});

