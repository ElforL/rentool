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

export const updateUsername = functions.https.onCall(async (data, context) => {
  const response: {
    success: boolean;
    response: string;
    username: string | undefined;
  } = {
    'success': false,
    'response': '',
    'username': undefined,
  }
  const uid = context.auth?.uid;

  if (uid == null) {
    response.response = 'ERROR: This function must be called by a signed-in user.';
    return response;
  }

  if (typeof data === 'string') {
    try {
      const username = data.trim()
      const user = await admin.auth().updateUser(uid, {
        displayName: username,
      })
      admin.firestore().doc(`Users/${uid}`).update({
        'name': user.displayName,
      });

      response.success = true;
      response.response = `SUCCESS`;
      response.username = user.displayName;
      return response;
    } catch (error) {
      functions.logger.error(`An unexpected error occured while chaning the username of user with uid=${uid}. Data=${data}.`, error);
      response.response = `ERROR: An unexpected error occured.`;
      return response;
    }
  } else {
    response.response = `ERROR: Invalid parameter type. This function accepts only 1 string paramater. Recivied: ${typeof data}.`;
    return response;
  }
})

export const updateUserPhoto = functions.https.onCall(async (data, context) => {
  const response: {
    success: boolean;
    response: string;
    photoUrl: string | undefined;
  } = {
    'success': false,
    'response': '',
    'photoUrl': undefined,
  }
  const uid = context.auth?.uid;

  if (uid == null) {
    response.response = 'ERROR: This function must be called by a signed-in user.';
    return response;
  }


  if (typeof data === 'string') {
    try {
      var photoUrl = data.trim();
      // Check the validity of the url
      // URL constructor will throw an error if it's invalid
      try {
        new URL(photoUrl);
      } catch (_) {
        response.response = 'ERROR: Invalid url.';
        return response;
      }

      // Update
      const user = await admin.auth().updateUser(uid, {
        photoURL: photoUrl,
      })
      admin.firestore().doc(`Users/${uid}`).update({
        'photoURL': user.photoURL,
      });
      
      // Response
      response.success = true;
      response.response = `SUCCESS`;
      response.photoUrl = user.photoURL;
      return response;
    } catch (error) {
      functions.logger.error(`An unexpected error occured while chaning the photoUrl of user with uid=${uid}. Data=${data}.`, error);
      response.response = `ERROR: An unexpected error occured.`;
      return response;
    }
  } else {
    response.response = `ERROR: Invalid parameter type. This function accepts only 1 string paramater. Recivied: ${typeof data}.`;
    return response;
  }
})


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
        var avgAfter = totalWithoutVal / (numOfReviews - 1);
        if (isNaN(avgAfter)) avgAfter = 0;

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