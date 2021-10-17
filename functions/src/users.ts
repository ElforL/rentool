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
    statusCode: number;
    success: boolean;
    message: string | null;
    value: any;
    error: any;
  } = {
    'statusCode': 401,
    'success': false,
    'message': null,
    'value': null,
    'error': null,
  }
  const uid = context.auth?.uid;

  if (uid == null) {
    response.message = 'ERROR: This function must be called by a signed-in user.';
    response.error = {
      'type': 'unauthorized',
      'code': 'not-signed-in'
    };
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

      response.statusCode = 200;
      response.success = true;
      response.message = `SUCCESS`;
      response.value = user.displayName;
      return response;
    } catch (error) {
      functions.logger.error(`An unexpected error occured while chaning the username of user with uid=${uid}. Data=${data}.`, error);
      response.message = `ERROR: An unexpected error occured.`;
      response.statusCode = 500;
      response.error = {
        'type': 'internal-server-error',
        'code': 'internal-server-error'
      };
      return response;
    }
  } else {
    response.message = `ERROR: Invalid parameter type. This function accepts only 1 string paramater. Recivied: ${typeof data}.`;
    response.statusCode = 400;
    response.error = {
      'type': 'bad-request',
      'code': 'invalid-paramaters'
    };
    return response;
  }
})

export const updateUserPhoto = functions.https.onCall(async (data, context) => {
  const response: {
    statusCode: number;
    success: boolean;
    message: string | null;
    value: any;
    error: any;
  } = {
    'statusCode': 401,
    'success': false,
    'message': null,
    'value': null,
    'error': null,
  }
  const uid = context.auth?.uid;

  if (uid == null) {
    response.message = 'ERROR: This function must be called by a signed-in user.';
    response.statusCode = 401;
    response.error = {
      'type': 'unauthorized',
      'code': 'not-signed-in'
    };
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
        response.message = 'ERROR: Invalid url.';
        response.statusCode = 400;
        response.error = {
          'type': 'bad-request',
          'code': 'invalid-url'
        };
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
      response.message = `SUCCESS`;
      response.statusCode = 200;
      response.value = user.photoURL;
      return response;
    } catch (error) {
      functions.logger.error(`An unexpected error occured while chaning the photoUrl of user with uid=${uid}. Data=${data}.`, error);
      response.message = `ERROR: An unexpected error occured.`;
      response.statusCode = 500;
      response.error = {
        'type': 'internal-server-error',
        'code': 'internal-server-error'
      };
      return response;
    }
  } else {
    response.message = `ERROR: Invalid parameter type. This function accepts only 1 string paramater. Recivied: ${typeof data}.`;
    response.statusCode = 400;
    response.error = {
      'type': 'bad-request',
      'code': 'invalid-paramaters'
    };
    return response;
  }
})

/// paramaters => ({uid: string, reason: string})
export const banUser = functions.https.onCall(async (data, context) => {
  const response: {
    statusCode: number;
    success: boolean;
    message: string | null;
    value: any;
    error: any;
  } = {
    'statusCode': 401,
    'success': false,
    'message': null,
    'value': null,
    'error': null,
  }

  if (context.auth?.token.admin !== true) {
    response.statusCode = 403;
    response.error = {
      'type': 'unauthorized',
      'code': 'not-an-admin'
    };
    return response;
  }

  if (typeof data.uid !== 'string' || typeof data.reason !== 'string') {
    response.message = `ERROR: Invalid parameters. This function accepts a map/object whith the keys 'uid' and 'reason' as: {'uid': string; 'reason': string;}. Recivied type: ${typeof data}.`;
    response.statusCode = 400;
    response.error = {
      'type': 'bad-request',
      'code': 'invalid-paramaters'
    };
    return response;
  }

  const uid = data.uid;
  const reason = data.reason;

  // Disable the user in auth
  // This will prevent the user from logging in or refreshing his/her access token.
  try {
    await admin.auth().updateUser(uid, {
      disabled: true,
    });

  } catch (error) {
    // This function's here to prevent the error:
    // `error TS1196: Catch clause variable cannot have a type annotation.`
    function handleError(e: any) {
      if (e.code === 'auth/user-not-found') {
        response.message = 'ERROR: There is no user record corresponding to the provided uid';
        response.statusCode = 400;
        response.error = {
          'type': 'bad-request',
          'code': 'no-user-with-provided-uid'
        };
        return response;
      }
      functions.logger.error(`An unexpected error occured while banning the user with uid=${uid}. Data=${data}.`, error);
      response.message = 'ERROR: An unexpected error occured';
      response.statusCode = 500;
      response.error = {
        'type': 'internal-server-error',
        'code': 'internal-server-error'
      };
      return response;
    }

    return handleError(error);
  }

  // Add the user's id number (if found) to the bannedList collection
  try {
    const doc = await admin.firestore().doc(`Users/${uid}/private/ID/`).get();
    const idNumber = doc.data()?.idNumber;
    if (idNumber != null) {
      await admin.firestore().doc(`bannedList/${idNumber}/`).set({
        'idNumber': idNumber,
        'uid': uid,
        'reason': reason,
        'admin': context.auth.uid,
        'ban_time': admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  } catch (error) {
    functions.logger.error(`An unexpected error occured while banning the user ID number with uid=${uid}. Data=${data}.`, error);
    response.message = "ERROR: The user was disabled but there was a problem banning the user's ID number";
    response.statusCode = 202;
    response.error = {
      'type': 'internal-server-error',
      'code': 'user-disabled-but-id-not-banned'
    };
    return response;
  }

  try {
    await admin.firestore().doc(`bannedUsers/${uid}/`).set({
      'uid': uid,
      'reason': reason,
      'admin': context.auth.uid,
      'ban_time': admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (_) { }

  response.success = true;
  response.message = 'SUCCESS';
  response.statusCode = 200;
  response.value = true;
  return response;
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
        var avgAfter = totalWithoutVal / (numOfReviews - 1);
        // isNaN is caused be dividing 0/0
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