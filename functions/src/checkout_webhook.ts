import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
// import Checkout from 'checkout-sdk-node';

// const cko = new Checkout(functions.config().checkout.sec_key);
const db = admin.firestore();
try {
  db.settings({ ignoreUndefinedProperties: true });
} catch (_) {}

/**
 * Handle the requests from the webhook
 */
export const payments = functions.https.onRequest(async (request, response) => {
  // Authorization
  if (request.get('authorization') !== functions.config().checkout.webhook1_key) {
    response.sendStatus(401);
    return;
  }

  var success;

  switch (request.body.type) {
    case 'card_verified':
      success = await card_verified_handler(request);
      break;
    // The other cases [[on the webhook]] (editable)
    // *  Card verification declined
    // *  Payment approved ('payment_approved')
    // *  Payment canceled
    // *  Payment declined
    // *  Payment paid
    // *  Payment pending
    // 
    // We highly recommend that you use payment_captured as the webhook trigger since this is the final state of a processed charge.
    // https://docs.checkout.com/reporting-and-insights/webhooks
    default:
      break;
  }

  if (success === false) {
    response.sendStatus(500);
  } else {
    response.sendStatus(200);
  }
});

async function card_verified_handler(request: functions.https.Request): Promise<boolean | void> {
  // Get the payment details to see if 
  const payment = request.body.data;

  const batch = db.batch();

  var user;
  try {
    user = await admin.auth().getUserByEmail(payment.customer.email);
  } catch (error) {
    functions.logger.error(`card_verified_handler couldn't get user info. customer_id: ${payment.customer.id}, email: ${payment.customer.email}`, error);
    return false;
  }

  batch.set(db.doc(`Users/${user.uid}/private/card`), {
    'expiry_month': payment.source.expiry_month,
    'expiry_year': payment.source.expiry_year,
    'name': payment.source.name,
    'scheme': payment.source.scheme,
    'last4': payment.source.last_4,
    'bin': payment.source.bin,
    'payouts': payment.source.payouts ?? true,
  });


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
}