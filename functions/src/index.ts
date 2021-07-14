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
          // create a meeting doc
          await admin.firestore().doc(`Tools/${toolID}/meetings/${newRequestID}`).set({
            // 'isActive': true,
            'ownerUID': change.after.data().ownerUID,
            'owner_arrived': false,
            'owner_pics_ok': false,
            'owner_ids_ok': false,
            'owner_pics_urls': [],
            'renterUID': newRequestID,
            'renter_arrived': false,
            'renter_pics_ok': false,
            'renter_ids_ok': false,
            'renter_pics_urls': [],
          });
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

// Creates an entry in db/idsList when the user sets thier ID number
export const IdCreated =
  functions.firestore.document('Users/{uid}/private/ID')
    .onCreate(async (snapshot, context) => {
      const idNumber = snapshot.data().idNumber;
      const uid = snapshot.ref.parent.parent!.id;
      return admin.firestore().doc(`idsList/${idNumber}`).set({'uid':uid, 'time':snapshot.createTime});
    });