import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { refundPayment } from './checkout_functions';

const db = admin.firestore();
try {
  db.settings({ ignoreUndefinedProperties: true });
} catch (_) { }

/**
 * Handle the requests from the webhook
 * 
 * This function  [must be deployed in us-central1 for hosting redirect](
 * https://firebase.google.com/docs/functions/locations#http_and_client-callable_functions)
 */
export const payments = functions.https.onRequest(async (request, response) => {
  if (typeof functions.config().checkout == 'undefined') {
    response.sendStatus(500);
    return;
  }
  // Authorization
  if (request.get('authorization') !== functions.config().checkout.webhook1_key) {
    response.sendStatus(401);
    return;
  }

  var success;

  // "We highly recommend that you use payment_captured as the webhook trigger since this is the final state of a processed charge."
  // Source: https://docs.checkout.com/reporting-and-insights/webhooks
  switch (request.body.type) {
    case 'card_verified':
      success = await card_verified_handler(request);
      break;
    case 'payment_captured': // When the payment is recived. read above the switch statement.
      success = await payment_captured_handler(request);
      break;
    case 'payment_canceled':
      success = await payment_canceled_handler(request);
      break;
    case 'payment_declined': // one case where it happens: when a payOUT is declined
      success = await payment_declined_handler(request);
      break;
    case 'payment_paid': // one case where it happens: when a payOUT is successful
      success = await payment_paid_handler(request);
      break;
    case 'payment_approved':
      success = await payment_approved_handler(request);
      break;
    case 'payment_capture_declined':
      success = await payment_capture_declined_handler(request);
      break;
    case 'payment_expired':
      success = await payment_expired_handler(request);
      break;
    default:
      functions.logger.warn(`Recived an unexpected event type ${request.body.type}`, request);
      break;
  }

  if (success == false) {
    response.sendStatus(500);
  } else {
    response.sendStatus(200);
  }
});

async function card_verified_handler(request: functions.https.Request): Promise<boolean | void> {
  // Get the payment details to see if 
  const payment = request.body.data;

  const batch = db.batch();

  let user;
  try {
    user = await admin.auth().getUserByEmail(payment.customer.email);
  } catch (error) {
    functions.logger.error(`card_verified_handler couldn't get user info. customer_id: ${payment.customer.id}, email: ${payment.customer.email}`, error);
    return false;
  }

  /** 
   * Payouts require a first and last name that i get from the card name
   * so if the name has no spaces in between, payouts = false
   */
  const payoutsBasedOnName = typeof payment.source.name == 'string' ? (payment.source.name as string).split(' ').length >= 2 : false;

  batch.set(db.doc(`Users/${user.uid}/private/card`), {
    'expiry_month': payment.source.expiry_month,
    'expiry_year': payment.source.expiry_year,
    'name': payment.source.name,
    'scheme': payment.source.scheme,
    'last4': payment.source.last_4,
    'bin': payment.source.bin,
    'payouts': payment.source.payouts ?? payoutsBasedOnName,
  });

  batch.set(admin.firestore().doc(`Users/${user.uid}/private/checklist`), {
    'hasCard': true,
    'cardPayouts': payment.source.payouts ?? payoutsBasedOnName,
  }, { merge: true });

  const userCkoDoc = db.doc(`cko_users_payments/${user.uid}`);

  batch.set(userCkoDoc, {
    'init_payment_id': payment.id,
    'customer': {
      'id': payment.customer.id,
      'email': payment.customer.email,
    },
    'source': payment.source,
  });

  batch.set(userCkoDoc.collection('payments').doc(payment.id), {
    [payment.status]: payment
    // use merge instead of update() to avoid errors where the doc hasn't been created.
  }, { merge: true });
  await batch.commit();
  return true;
}

