import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Checkout } from 'checkout-sdk-node';

// TODO RENAME URGENT
export const ckoPay = functions.https.onCall(async (data, context) => {
  if (context.auth == null) return 'Unauthorized';
  if (context.auth!.token.email == null) return 'User has no email address';

  const uid = context.auth!.uid
  const email = context.auth!.token.email!;

  console.log('Data:');
  console.log(data);
  const token = data.body.token;
  console.log(`token = ${token}`);

  const cko = new Checkout('sk_test_f1a1d5bb-9b4b-4660-b6b8-f769158fa21e');

  const db = admin.firestore();
  try {
    db.settings({ ignoreUndefinedProperties: true });
  } catch (error) { }

  const userCkoDoc = db.doc(`cko_users_payments/${uid}`);
  try {
    const result: any = await cko.payments.request({
      "source": {
        "type": "token",
        "token": token
      },
      "amount": 0,
      "currency": "SAR",
      "customer": {
        "email": email,
        "name": uid,
      }
    });

    if (result.approve === false) {
      console.log('NOT APPROVED', result);
      return result.status ?? 'not-approved';
    }

    const batch = db.batch();

    batch.set(db.doc(`Users/${uid}/private/card`), {
      'expiry_month': result.source.expiry_month,
      'expiry_year': result.source.expiry_year,
      'name': result.source.name,
      'scheme': result.source.scheme,
      'last4': result.source.last4,
      'bin': result.source.bin,
    });

    batch.set(userCkoDoc, {
      'init_payment_id': result.id,
      'customer': {
        'id': result.customer.id,
        'email': result.customer.email,
      },
      'card': {
        'expiry_month': result.source.expiry_month,
        'expiry_year': result.source.expiry_year,
        'name': result.source.name,
        'scheme': result.source.scheme,
        'last4': result.source.last4,
        'bin': result.source.bin,
      },
      'first_token_headers': data.headers,
    });
    batch.set(userCkoDoc.collection('payments').doc(result.id), result);
    return batch.commit();
  } catch (error) {
    function setDoc(e: any) {
      return userCkoDoc.set({'error': error });
    }
    console.log('ERROR CAUGHT');
    console.log(error);
    return setDoc(error);
  }
});