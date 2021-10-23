import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { addNotification } from './fcm';

export const returnMeetingUpdated = functions.firestore.document('Tools/{toolID}/return_meetings/{requestID}')
  .onUpdate(returnMeetingHandler);

async function returnMeetingHandler(change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) {
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
        'timeCreated': admin.firestore.FieldValue.serverTimestamp(),
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
