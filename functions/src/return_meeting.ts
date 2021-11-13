import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { createCkoProblem, payOutCustomer, refundPayment, setPayIdToReference } from './checkout_functions';
import { addNotification } from './fcm';

export const returnMeetingUpdated = functions.firestore.document('Tools/{toolID}/return_meetings/{requestID}')
  .onUpdate(returnMeetingHandler);

async function returnMeetingHandler(change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) {
  const toolID = context.params.toolID;
  const requestID = context.params.requestID;
  const newData = change.after.data();
  const oldData = change.before.data();

  if(newData.disagreementCaseResult == true){
    return endRent(
      toolID,
      requestID,
      newData.ownerUID,
      newData.renterUID,
      change.after.ref,
    );
  }

  // if renterArrived CHANGED to `false` set everything that comes after it to false
  if (!oldData.renterArrived && newData.renterArrived) {
    // same for other fields
    let updates;
    if (newData.disagreementCaseSettled != null) {
      // if there is a disagreement case don't change `renterAdmitDamage` and `renterMediaOK`
      // because 1- changing them won't change anythin 2- they must be `false` and `true` respectively for a disagreement case to have been created
      updates = {
        'renterConfirmHandover': false,
      };
    } else {
      updates = {
        'renterAdmitDamage': null,
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
        'ownerConfirmHandover': false,
      };
    } else {
      updates = {
        'toolDamaged': null,
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

  if (newData.renterAdmitDamage) {
    return endRent(
      toolID,
      requestID,
      newData.ownerUID,
      newData.renterUID,
      change.after.ref,
    );
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
  returnMeetingDoc: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>,
) {
  // calculate total - and process payment
  const requestDoc = admin.firestore().doc(`Tools/${toolID}/requests/${requestID}`);
  const requstData = (await requestDoc.get()).data()!;

  const insuranceAmount = requstData.insuranceAmount;

  const total_to_renter = 0;
  const total_to_owner = insuranceAmount;

  if (total_to_renter > 0) {
    const payment_type = 'refund_all_insurance_to_renter';

    const deliveryPaymentProcessingDoc = await admin.firestore()
      .doc(`Tools/${toolID}/deliver_meetings/${requestID}/private/payments_processing`).get();

    const renter_payment_ids = deliveryPaymentProcessingDoc.data()?.renter_payment_ids;
    
    if (typeof renter_payment_ids == 'object') {
      for (const id in renter_payment_ids) {
        if (Object.prototype.hasOwnProperty.call(renter_payment_ids, id)) {
          const payment_id = renter_payment_ids[id];
          try {
            if (payment_id.paid == true && payment_id.refunded != true) {
              const payment: any = await refundPayment(
                payment_id.id,
                payment_type,
                `${toolID}-${requestID}-${payment_type}`,
                {
                  'toolID': toolID,
                  'requestID': requestID,
                  'renterUID': ownerUID,
                },
                total_to_renter > 0 ? Math.round(total_to_renter * 100) : undefined,
              );

              await setPayIdToReference(payment.reference, payment.id);
              break;
            }
          } catch (error) {
            functions.logger.error(
              'ERROR refunding insurance to renter',
              `toolID:${toolID}, requestID:${requestID}, ownerUid:${ownerUID} amount:${total_to_renter} amount_Halala:${Math.round(total_to_renter * 100)} payment_id:${payment_id.id}`,
              error
            );
            await createCkoProblem('insurance_refund_return_error', error, {
              'toolID': toolID,
              'requestID': requestID,
              'renterUID': renterUID,
              'payment_id': payment_id.id,
              'amount': total_to_renter,
              'amount_Halala': Math.round(total_to_renter * 100),
            });
            await returnMeetingDoc.update({
              'errors_for_renter': admin.firestore.FieldValue.arrayUnion('renter_refund_failed'),
            });
          }
        }
      }
    }
  }

  if (total_to_owner > 0) {
    try {
      const payment_type = 'compensation_to_owner';
      const payment: any = await payOutCustomer(
        ownerUID,
        Math.round(total_to_owner * 100),
        payment_type,
        'Rentool- compensation price',
        `${toolID}-${requestID}-${payment_type}`,
        {
          'toolID': toolID,
          'requestID': requestID,
          'ownerUID': ownerUID,
        },
      );
      await setPayIdToReference(payment.reference, payment.id);
    } catch (error) {
      functions.logger.error(
        'ERROR paying compensation to owner.',
        `toolID:${toolID}, requestID:${requestID}, ownerUid:${ownerUID} amount:${total_to_owner} amount_Halala:${Math.round(total_to_owner * 100)}`,
        error
      );
      await createCkoProblem('compensation_payout_return_error', error, {
        'toolID': toolID,
        'requestID': requestID,
        'ownerUID': ownerUID,
        'amount': total_to_owner,
        'amount_Halala': Math.round(total_to_owner * 100),
      });
      await returnMeetingDoc.update({
        'errors_for_owner': admin.firestore.FieldValue.arrayUnion('owner_payout_failed'),
      });
    }
  }

  const toolDoc = admin.firestore().doc(`Tools/${toolID}`);
  const toolData = (await toolDoc.get()).data()!;

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

  // Send notifications
  const toolName = toolData.name;
  const renterName = (await admin.firestore().doc(`Users/${renterUID}`).get()).data()?.name;
  const ownerName = (await admin.firestore().doc(`Users/${ownerUID}`).get()).data()?.name;

  const notifCode = 'REN_END';
  const renterBodyData = {
    'notificationBodyArgs': [toolName, ownerName],
    'toolName': toolName,
    'otherUserName': ownerName,
    'otherUserId': ownerUID,
    'toolID': toolID,
  };
  const ownerBodyData = {
    'notificationBodyArgs': [toolName, renterName],
    'toolName': toolName,
    'otherUserName': renterName,
    'otherUserId': renterUID,
    'toolID': toolID,
  };

  await addNotification(ownerUID, notifCode, ownerBodyData);
  return addNotification(renterUID, notifCode, renterBodyData);
}