async function payment_captured_handler(request: functions.https.Request): Promise<boolean | void> {
  // TODOs for the handler:
  // * if it's for a delivery meeting, check if all is ready to start rent (payout successful and renter charged).
  // * 

  // Get reference
  const payment = request.body.data;
  let referenceId: string | undefined = payment.reference;
  if (referenceId != null) {
    const referenceDoc = await getReferenceDoc(referenceId);

    if (referenceDoc.data()?.type == 'rent_n_insurance_from_renter') {
      // charge of the renter in delivery meeting. Includes the rent price + insurance amount

      const toolID = referenceDoc.data()!.metadata.toolID;
      const requestID = referenceDoc.data()!.metadata.requestID;

      const deliverMeetingDoc = admin.firestore().doc(`Tools/${toolID}/deliver_meetings/${requestID}`);
      const paymentProcessingDocRef = deliverMeetingDoc.collection('private').doc('payments_processing');

      await paymentProcessingDocRef.update({
        'renter_paid': true,
      });

      const paymentProcessingDoc = await paymentProcessingDocRef.get();

      const renter_payment_ids = paymentProcessingDoc.data()?.renter_payment_ids;
      if (typeof renter_payment_ids == 'object') {
        for (const id in renter_payment_ids) {
          if (Object.prototype.hasOwnProperty.call(renter_payment_ids, id)) {
            const payment_id = renter_payment_ids[id];

            if (payment_id.id == payment.id) {
              await paymentProcessingDocRef.update({
                [`renter_payment_ids.${payment_id.id}.paid`]: true,
              })
              break;
            }
          }
        }
      }
      return true;
    }
  }

  logNoReferenceEvent('payment_captured', request);
  return true;
}

async function payment_canceled_handler(request: functions.https.Request): Promise<boolean | void> {
  // TODOs for the handler:
  // * if it's for a delivery meeting, cancel the request.
  // * 

  // Get reference
  const payment = request.body.data;
  let referenceId: string | undefined = payment.reference;

  if (referenceId != null) {
    const referenceDoc = await getReferenceDoc(referenceId);

    if (referenceDoc.data()?.type == 'rent_n_insurance_from_renter') {
      await cancelRequestForRenterFailedPayment(referenceDoc, 'payment_canceled');
      return true;
    }
  }
  // referenceId == null

  logNoReferenceEvent('payment_canceled', request);
  return true;
}

async function payment_declined_handler(request: functions.https.Request): Promise<boolean | void> {
  // TODOs for the handler:
  // * if it's a payout in a delivery meeting, cancel the request. and refund renter if charged
  // * 

  // Get reference
  const payment = request.body.data;
  let referenceId: string | undefined = payment.reference;

  if (referenceId != null) {
    const referenceDoc = await getReferenceDoc(referenceId);

    if (referenceDoc.data()?.type == 'rent_price_to_owner') {
      await cancelRequestForOwnerFailedPayment(referenceDoc, 'payment_declined');
      return true;
    }

    if (referenceDoc.data()?.type == 'rent_n_insurance_from_renter') {
      await cancelRequestForRenterFailedPayment(referenceDoc, 'payment_declined');
      return true;
    }
  }
  // referenceId == null

  logNoReferenceEvent('payment_declined', request);
  return true;
}


async function payment_paid_handler(request: functions.https.Request): Promise<boolean | void> {
  // TODOs for the handler:
  // * if it's for a delivery meeting, check if all is ready to start rent (payout successful and renter charged).
  // * 

  // Get reference
  const payment = request.body.data;
  let referenceId: string | undefined = payment.reference;
  if (referenceId != null) {
    const referenceDoc = await getReferenceDoc(referenceId);

    if (referenceDoc.data()?.type == 'rent_price_to_owner') {

      const toolID = referenceDoc.data()!.metadata.toolID;
      const requestID = referenceDoc.data()!.metadata.requestID;

      const deliverMeetingDoc = admin.firestore().doc(`Tools/${toolID}/deliver_meetings/${requestID}`);
      const paymentProcessingDocRef = deliverMeetingDoc.collection('private').doc('payments_processing');

      await paymentProcessingDocRef.update({
        'owner_paid': true,
      });

      const paymentProcessingDoc = await paymentProcessingDocRef.get();

      const owner_payment_ids = paymentProcessingDoc.data()?.owner_payment_ids;
      if (typeof owner_payment_ids == 'object') {
        for (const id in owner_payment_ids) {
          if (Object.prototype.hasOwnProperty.call(owner_payment_ids, id)) {
            const payment_id = owner_payment_ids[id];

            if (payment_id.id == payment.id) {
              await paymentProcessingDocRef.update({
                [`owner_payment_ids.${payment_id.id}.paid`]: true,
              })
              break;
            }
          }
        }
      }
    }
    return true;
  }

  logNoReferenceEvent('payment_paid', request);
  return true;
}


async function payment_approved_handler(request: functions.https.Request): Promise<boolean | void> {
  // functions.logger.warn('Recived a "payment_approved" without a reference', request);
  functions.logger.debug('Function not implemented: payment_approved_handler');
}


