import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

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

    const renterPicsChanged = !arraysEqual(before.renter_pics_urls , after.renter_pics_urls);
    const ownerPicsChanged = !arraysEqual(before.owner_pics_urls , after.owner_pics_urls);
    if (renterPicsChanged || ownerPicsChanged) {
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
        await change.after.ref.update({
          'owner_id': null,
          'renter_id': null,
        });

        return startRent(
          context.params.toolID,
          context.params.requestID,
          ownerUID,
          renterUID,
          change.after.ref,
        );
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
    const renterLikedMedia = !oldData.renterMediaOK && newData.renterMediaOK;
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

    const compensationPriceChanged = oldData.compensationPrice != newData.compensationPrice;
    if (compensationPriceChanged) {
      await change.after.ref.update({
        'renterAcceptCompensationPrice': null,
      });
    }

    const ownerConfirmedHO = !oldData.ownerConfirmHandover && newData.ownerConfirmHandover;
    const renterConfirmedHO = !oldData.renterConfirmHandover && newData.renterConfirmHandover;
    // when any [ConfirmHandover] change from `false` to `true`
    if (ownerConfirmedHO || renterConfirmedHO) {
      // when BOTH [ConfirmHandover] are true
      if (newData.ownerConfirmHandover && newData.renterConfirmHandover) {
        return endRent(
          toolID,
          requestID,
          newData.ownerUID,
          newData.renterUID,
          newData.compensationPrice,
          change.after.ref,
        );
      }
    }

    return null;
  });

