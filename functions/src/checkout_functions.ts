/**
 * Non cloud functions for checkout. 
*/

import { Checkout } from 'checkout-sdk-node';
import * as admin from 'firebase-admin';

const cko = new Checkout('sk_test_f1a1d5bb-9b4b-4660-b6b8-f769158fa21e');

export async function refundPayment(
  payment_id: string,
  payment_type: string,
  idempotencyKey: string,
  payment_reference_metadata: Object | undefined,
  amount?: number | undefined,
) {
  const reference = (await admin.firestore().collection('payment_references').add({
    'payment_id': null,
    'type': payment_type,
    'processed': false,
    'metadata': payment_reference_metadata ?? {},
  })).id;

  return cko.payments.refund(
    payment_id,
    {
      'amount': amount,
      'reference': reference
    },
    idempotencyKey,
  );
}

export async function chargeCustomer(
  uid: string,
  amount: number,
  payment_type: string,
  description: string,
  idempotencyKey: string,
  payment_reference_metadata: Object | undefined,
) {
  const user = await admin.auth().getUser(uid);
  const userPaymentsDoc = await admin.firestore().doc(`cko_users_payments/${uid}`).get();

  const cus_id = userPaymentsDoc.data()!.customer.id;

  const reference = (await admin.firestore().collection('payment_references').add({
    'payment_id': null,
    'type': payment_type,
    'processed': false,
    'metadata': payment_reference_metadata ?? {},
  })).id;

  return cko.payments.request({
    'source': {
      'type': 'customer',
      'id': cus_id
    },
    'reference': reference,
    'amount': amount,
    'currency': 'SAR',
    'payment_type': 'Recurring',
    'description': description,
    'customer': {
      'id': cus_id,
      'email': user.email,
    }
  }, idempotencyKey);
}

export async function payOutCustomer(
  reciverUid: string,
  amount: number,
  payment_type: string,
  description: string,
  idempotencyKey: string,
  payment_reference_metadata: Object | undefined,
) {
  const reciver = await admin.auth().getUser(reciverUid);

  const reciverPaymentsDoc = await admin.firestore().doc(`cko_users_payments/${reciverUid}`).get();

  const src_id = reciverPaymentsDoc.data()!.source.id;
  const reciver_first_name = (reciverPaymentsDoc.data()!.source.name as string).split(' ')[0];

  let reciver_last_name: string = (reciverPaymentsDoc.data()!.source.name as string).split(' ')[1];
  if (typeof reciver_last_name == 'undefined' || reciver_last_name.trim() == '') reciver_last_name = 'R';

  const reciver_email = reciver.email!;
  const reciver_cus_id = reciverPaymentsDoc.data()!.customer.id;

  const reference = (await admin.firestore().collection('payment_references').add({
    'payment_id': null,
    'type': payment_type,
    'processed': false,
    'metadata': payment_reference_metadata ?? {},
  })).id;

  return payOutCard(
    src_id,
    reciver_first_name,
    reciver_last_name,
    amount,
    description,
    'SAR',
    reciver_email,
    reciver_cus_id,
    reference,
    idempotencyKey,
  );
}

/**
 * 
 * 
 * @param src_id The payment source identifier (e.g., a card source identifier). `^(src)_(\w{26})$`
 * @param first_name The payout destination owner's first name
 * @param last_name The payout destination owner's last name
 * @param amount The payment amount. The exact format depends on the currency. Omit the amount or provide a value of 0 to perform a card verification. _**(integer >= 0)**_
 * @param currency The three-letter ISO currency code
 * @param cus_email An optional email address to associate with the customer
 * @param cus_id The identifier of an existing customer. If neither customer id nor email is provided, then a new customer will be registered. `^(cus)_(\w{26})$`
 * @param reference A reference you can later use to identify this payment, such as an order number _**(<= 50 characters)**_
 * @returns Promise\<Object\>
 * @throws [Error] for invalid argments
 */
export function payOutCard(
  src_id: string,
  first_name: string,
  last_name: string,
  amount: number,
  description: string,
  currency: string,
  cus_email: string | undefined,
  cus_id: string | undefined,
  reference: string | undefined,
  idempotencyKey: string
): Promise<Object> {
  if (!RegExp('^(src)_(\\w{26})$').test(src_id)) {
    throw Error(`Invalid argments: invalid source id: ${src_id}`);
  } else if (amount < 0) {
    throw Error(`Invalid argments: amount must be >= 0: ${amount}`);
  } else if (currency.length !== 3) {
    throw Error(`Invalid argments: currency must be 3 three-letter ISO currency code: ${currency}`);
  } else if (reference != null && reference!.length > 50) {
    throw Error(`Invalid argments: reference length must be <= 50 characters>: ${reference?.length}`);
  } else if (cus_id != null && !RegExp('^(cus)_(\\w{26})$').test(cus_id)) {
    throw Error(`Invalid argments: invalid customer id: ${cus_id}`);
  }

  return cko.payments.request({
    "destination": {
      "type": "id",
      "id": src_id,
      "first_name": first_name,
      "last_name": last_name,
    },
    'description': description,
    "reference": reference,
    "amount": amount,
    "currency": currency,
    "customer": {
      "id": cus_id,
      "email": cus_email,
    },
  }, idempotencyKey);
}

/**
 * 
 * @param type :
 * - insurance_refund_return_error
 * - compensation_payout_return_error
 * - both_paid_but_payments_successful_is_false
 * @returns 
 */
export function createCkoProblem(type: string, error: any, metadata: any) {
  return admin.firestore().collection('payment_known_problems').add({
    'type': type,
    'error_obj': error as Object,
    'metadata': metadata,
  });
}

export function setPayIdToReference(reference: string, payment_id: string) {
  return admin.firestore().doc(`payment_references/${reference}`).update({
    'payment_id': payment_id,
  });
}