async function payment_capture_declined_handler(request: functions.https.Request): Promise<boolean | void> {
  // TODOs for the handler:
  // *  if it's a renter charge in a delivery meeting, cancel the request.
  // * 

  // Get reference
  const payment = request.body.data;
  let referenceId: string | undefined = payment.reference;

  if (referenceId != null) {
    const referenceDoc = await getReferenceDoc(referenceId);

    if (referenceDoc.data()?.type == 'rent_n_insurance_from_renter') {
      await cancelRequestForRenterFailedPayment(referenceDoc, 'payment_declined');
      return true;
    }
  }
  // referenceId == null

  logNoReferenceEvent('payment_capture_declined', request);
  return true;
}


async function payment_expired_handler(request: functions.https.Request): Promise<boolean | void> {
  // TODOs for the handler:
  // *  if it's a renter charge in a delivery meeting, cancel the request.
  // * 

  // Get reference
  const payment = request.body.data;
  let referenceId: string | undefined = payment.reference;

  if (referenceId != null) {
    const referenceDoc = await getReferenceDoc(referenceId);

    if (referenceDoc.data()?.type == 'rent_n_insurance_from_renter') {
      await cancelRequestForRenterFailedPayment(referenceDoc, 'payment_expired');
      return true;
    }
  }
  // referenceId == null

  logNoReferenceEvent('payment_expired', request);
  return true;
}

async function getReferenceDoc(referenceId: string) {
  return await admin.firestore().doc(`payment_references/${referenceId}`).get();
}

async function cancelRequestForRenterFailedPayment(referenceDoc: FirebaseFirestore.DocumentSnapshot<FirebaseFirestore.DocumentData>, code: string) {
  const toolID = referenceDoc.data()!.metadata.toolID;
  const requestID = referenceDoc.data()!.metadata.requestID;

  const deliverMeetingDoc = await admin.firestore().doc(`Tools/${toolID}/deliver_meetings/${requestID}`).get();
  const paymentProcessingDocRef = deliverMeetingDoc.ref.collection('private').doc('payments_processing');
  const paymentProcessingDoc = await paymentProcessingDocRef.get();

  if (paymentProcessingDoc.data()?.owner_paid) {
    functions.logger.error('Logic Error: Owner was paid before capturing renter\'s payment');
  }

  await deliverMeetingDoc.ref.update({
    'payments_successful': false,
    'errors': admin.firestore.FieldValue.arrayUnion({
      'time': admin.firestore.Timestamp.now(),
      'side_uid': deliverMeetingDoc.data()?.renterUID,
      'code': code,
    })
  });

  // Cancel the request
  const toolDoc = deliverMeetingDoc.ref.parent.parent;
  await toolDoc?.update({
    'acceptedRequestID': null,
  });
}

async function cancelRequestForOwnerFailedPayment(referenceDoc: FirebaseFirestore.DocumentSnapshot<FirebaseFirestore.DocumentData>, code: string) {
  const toolID = referenceDoc.data()!.metadata.toolID;
  const requestID = referenceDoc.data()!.metadata.requestID;

  const deliverMeetingDoc = await admin.firestore().doc(`Tools/${toolID}/deliver_meetings/${requestID}`).get();
  const paymentProcessingDocRef = deliverMeetingDoc.ref.collection('private').doc('payments_processing');

  await deliverMeetingDoc.ref.update({
    'payments_successful': false,
    'errors': admin.firestore.FieldValue.arrayUnion({
      'time': admin.firestore.Timestamp.now(),
      'side_uid': deliverMeetingDoc.data()?.ownerUID,
      'code': code,
    })
  });


  // Refund the renter
  const paymentProcessingDoc = await paymentProcessingDocRef.get();
  const renter_payment_ids = paymentProcessingDoc.data()?.renter_payment_ids;

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
            await paymentProcessingDocRef.update({
              [`renter_payment_ids.${payment_id.id}.refunded`]: true,
            })
          } catch (_) { }
        }
      }
    }
  }

  // Cancel the request
  const toolDoc = deliverMeetingDoc.ref.parent.parent;
  await toolDoc?.update({
    'acceptedRequestID': null,
  });
}

function logNoReferenceEvent(event_type: string, request: functions.https.Request) {
  functions.logger.warn(`Recived a ${event_type} without a reference :${request.body.data.reference}`, 'body:', request.body, 'headers:', request.headers, 'full:', request);
}