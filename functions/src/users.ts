import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const authChange = functions.auth.user().onCreate((user, context) => {
  return admin.firestore().doc(`Users/${user.uid}`).set({
    'name': user.displayName,
    'photoURL': user.photoURL,
    'rating': 0,
    'numOfReviews': 0,
  });
});

export const userDocChange = functions.firestore.document('Users/{userID}').onUpdate(async (change, context) => {
  const uid = context.params.userID;
  const afterData = change.after.data();

  console.log(`changing user(${uid})'s displayName to ${afterData.name}`);

  return admin.auth().updateUser(uid, {
    displayName: afterData.name,
    photoURL: afterData.photoURL,
  });
});

export const reviewWrite = functions.firestore.document('Users/{userID}/reviews/{reviewerUID}')
  .onWrite(async (change, context) => {
    const uid = context.params.userID;
    const reviewerUID = context.params.reviewerUID;
    const isDelete = !change.after.exists;
    const isNew = !change.before.exists;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    const userDoc = admin.firestore().doc(`Users/${uid}`);


    if (isDelete) {
      return admin.firestore().runTransaction(async (transaction) => {
        // Read the data
        const userData = await transaction.get(userDoc);

        // Process
        const rating = userData.data()!.rating;
        const numOfReviews = userData.data()!.numOfReviews;

        const reviewValue = beforeData!.value;

        const totalWithoutVal = (rating * numOfReviews) - reviewValue;
        const avgAfter = totalWithoutVal / (numOfReviews - 1);

        // Update
        console.log(`Deleted review on user(${uid}) from user(${reviewerUID})`);
        return transaction.update(userDoc, {
          'rating': avgAfter,
          'numOfReviews': numOfReviews - 1,
        });
      })
    } else {
      return admin.firestore().runTransaction(async (transaction) => {
        // Read the data
        const userData = await transaction.get(userDoc);

        // Process
        const rating = userData.data()!.rating;
        const numOfReviews = userData.data()!.numOfReviews;
        const reviewValue = afterData!.value;

        const oldTotal = rating * numOfReviews;

        var newAvg;
        var newNumOfReviews;
        if (isNew) {
          // New review
          console.log(`new review on user(${uid}) from user(${reviewerUID})`);
          newAvg = (oldTotal + reviewValue) / (numOfReviews + 1);
          newNumOfReviews = numOfReviews + 1;
        } else {
          // change review value
          console.log(`Update review on user(${uid}) from user(${reviewerUID})`);
          const oldReviewValue = beforeData!.value;
          newAvg = ((oldTotal - oldReviewValue) + reviewValue) / numOfReviews;
          newNumOfReviews = numOfReviews;
        }

        // Update
        return transaction.update(userDoc, {
          'rating': newAvg,
          'numOfReviews': newNumOfReviews,
        });
      })
    }
  });