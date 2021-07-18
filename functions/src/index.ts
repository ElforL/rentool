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
export const toolUpdated =
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
            'isActive': true,
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
            // if the meeting was done and succesful and a rent object/doc was created
            'rent_started': false,
            // any errors that could occur with the meeting e.g., payment fail, database error... etc
            // TODO consider changing it to list in case there were multiple erros
            'error': null, 
          });
          // accepted a new request
          return admin.firestore().doc(`Tools/${toolID}/requests/${newRequestID}`).update({ 'isAccepted': true });
        } else {
          // canceled accepted request
          // i.e., changed acceptedRequestID to null

          // set its meeting to inactive
          await admin.firestore().doc(`Tools/${toolID}/meetings/${oldRequestID}`).update({'isActive': false});

          // change the request's `isAccepted` to false if it still exist (i.e., it wasn't deleted)
          const oldRequestDoc = await admin.firestore().doc(`Tools/${toolID}/requests/${oldRequestID}`)
          if ((await oldRequestDoc.get()).exists) {
            return oldRequestDoc.update({ 'isAccepted': false });
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

export const meetingInfoChanged =
  functions.firestore.document('Tools/{toolID}/meetings/{requestID}')
    .onUpdate(async (change, context) => {
      const after = change.after.data();
      const before = change.before.data();

      // if either the owner or renter changed arrive from `true` to `false`
      if(before.owner_arrived && !after.owner_arrived || before.renter_arrived && !after.renter_arrived){
        return change.after.ref.update({
          'owner_pics_ok': false,
          'owner_ids_ok': false,
          'renter_pics_ok': false,
          'renter_ids_ok': false,
        });
      }

      // if either the owner or renter changed [pics] from `true` to `false`
      if(before.owner_pics_ok && !after.owner_pics_ok || before.renter_pics_ok && !after.renter_pics_ok){
        // if `owner_id` or `renter_id` wasn't null (which mean they were both agreed on pics)
        // set the IDs to null
        if(before.owner_id != null || before.renter_id != null){
          await change.after.ref.update({
            'owner_id': null, 
            'renter_id': null,
          });
        }
        return change.after.ref.update({
          'owner_ids_ok': false,
          'renter_ids_ok': false,
        });
      }

      // if either the owner or renter changed [pics] from `false` to `true`
      if(!before.owner_pics_ok && after.owner_pics_ok || !before.renter_pics_ok && after.renter_pics_ok){
        // when BOTH agree on pics set the IDs
        if(after.owner_pics_ok && after.renter_pics_ok){
          const ownerUID = after.ownerUID;
          const renterUID = after.renterUID;
          const ownerIdDoc = await admin.firestore().doc(`Users/${ownerUID}/private/ID`).get();
          const renterIdDoc = await admin.firestore().doc(`Users/${renterUID}/private/ID`).get();
          return change.after.ref.update({
            'owner_id': ownerIdDoc.data()?.idNumber, 
            'renter_id': renterIdDoc.data()?.idNumber,
          });
        }else 
          return null;
      }

      // if the owner was ok with IDs then wasn't, change the renter's IDs-OK to false aswell
      if(before.owner_ids_ok && !after.owner_ids_ok){
        return change.after.ref.update({
          'renter_ids_ok': false,
        });
      }

      // if the renter was ok with IDs then wasn't, change the owner's IDs-OK to false aswell
      if(before.renter_ids_ok && !after.renter_ids_ok){
        return change.after.ref.update({
          'owner_ids_ok': false,
        });
      }

      if(!before.owner_ids_ok && after.owner_ids_ok || !before.renter_ids_ok && after.renter_ids_ok){
        // when they both agree on IDs
        if(after.owner_ids_ok && after.renter_ids_ok){
          // remove the IDs strings from meetings doc
          await change.after.ref.update({
            'owner_id': null, 
            'renter_id': null,
          });
          try {
            const rentsCollection = admin.firestore().collection('rents/')
            // Create rent doc
            const rentDoc = await rentsCollection.add({
              toolID : change.after.ref.parent.parent!.id,
              requestID: change.after.id,
              startTime: admin.firestore.Timestamp.now(),
              endTime: null,
            });
            // Update the tool doc
            const toolDoc = admin.firestore().doc(`Tools/${context.params.toolID}`)
            await toolDoc.update({
              'currentRent': rentDoc,
            });
            // Update the meeting doc
            return change.after.ref.update({
              'rent_started': true, 
            });
          } catch (error) {
            return change.after.ref.update({
              'error': error, 
            });
          }
        }else{
          return null;
        }
      }

      return null;
    });