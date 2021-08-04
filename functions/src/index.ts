import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// // Start writing Firebase Functions
// // https://firebase.google.com/docs/functions/typescript

admin.initializeApp();

export * from './fcm';

/**
 * handle tools' `acceptedRequestID` field changes
 * - if a new requst was added this function changes the request's `isAccepted` to true
 * - if `acceptedRequestID` changed to null this function changes the old request's `isAccepted` to false (if it still exist)
*/
export const toolUpdated = functions.firestore.document('Tools/{toolID}')
  .onUpdate(async (change, context) => {
    /** did `acceptedRequestID` field changed */
    const oldData = change.before.data();
    const newData = change.after.data();

    const changedAcceptedID = oldData.acceptedRequestID != newData.acceptedRequestID;
    if (changedAcceptedID) {
      const toolID = change.after.id;
      const oldRequestID = oldData.acceptedRequestID;
      const newRequestID = newData.acceptedRequestID;
      if (newRequestID != null) {
        const requestDoc = admin.firestore().doc(`Tools/${toolID}/requests/${newRequestID}`);
        const renterUID = (await requestDoc.get()).data()!.renterUID;
        // create a deliver_meeting doc
        await admin.firestore().doc(`Tools/${toolID}/deliver_meetings/${newRequestID}`).set({
          'isActive': true,
          'ownerUID': newData.ownerUID,
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
        const oldRequestDoc = await admin.firestore().doc(`Tools/${toolID}/requests/${oldRequestID}`);
        if ((await oldRequestDoc.get()).exists) {
          return oldRequestDoc.update({ 'isAccepted': false });
        } else {
          return null;
        }
      }
    } else {
      return null;
    }
  });

export const requestWrite = functions.firestore.document('Tools/{toolID}/requests/{requestID}')
  .onWrite(async (change, context) => {
    const toolDoc = admin.firestore().doc(`Tools/${context.params.toolID}`);
    if (!change.after.exists) {
      // DELETE
      const docData = change.before.data()!;
      // if the request was accepted, remove its ID from `acceptedRequestID`
      if (docData && docData.isAccepted == true) {
        await toolDoc.update({ 'acceptedRequestID': null });
      }

      // delete the request snippet in the user subcollection
      const renterUID = docData.renterUID;
      const renterRequestDoc = admin.firestore().doc(`Users/${renterUID}/requests/${docData.toolID}`);
      await renterRequestDoc.delete();

      // send notification to renter
      const toolDocData = await toolDoc.get();
      const toolName = toolDocData.data()?.name;
      return addNotification(docData.renterUID, 'REQ_DEL', {
        'notificationBodyArgs': [toolName],
        'toolID': context.params.toolID,
        'requestID': context.params.requestID,
        'toolName': toolName,
      });
    } else {
      // UPDATE OR CREATE
      const docData = change.after.data()!;

      if (!change.before.exists) {
        // if it was a new request
        // send notification to owner
        const toolDocData = await toolDoc.get();
        const toolName = toolDocData.data()?.name;
        const renterDoc = await admin.firestore().doc(`Users/${docData.renterUID}`).get();
        const renterName = renterDoc.data()?.name;
        await addNotification(toolDocData.data()!.ownerUID, 'REQ_REC', {
          'notificationBodyArgs': [toolName, renterName],
          'toolID': context.params.toolID,
          'requestID': context.params.requestID,
          'toolName': toolName,
          'renterName': renterName,
        });
      }

      // update/create the request snippet in the user's subcollection
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
    const ownerLeft = before.owner_arrived && !after.owner_arrived;
    const renterLeft = before.renter_arrived && !after.renter_arrived;
    if (ownerLeft || renterLeft) {
      return change.after.ref.update({
        'owner_pics_ok': false,
        'owner_ids_ok': false,
        'renter_pics_ok': false,
        'renter_ids_ok': false,
      });
    }

    // if either the owner or renter changed [pics] from `true` to `false`
    const ownerPicsBecameFalse = before.owner_pics_ok && !after.owner_pics_ok;
    const renterPicsBecameFalse = before.renter_pics_ok && !after.renter_pics_ok;
    if (ownerPicsBecameFalse || renterPicsBecameFalse) {
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

    const ownerAgreedOnPics = !before.owner_pics_ok && after.owner_pics_ok;
    const renterAgreedOnPics = !before.renter_pics_ok && after.renter_pics_ok;
    // if either the owner or renter changed [pics] from `false` to `true`
    if (ownerAgreedOnPics || renterAgreedOnPics) {
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

    const ownerAgreedOnIds = !before.owner_ids_ok && after.owner_ids_ok;
    const renterAgreedOnIds = !before.renter_ids_ok && after.renter_ids_ok;
    if (ownerAgreedOnIds || renterAgreedOnIds) {
      // when they both agree on IDs
      if (after.owner_ids_ok && after.renter_ids_ok) {
        // remove the IDs strings from meetings doc
        await change.after.ref.update({
          'owner_id': null,
          'renter_id': null,
        });
        try {
          const rentsCollection = admin.firestore().collection('rents/');
          // Create rent doc
          const rentDoc = await rentsCollection.add({
            toolID: change.after.ref.parent.parent!.id,
            requestID: change.after.id,
            startTime: admin.firestore.Timestamp.now(),
            endTime: null,
          });
          // Update the tool doc
          const toolDoc = admin.firestore().doc(`Tools/${context.params.toolID}`);
          await toolDoc.update({
            'currentRent': rentDoc.id,
          });
          // Update the request `isRented` field
          const requestDoc = admin.firestore().doc(`Tools/${context.params.toolID}/requests/${context.params.requestID}`);
          await requestDoc.update({
            'isRented': true,
          });

          // Create return meeting doc
          const returnMeetingDoc = admin.firestore().doc(`Tools/${context.params.toolID}/return_meetings/${context.params.requestID}`);
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


          // Send notifications
          const toolName = (await toolDoc.get()).data()?.name;
          const renterName = (await admin.firestore().doc(`Users/${renterUID}`).get()).data()?.name;
          const ownerName = (await admin.firestore().doc(`Users/${ownerUID}`).get()).data()?.name;

          const notifCode = 'REN_START';
          const renterBodyData = {
            'notificationBodyArgs': [toolName, ownerName],
            'toolName': toolName,
            'renterName': renterName,
            'ownerName': ownerName,
            'toolID': context.params.toolID,
            'renterUID': renterUID,
          };
          const ownerBodyData = {
            'notificationBodyArgs': [toolName, renterName],
            'toolName': toolName,
            'renterName': renterName,
            'ownerName': ownerName,
            'toolID': context.params.toolID,
            'renterUID': renterUID,
          };
          addNotification(ownerUID, notifCode, ownerBodyData);
          addNotification(renterUID, notifCode, renterBodyData);

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
      let updates;
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
      let updates;
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

    const ownerFinishedMedia = !oldData.ownerMediaOK && newData.ownerMediaOK;
    const renterLikedMedia = !oldData.renterMediaOK && oldData.renterMediaOK;
    // when any [mediaOk] change from `false` to `true`
    if (ownerFinishedMedia || renterLikedMedia) {
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

    const ownerConfirmedHO = !oldData.ownerConfirmHandover && newData.ownerConfirmHandover;
    const renterConfirmedHO = !oldData.renterConfirmHandover && newData.renterConfirmHandover;
    // when any [ConfirmHandover] change from `false` to `true`
    if (ownerConfirmedHO || renterConfirmedHO) {
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
          console.log(`An error occured after handover\n${error.toString()}`);
          return null;
        }

        // end rent
        const toolDoc = admin.firestore().doc(`Tools/${toolID}`);
        const toolData = (await toolDoc.get()).data()!;

        const rentDoc = admin.firestore().doc(`rents/${toolData.currentRent}`);
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
        );
        await requestDoc.delete();

        // Update the deliver meeting doc to inActive
        const deliverMeetingDoc = admin.firestore().doc(`Tools/${toolID}/deliver_meetings/${requestID}`);
        await deliverMeetingDoc.update({
          'isActive': false,
        });

        // Send notifications
        const toolName = toolData.name;
        const renterName = (await admin.firestore().doc(`Users/${newData.renterUID}`).get()).data()?.name;
        const ownerName = (await admin.firestore().doc(`Users/${newData.ownerUID}`).get()).data()?.name;

        const notifCode = 'REN_END';
        const renterBodyData = {
          'notificationBodyArgs': [toolName, ownerName],
          'toolName': toolName,
          'ownerName': ownerName,
          'renterName': renterName,
          'toolID': toolID,
          'renterUID': newData.renterUID,
        };
        const ownerBodyData = {
          'notificationBodyArgs': [toolName, renterName],
          'toolName': toolName,
          'ownerName': ownerName,
          'renterName': renterName,
          'toolID': toolID,
          'renterUID': newData.renterUID,
        };

        addNotification(newData.ownerUID, notifCode, ownerBodyData);
        addNotification(newData.renterUID, notifCode, renterBodyData);

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

    if (newData == null) return null;

    if (newData.Result_IsToolDamaged != null) {
      // a result has been set
      const isToolDamaged = newData.Result_IsToolDamaged;
      const toolID = newData.toolID;

      const toolDoc = await admin.firestore().doc(`Tools/${toolID}`).get();
      const toolName = toolDoc.data()?.name;

      const notifCode = isToolDamaged ? 'DC_DAM' : 'DC_NDAM';
      const notifData = {
        'notificationBodyArgs': [toolName],
        'toolID': toolID,
        'toolName': toolName,
      };
      addNotification(newData.renterUID, notifCode, notifData);
      addNotification(newData.ownerUID, notifCode, notifData);

      const requestID = newData.requestID;
      return admin.firestore().doc(`Tools/${toolID}/return_meetings/${requestID}`).update({
        'disagreementCaseSettled': true,
        'disagreementCaseResult': isToolDamaged,
      });
    }

    return null;
  });

/**
 * create a new doc in the user's notification collections which also invokes `newNotification()` and sends the user an FCM message
 * @param userUID the user's uid
 * @param code
 * Notifications codes:
 * - `REQ_REC`: request recived
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
function addNotification(userUID: string, code: string, data: any)
  : Promise<FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>> {
  const notifsCollection = admin.firestore().collection(`Users/${userUID}/notifications`);
  return notifsCollection.add({
    'code': code,
    'data': data,
    'time': admin.firestore.FieldValue.serverTimestamp(),
    'isRead': false,
  });
}