async function startRent(
  toolID: string,
  requestID: string,
  ownerUID: string,
  renterUID: string,
  deliverMeetingDoc: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>,
) {
  /** a `true` bool that turns `false` if an error was catched in a try-catch */
  let success = true;
  /** did [error] occur in payment logic */
  let errorInPayment;
  /** error object caught in a try-catch */
  let error;
  const toolDoc = admin.firestore().doc(`Tools/${toolID}`);
  const requestDoc = admin.firestore().doc(`Tools/${toolID}/requests/${requestID}`);
  const requestData = (await requestDoc.get()).data()!;

  // Process payment
  try {
    // TODO: for better debugging, wrap each step with a try-catch to know what exactly failed
    // Calculate total
    // Take the total from renter
    // Give the owner the rent money
  } catch (e) {
    success = false;
    errorInPayment = true;
    error = e;
    await deliverMeetingDoc.update({
      'error': 'Operation failed: An error occured while processing the payment.'
    });
  }

  if (success)
    try {
      // Create a rent document
      const rentsCollection = admin.firestore().collection('rents/');
      const rentDoc = await rentsCollection.add({
        toolID: toolID,
        requestID: requestID,
        startTime: admin.firestore.Timestamp.now(),
        endTime: null,
      });

      // Create a batch to perform a batched write
      // Batched writes: (https://firebase.google.com/docs/firestore/manage-data/transactions#batched-writes)
      const batch = admin.firestore().batch();

      // Update the tool's doc.currentRent
      batch.update(toolDoc, { 'currentRent': rentDoc.id });

      // Update the request `isRented` field
      batch.update(requestDoc, { 'isRented': true });

      // Create return meeting doc
      const returnMeetingDoc = admin.firestore().doc(`Tools/${toolID}/return_meetings/${requestID}`);
      batch.set(returnMeetingDoc, {
        'isActive': true,
        'error': false,
        'insuranceAmount': requestData.insuranceAmount,
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
      batch.update(deliverMeetingDoc, { 'rent_started': true });

      // commit the updates
      await batch.commit();
    } catch (e) {
      success = false;
      errorInPayment = false;
      error = e;
      // if an error occured update the meeting's error field.
      await deliverMeetingDoc.update({
        'error': 'Operation failed: An error occured while starting the rent.'
      });
    }

  if (success) {
    // Send notifications
    const toolName = (await toolDoc.get()).data()?.name;
    const renterName = (await admin.firestore().doc(`Users/${renterUID}`).get()).data()?.name;
    const ownerName = (await admin.firestore().doc(`Users/${ownerUID}`).get()).data()?.name;

    const notifCode = 'REN_START';
    const renterBodyData = {
      'notificationBodyArgs': [toolName, ownerName],
      'toolName': toolName,
      'otherUserName': ownerName,
      'toolID': toolID,
    };
    const ownerBodyData = {
      'notificationBodyArgs': [toolName, renterName],
      'toolName': toolName,
      'otherUserName': renterName,
      'toolID': toolID,
    };
    await addNotification(ownerUID, notifCode, ownerBodyData);
    return addNotification(renterUID, notifCode, renterBodyData);
  } else {
    if (error != null) {
      return functions.logger.error(
        `an error occured while starting the rent for tool ${toolID}, request ${requestID}, owner:${ownerUID}, renter${renterUID}`,
        `did the error occur in payment?: ${errorInPayment}`,
        'error toString = ',
        error.toString(),
        'error variable:',
        error,
      );
    } else {
      return functions.logger.error(
        `an error occured while starting the rent for tool ${toolID}, request ${requestID}, owner:${ownerUID}, renter${renterUID}`,
        "However, the error wasn't caught in the try-catch 😕"
      );
    }
  }
}

async function endRent(
  toolID: string,
  requestID: string,
  ownerUID: string,
  renterUID: string,
  compensationPrice: number = 0,
  returnMeetingDoc: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>,
) {

  /** a `true` bool that turns `false` if an error was catched in a try-catch */
  let success = true;
  /** did [error] occur in payment logic */
  let errorInPayment;
  /** error object caught in a try-catch */
  let error;


  // calculate total - and process payment
  const requestDoc = admin.firestore().doc(`Tools/${toolID}/requests/${requestID}`);
  const requstData = (await requestDoc.get()).data()!;

  try {
    // TODO move insuranceAmount to rent doc
    const insuranceAmount = requstData.insuranceAmount;

    const total_to_renter = insuranceAmount - compensationPrice;
    const total_to_owner = compensationPrice;

    if (total_to_renter != 0) {
      // send the money
    }
    if (total_to_owner != 0) {
      // send the money
    }
  } catch (e) {
    success = false;
    errorInPayment = true;
    error = e;
    await returnMeetingDoc.update({
      'error': 'Operation failed: An error occured while processing the payment.'
    });
  }

  const toolDoc = admin.firestore().doc(`Tools/${toolID}`);
  const toolData = (await toolDoc.get()).data()!;

  if (success) {
    try {
      const batch = admin.firestore().batch();

      const rentDoc = admin.firestore().doc(`rents/${toolData.currentRent}`);
      batch.update(rentDoc, {
        endTime: admin.firestore.Timestamp.now(),
      });

      // Update the tool doc
      batch.update(toolDoc, {
        'currentRent': null,
        'acceptedRequestID': null,
      });


      // move the request to `previous_requests` subcollection then delete it from the `requests` subcollection
      batch.set(
        admin.firestore().doc(`Tools/${toolID}/previous_requests/${requestID}`),
        requstData,
      );
      batch.delete(requestDoc);

      // Update the deliver meeting doc to inActive
      const deliverMeetingDoc = admin.firestore().doc(`Tools/${toolID}/deliver_meetings/${requestID}`);
      batch.update(deliverMeetingDoc, {
        'isActive': false,
      });

      // set returnMeetingDoc.isActive to false
      batch.update(returnMeetingDoc, {
        'isActive': false,
      });

      const rentersPreviousUserDoc = admin.firestore().doc(`Users/${renterUID}/previous_users/${ownerUID}`);
      const owbersPreviousUserDoc = admin.firestore().doc(`Users/${ownerUID}/previous_users/${renterUID}`);
      batch.set(rentersPreviousUserDoc, { [toolID]: true }, { merge: true });
      batch.set(owbersPreviousUserDoc, { [toolID]: true }, { merge: true });

      await batch.commit();
    } catch (e) {
      success = false;
      errorInPayment = false;
      error = e;
      await returnMeetingDoc.update({
        // TODO localize errors
        'error': 'Operation failed: An error occured while ending the rent on our end. Payment has been deducted though. So, deliver the tool and we will fix this ASAP'
      });
      // TODO Send important notice to admins
    }
  }

  if (success) {
    // Send notifications
    const toolName = toolData.name;
    const renterName = (await admin.firestore().doc(`Users/${renterUID}`).get()).data()?.name;
    const ownerName = (await admin.firestore().doc(`Users/${ownerUID}`).get()).data()?.name;

    const notifCode = 'REN_END';
    const renterBodyData = {
      'notificationBodyArgs': [toolName, ownerName],
      'toolName': toolName,
      'otherUserName': ownerName,
      'toolID': toolID,
    };
    const ownerBodyData = {
      'notificationBodyArgs': [toolName, renterName],
      'toolName': toolName,
      'otherUserName': renterName,
      'toolID': toolID,
    };

    await addNotification(ownerUID, notifCode, ownerBodyData);
    return addNotification(renterUID, notifCode, renterBodyData);
  } else {
    if (error != null) {
      return functions.logger.error(
        `an error occured while ending the rent for tool ${toolID}, request ${requestID}, owner:${ownerUID}, renter${renterUID}`,
        `did the error occur in payment?: ${errorInPayment}`,
        'error toString = ',
        error.toString(),
        'error variable:',
        error,
      );
    } else {
      return functions.logger.error(
        `an error occured while ending the rent for tool ${toolID}, request ${requestID}, owner:${ownerUID}, renter${renterUID}`,
        "However, the error wasn't caught in the try-catch 😕"
      );
    }
  }

}

function arraysEqual(a: any, b: any) {
  if(!Array.isArray(a) || !Array.isArray(b)) return false;
  if (a === b) return true;
  if (a == null || b == null) return false;
  if (a.length !== b.length) return false;

  // If you don't care about the order of the elements inside
  // the array, you should sort both arrays here.
  // Please note that calling sort on an array will modify that array.
  // you might want to clone your array first.

  for (var i = 0; i < a.length; ++i) {
    if (a[i] !== b[i]) return false;
  }
  return true;
}

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
