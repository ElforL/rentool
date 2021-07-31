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
export const toolUpdated = functions.firestore.document('Tools/{toolID}')
  .onUpdate(async (change, context) => {
    /** did `acceptedRequestID` field changed */
    const changedAcceptedID = change.before.data().acceptedRequestID != change.after.data().acceptedRequestID;
    if (changedAcceptedID) {
      const toolID = change.after.id;
      const oldRequestID = change.before.data().acceptedRequestID;
      const newRequestID = change.after.data().acceptedRequestID;
      if (newRequestID != null) {
        const renterUID = (await admin.firestore().doc(`Tools/${toolID}/requests/${newRequestID}`).get()).data()!.renterUID;
        // create a deliver_meeting doc
        await admin.firestore().doc(`Tools/${toolID}/deliver_meetings/${newRequestID}`).set({
          'isActive': true,
          'ownerUID': change.after.data().ownerUID,
          'owner_arrived': false,
          'owner_pics_ok': false,
          'owner_ids_ok': false,
          'owner_pics_urls': [],
          'renterUID': renterUID,
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
        // changed acceptedRequestID to null
        // i.e., canceled accepted request

        // set its meeting to inactive
        await admin.firestore().doc(`Tools/${toolID}/deliver_meetings/${oldRequestID}`).update({ 'isActive': false });

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

export const requestWrite = functions.firestore.document('Tools/{toolID}/requests/{requestID}')
  .onWrite(async (change, context) => {
    if (!change.after.exists) {
      // DELETE

      const docData = change.before.data()!;
      // if the request was accepted, remove its ID from `acceptedRequestID`
      if (docData && docData.isAccepted == true) {
        const toolID = docData.toolID;
        await admin.firestore().doc(`Tools/${toolID}`).update({ 'acceptedRequestID': null });
      }

      // delete the request snippet in the user subcollection
      const renterUID = docData.renterUID;
      const renterRequestDoc = admin.firestore().doc(`Users/${renterUID}/requests/${docData.toolID}`);
      return renterRequestDoc.delete();
    } else {
      // UPDATE OR CREATE

      // update/create the request snippet in the user's subcollection
      const docData = change.after.data()!;
      const renterUID = docData.renterUID;
      const renterRequestDoc = await admin.firestore().doc(`Users/${renterUID}/requests/${docData.toolID}`).get();
      if (renterRequestDoc.exists && renterRequestDoc.data()!.id != change.after.id) {
        // if the user already has a request doc for the tool in his `requests` subcollection (i.e., already sent a request to this tool)
        // then delete the new request
        return change.after.ref.delete();
      } else {
        // otherwise, create the request doc
        docData.id = change.after.id;
        return renterRequestDoc.ref.set(docData);
      }
    }
  });

// Creates an entry in db/idsList when the user sets thier ID number
export const IdCreated = functions.firestore.document('Users/{uid}/private/ID')
  .onCreate(async (snapshot, context) => {
    const idNumber = snapshot.data().idNumber;
    const uid = snapshot.ref.parent.parent!.id;
    return admin.firestore().doc(`idsList/${idNumber}`).set({ 'uid': uid, 'time': snapshot.createTime });
  });

export const deliverMeetingUpdated = functions.firestore.document('Tools/{toolID}/deliver_meetings/{requestID}')
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();

    const ownerUID = after.ownerUID;
    const renterUID = after.renterUID;

    // if either the owner or renter changed arrive from `true` to `false`
    if (before.owner_arrived && !after.owner_arrived || before.renter_arrived && !after.renter_arrived) {
      return change.after.ref.update({
        'owner_pics_ok': false,
        'owner_ids_ok': false,
        'renter_pics_ok': false,
        'renter_ids_ok': false,
      });
    }

    // if either the owner or renter changed [pics] from `true` to `false`
    if (before.owner_pics_ok && !after.owner_pics_ok || before.renter_pics_ok && !after.renter_pics_ok) {
      // if `owner_id` or `renter_id` wasn't null (which mean they were both agreed on pics)
      // set the IDs to null
      if (before.owner_id != null || before.renter_id != null) {
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
    if (!before.owner_pics_ok && after.owner_pics_ok || !before.renter_pics_ok && after.renter_pics_ok) {
      // when BOTH agree on pics set the IDs
      if (after.owner_pics_ok && after.renter_pics_ok) {
        const ownerIdDoc = await admin.firestore().doc(`Users/${ownerUID}/private/ID`).get();
        const renterIdDoc = await admin.firestore().doc(`Users/${renterUID}/private/ID`).get();
        return change.after.ref.update({
          'owner_id': ownerIdDoc.data()?.idNumber,
          'renter_id': renterIdDoc.data()?.idNumber,
        });
      } else {
        return null;
      }
    }

    // if the owner was ok with IDs then wasn't, change the renter's IDs-OK to false aswell
    if (before.owner_ids_ok && !after.owner_ids_ok) {
      return change.after.ref.update({
        'renter_ids_ok': false,
      });
    }

    // if the renter was ok with IDs then wasn't, change the owner's IDs-OK to false aswell
    if (before.renter_ids_ok && !after.renter_ids_ok) {
      return change.after.ref.update({
        'owner_ids_ok': false,
      });
    }

    if (!before.owner_ids_ok && after.owner_ids_ok || !before.renter_ids_ok && after.renter_ids_ok) {
      // when they both agree on IDs
      if (after.owner_ids_ok && after.renter_ids_ok) {
        // remove the IDs strings from meetings doc
        await change.after.ref.update({
          'owner_id': null,
          'renter_id': null,
        });
        try {
          const rentsCollection = admin.firestore().collection('rents/')
          // Create rent doc
          const rentDoc = await rentsCollection.add({
            toolID: change.after.ref.parent.parent!.id,
            requestID: change.after.id,
            startTime: admin.firestore.Timestamp.now(),
            endTime: null,
          });
          // Update the tool doc
          const toolDoc = admin.firestore().doc(`Tools/${context.params.toolID}`)
          await toolDoc.update({
            'currentRent': rentDoc.id,
          });
          // Update the request `isRented` field
          const requestDoc = admin.firestore().doc(`Tools/${context.params.toolID}/requests/${context.params.requestID}`)
          await requestDoc.update({
            'isRented': true,
          });

          // Create return meeting doc
          const returnMeetingDoc = admin.firestore().doc(`Tools/${context.params.toolID}/return_meetings/${context.params.requestID}`)
          await returnMeetingDoc.set({
            'isActive': true,
            'ownerUID': ownerUID,
            'renterUID': renterUID,
            'ownerArrived': false,
            'renterArrived': false,
            'toolDamaged': null,
            'renterAdmitDamage': null,
            'compensationPrice': null,
            'renterAcceptCompensationPrice': null,
            'ownerConfirmHandover': false,
            'renterConfirmHandover': false,
            'disagreementCaseID': null,
            'disagreementCaseSettled': null,
            'disagreementCaseResult': null,
            'ownerMediaOK': false,
            'renterMediaOK': false,
            'renterMediaUrls': [],
            'ownerMediaUrls': [],
          });

          // Update the meeting doc
          return change.after.ref.update({
            'rent_started': true,
          });
        } catch (error) {
          // TODO undo things done before the error. transactions??
          return change.after.ref.update({
            'error': error.toString(),
          });
        }
      } else {
        return null;
      }
    }

    return null;
  });

export const returnMeetingUpdated = functions.firestore.document('Tools/{toolID}/return_meetings/{requestID}')
  .onUpdate(async (change, context) => {
    const toolID = context.params.toolID;
    const requestID = context.params.requestID;
    const newData = change.after.data();
    const oldData = change.before.data();

    // if renterArrived CHANGED to `false` set everything that comes after it to false
    if (!oldData.renterArrived && newData.renterArrived) {
      // same for other fields
      var updates;
      if (newData.disagreementCaseSettled != null) {
        // if there is a disagreement case don't change `renterAdmitDamage` and `renterMediaOK`
        // because 1- changing them won't change anythin 2- they must be `false` and `true` respectively for a disagreement case to have been created
        updates = {
          'renterAcceptCompensationPrice': null,
          'renterConfirmHandover': false,
        };
      } else {
        updates = {
          'renterAdmitDamage': null,
          'renterAcceptCompensationPrice': null,
          'renterMediaOK': false,
          'renterConfirmHandover': false,
        };
      }
      return change.after.ref.update(updates);
    }

    // if ownerArrived CHANGED to `false` set everything that comes after it to false
    if (!oldData.ownerArrived && newData.ownerArrived) {
      var updates;
      if (newData.disagreementCaseSettled != null) {
        // if there is a disagreement case don't change `toolDamaged` and `ownerMediaOK`
        // because 1- changing them won't change anythin 2- they must be both `true` for a disagreement case to have been created
        updates = {
          'compensationPrice': null,
          'ownerConfirmHandover': false,
        };
      } else {
        updates = {
          'toolDamaged': null,
          'compensationPrice': null,
          'ownerMediaOK': false,
          'ownerConfirmHandover': false,
        };
      }
      return change.after.ref.update(updates);
    }

    // when any [mediaOk] change from `false` to `true`
    if (!oldData.ownerMediaOK && newData.ownerMediaOK || !oldData.renterMediaOK && oldData.renterMediaOK) {
      // when BOTH [mediaOk] are true
      if (newData.ownerMediaOK && newData.renterMediaOK) {
        // create disagreement case
        const disagreementsCollection = admin.firestore().collection('disagreementCases/');
        const disagreementDoc = await disagreementsCollection.add({
          'toolID': toolID,
          'requestID': requestID,
          'ownerUID': newData.ownerUID,
          'renterUID': newData.renterUID,
          'ownerMedia': newData.ownerMediaUrls,
          'renterMedia': newData.renterMediaUrls,
          'Admin': null,
          'Result_IsToolDamaged': null,
          'ResultDescription': null,
        });

        // update return meeting doc
        return change.after.ref.update({
          'disagreementCaseID': disagreementDoc.id,
          'disagreementCaseSettled': false,
          'disagreementCaseResult': null,
        });
      }
    }

    // when any [ConfirmHandover] change from `false` to `true`
    if (!oldData.ownerConfirmHandover && newData.ownerConfirmHandover || !oldData.renterConfirmHandover && newData.renterConfirmHandover) {
      // when BOTH [ConfirmHandover] are true
      if (newData.ownerConfirmHandover && newData.renterConfirmHandover) {
        // after both_handover 
        // calculate total - and process payment
        // end rent 
        // set isActive to false

        // calculate total - and process payment
        const requestDoc = admin.firestore().doc(`Tools/${toolID}/requests/${requestID}`);
        const requstData = (await requestDoc.get()).data()!;
        const insuranceAmount = requstData.insuranceAmount;
        const compensationPrice = newData.compensationPrice ?? 0;

        const total_to_renter = insuranceAmount - compensationPrice;
        const total_to_owner = compensationPrice;

        try {
          if (total_to_renter != 0) {
            // send the money
          }
          if (total_to_owner != 0) {
            // send the money
          }
        } catch (error) {
          // if an error occured during payment don't end rent
          console.log(`An error occured after handover\n${error.toString()}`)
          return null;
        }

        // end rent
        const toolDoc = admin.firestore().doc(`Tools/${toolID}`);
        const toolData = (await toolDoc.get()).data()!;

        const rentDoc = admin.firestore().doc(`rents/${toolData.currentRent}`)
        rentDoc.update({
          endTime: admin.firestore.Timestamp.now(),
        });
        // Update the tool doc
        await toolDoc.update({
          'currentRent': null,
          'acceptedRequestID': null,
        });


        // move the request to `previous_requests` subcollection then delete it from the `requests` subcollection
        await admin.firestore().doc(`Tools/${toolID}/previous_requests/${requestID}`).set(
          (await requestDoc.get()).data()!
        )
        await requestDoc.delete();

        // Update the deliver meeting doc to inActive
        const deliverMeetingDoc = admin.firestore().doc(`Tools/${toolID}/deliver_meetings/${requestID}`);
        await deliverMeetingDoc.update({
          'isActive': false,
        });

        // set isActive to false
        return change.after.ref.update({
          'isActive': false,
        });
      }
    }

    return null;
  });

export const disagreementCaseUpdated = functions.firestore.document('/disagreementCases/{caseID}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();

    if(newData == null) return null;

    if(newData.Result_IsToolDamaged != null){
      // a result has been set
      const isToolDamaged = newData.Result_IsToolDamaged;
      const toolID = newData.toolID;
      const requestID = newData.requestID;
      return admin.firestore().doc(`Tools/${toolID}/return_meetings/${requestID}`).update({
        'disagreementCaseSettled': true,
        'disagreementCaseResult': isToolDamaged,
      });
    }

    return null;
  });