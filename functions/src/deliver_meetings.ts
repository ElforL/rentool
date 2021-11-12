import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { chargeCustomer, createCkoProblem, payOutCustomer, refundPayment } from './checkout_functions';
import { addNotification } from './fcm';

export const deliverMeetingUpdated = functions.firestore.document('Tools/{toolID}/deliver_meetings/{requestID}').onUpdate(deliverMeetingHandler);
export const dMeetPaymendDocUpdated = functions.firestore.document('Tools/{toolID}/deliver_meetings/{requestID}/private/payments_processing').onUpdate(dMeetPaymendDocUpdatedHandler);


async function deliverMeetingHandler(change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) {
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

  const renterPicsChanged = !arraysEqual(before.renter_pics_urls, after.renter_pics_urls);
  const ownerPicsChanged = !arraysEqual(before.owner_pics_urls, after.owner_pics_urls);
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

      await createPaymentDoc(change.after.ref.collection('private').doc('payments_processing'));
      await pay(
        context.params.toolID,
        context.params.requestID,
        renterUID,
        change.after.ref,
      );
      change.after.ref.update({ 'processing_payment': true });
    } else {
      return null;
    }
  }

  if (before.payments_successful == null && after.payments_successful == true) {
    return startRent(
      context.params.toolID,
      context.params.requestID,
      ownerUID,
      renterUID, change.after.ref
    );
  }

  return null;
}

async function createPaymentDoc(paymentDoc: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>) {
  const doc = await paymentDoc.get();
  if (doc.exists && doc.data() != null) {
    return paymentDoc.set({
      'renter_paid': false,
      'owner_paid': false,
      'renter_sent_charge': false,
      'owner_sent_payment': false,
    }, { merge: true });
  }
  return paymentDoc.set({
    'renter_paid': false,
    'owner_paid': false,
    'renter_sent_charge': false,
    'owner_sent_payment': false,
    'renter_payment_ids': {},
    'owner_payment_ids': {},
  }, { merge: true });
}

async function pay(
  toolID: string,
  requestID: string,
  renterUID: string,
  deliverMeetingDoc: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>,
) {
  let paymentDocData = (await deliverMeetingDoc.collection('private').doc('payments_processing').get()).data()!

  const requestDoc = await admin.firestore().doc(`Tools/${toolID}/requests/${requestID}`).get();
  const numOfDays = requestDoc.data()!.numOfDays;
  const rentPrice = requestDoc.data()!.rentPrice;
  const insuranceAmount = requestDoc.data()!.insuranceAmount;

  const total = (numOfDays * rentPrice + insuranceAmount);

  if (paymentDocData.renter_sent_charge != true) {
    try {
      await deliverMeetingDoc.collection('private').doc('payments_processing').update({ 'renter_sent_charge': true });
      await chargeRenter(renterUID, total, toolID, requestID, deliverMeetingDoc);
    } catch (error) {
      functions.logger.debug('Failed to charge the renter', error);
      await cancelRequest(toolID);
      await deliverMeetingDoc.update({
        'payments_successful': false,
        'errors': admin.firestore.FieldValue.arrayUnion({
          'time': admin.firestore.Timestamp.now(),
          'side_uid': renterUID,
        }),
      });
      return;
    }
  }
}

async function refundRenter(
  deliverMeetingDoc: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>,
  renterUID: string,
  toolID: string,
  requestID: string,
) {
  const paymentDoc = await deliverMeetingDoc.collection('private').doc('payments_processing').get();

  const renter_payment_ids = paymentDoc.data()?.renter_payment_ids;

  if (typeof renter_payment_ids == 'object') {
    for (const id in renter_payment_ids) {
      if (Object.prototype.hasOwnProperty.call(renter_payment_ids, id)) {
        const payment_id = renter_payment_ids[id];

        if (payment_id.refunded != true) {
          const payment_type = 'refund_rent_n_insurance_to_renter';
          try {
            await refundPayment(
              payment_id.id,
              payment_type,
              `${toolID}-${requestID}-${payment_type}`,
              {
                'toolID': toolID,
                'requestID': requestID,
              }
            );

            await paymentDoc.ref.update({
              [`renter_payment_ids.${payment_id.id}.refunded`]: true,
            })

            await admin.firestore().doc(`cko_users_payments/${renterUID}/payments/${payment_id.id}`).set({
              [payment_id.status]: payment_id,
            }, { merge: true });
          } catch (_) { }
        }
      }
    }
  }
}

async function chargeRenter(
  renterUID: string,
  /** the amount in Riyals not Halalas */
  amount: number,
  toolID: string,
  requestID: string,
  deliverMeetingDoc: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>,
) {
  const paymentDoc = deliverMeetingDoc.collection('private').doc('payments_processing')
  const payment_type = 'rent_n_insurance_from_renter';
  const payment: any = await chargeCustomer(
    renterUID,
    Math.round(amount * 100),
    payment_type,
    'Rentool- rent and insurance price',
    `${toolID}-${requestID}-${payment_type}`,
    {
      'toolID': toolID,
      'requestID': requestID,
    },
    true,
  );

  await admin.firestore().doc(`cko_users_payments/${renterUID}/payments/${payment.id}`).set({
    [payment.status]: payment
  }, { merge: true });

  if (payment.approved == false) throw 'Not-Approved';

  const batch = admin.firestore().batch();

  batch.update(admin.firestore().doc(`payment_references/${payment.reference}`), {
    'payment_id': payment.id,
  });

  batch.update(paymentDoc, {
    [`renter_payment_ids.${payment.id}`]: {
      'id': payment.id,
      'time': admin.firestore.FieldValue.serverTimestamp()
    }
  });

  if (payment.status == 'Pending') {
    const redirectLink = payment._links.redirect.href;
    batch.set(deliverMeetingDoc.collection('private').doc(renterUID), {
      'type': 'redirect',
      'link': redirectLink,
    });
    batch.update(deliverMeetingDoc, {
      'renter_action_required': true,
    });
  }

  await batch.commit();
}

