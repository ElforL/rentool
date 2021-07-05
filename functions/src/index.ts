import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// // Start writing Firebase Functions
// // https://firebase.google.com/docs/functions/typescript

admin.initializeApp();

/** 
 * handle tools' `acceptedRequestID` field changes
 * - if a new requst was added this function changes the request's `isAccepted` to true
 * - if `acceptedRequestID` changed to null this function changes the old request's `isAccepted` to false (if it still exist)
*/
export const acceptRequset =
  functions.firestore.document('Tools/{toolID}')
    .onUpdate(async (change, context) => {
      /** did `acceptedRequestID` field changed */
      const changedAcceptedID = change.before.data().acceptedRequestID != change.after.data().acceptedRequestID;
      if (changedAcceptedID) {
        const toolID = change.after.id;
        const oldRequestID = change.before.data().acceptedRequestID;
        const newRequestID = change.after.data().acceptedRequestID;
        if (newRequestID != null) {
          // accepted a new request
          return admin.firestore().doc(`Tools/${toolID}/requests/${newRequestID}`).update({ 'isAccepted': true });
        } else {
          // canceled accepted request
          // i.e., changed acceptedRequestID to null
          const docExists = (await admin.firestore().doc(`Tools/${toolID}/requests/${oldRequestID}`).get()).exists
          if (docExists) {
            return admin.firestore().doc(`Tools/${toolID}/requests/${oldRequestID}`).update({ 'isAccepted': false });
          } else {
            return null
          }
        }
      } else {
        return null;
      }
    });

export const requestWrite =
  functions.firestore.document('Tools/{toolID}/requests/{renterUID}')
    .onWrite(async (change, context) => {
      if (!change.after.exists) {
        // DELETE

        const docData = change.before.data();
        // if the request was accepted, remove its ID from `acceptedRequestID`
        if (docData && docData.isAccepted == true) {
          const toolID = docData.toolID;
          await admin.firestore().doc(`Tools/${toolID}`).update({ 'acceptedRequestID': null });
        }

        // delete the request snippet in the user subcollection
        const renterUID = change.before.id;
        return admin.firestore().doc(`Users/${renterUID}/requests/${docData!.toolID}`).delete();
      } else {
        // UPDATE OR CREATE

        // update/create the request snippet in the user's subcollection
        const docData = change.after.data();
        const renterUID = change.after.id;
        return admin.firestore().doc(`Users/${renterUID}/requests/${docData!.toolID}`).set(docData!);
      }
    });