async function payOutOwner(
  /** the amount in Riyals not Halalas */
  amount: number,
  ownerUID: string,
  toolID: string,
  requestID: string,
  deliverMeetingDoc: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>,
) {
  const paymentDoc = deliverMeetingDoc.collection('private').doc('payments_processing')

  const payment_type = 'rent_price_to_owner';
  const payment: any = await payOutCustomer(
    ownerUID,
    Math.round(amount * 100),
    payment_type,
    'Rentool- Rent price',
    `${toolID}-${requestID}-${payment_type}`,
    {
      'toolID': toolID,
      'requestID': requestID,
    },
  );

  await admin.firestore().doc(`cko_users_payments/${ownerUID}/payments/${payment.id}`).set({
    [payment.status]: payment
  }, { merge: true });

  if (payment.approved == false) throw 'Not-Approved';

  paymentDoc.update({
    [`owner_payment_ids.${payment.id}`]: {
      'id': payment.id,
      'time': admin.firestore.Timestamp.now()
    }
  });

  return payment;
}

async function cancelRequest(toolID: string) {
  admin.firestore().doc(`Tools/${toolID}`).update({ 'acceptedRequestID': null })
}

async function startRent(
  toolID: string,
  requestID: string,
  ownerUID: string,
  renterUID: string,
  deliverMeetingDoc: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>,
) {
  /** a `true` bool that turns `false` if an error was catched in a try-catch */
  let success = true;
  /** error object caught in a try-catch */
  let error;
  const toolDoc = admin.firestore().doc(`Tools/${toolID}`);
  const requestDoc = admin.firestore().doc(`Tools/${toolID}/requests/${requestID}`);
  const requestData = (await requestDoc.get()).data()!;

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

function arraysEqual(a: any, b: any) {
  if (!Array.isArray(a) || !Array.isArray(b)) return false;
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


async function dMeetPaymendDocUpdatedHandler(change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) {

  const renterPaid = change.before.data().renter_paid == false && change.after.data().renter_paid == true;
  const owner_paid = change.before.data().owner_paid == false && change.after.data().owner_paid == true;
  const toolID = context.params.toolID;
  const requestID = context.params.requestID;

  let deliverMeetingDoc = await change.after.ref.parent.parent?.get();

  if (renterPaid || owner_paid) {
    const paymentDocData = await deliverMeetingDoc!.ref.collection('private').doc('payments_processing').get();
    if (renterPaid) {
      if (paymentDocData.data()?.owner_sent_payment != true) {
        const requestDoc = await admin.firestore().doc(`Tools/${toolID}/requests/${requestID}`).get();
        const numOfDays = requestDoc.data()!.numOfDays;
        const rentPrice = requestDoc.data()!.rentPrice;

        const total = numOfDays * rentPrice;

        try {
          await paymentDocData.ref.update({ 'owner_sent_payment': true });
          await payOutOwner(total, deliverMeetingDoc!.data()!.ownerUID, toolID, requestID, deliverMeetingDoc!.ref);
        } catch (error) {
          functions.logger.debug('Failed to payout the owner', error);
          await refundRenter(deliverMeetingDoc!.ref, deliverMeetingDoc!.data()!.renterUID, toolID, requestID);
          await cancelRequest(toolID);
          await deliverMeetingDoc!.ref.update({
            'payments_successful': false,
            'errors': admin.firestore.FieldValue.arrayUnion({
              'time': admin.firestore.Timestamp.now(),
              'side_uid': deliverMeetingDoc!.data()!.ownerUID,
            }),
          });
        }
      }
    }

    if (change.after.data().renter_paid == change.after.data().owner_paid) {
      deliverMeetingDoc = await deliverMeetingDoc!.ref.get();

      await deliverMeetingDoc?.ref.update({
        'payments_successful': true,
      });
      if (deliverMeetingDoc?.data()?.payments_successful == false) {
        functions.logger.error('Both parties set to "paid" in an unsuccessful payment.',
          `toolId: ${toolID}`,
          `requestID: ${requestID}`
        );
        try {
          await createCkoProblem(
            'both_paid_but_payments_successful_is_false',
            'Both parties set to "paid" in an unsuccessful payment. Make sure all charges are ok',
            {
              'deliveryDoc': deliverMeetingDoc.data() as Object,
              'paymentDoc': paymentDocData.data() as Object,
            },
          );
        } catch (error) {
          functions.logger.error('Couldn\'t create cko problem.');
        }
      }
    }
  }
}
