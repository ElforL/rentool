import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Checkout } from 'checkout-sdk-node';

const env = functions.config();
let cko: Checkout | undefined;
if (typeof env.checkout != 'undefined') {
  cko = new Checkout(env.checkout.sec_key);
}

/**
* Create a payment source using a token provided by the user.
* 
* Accepts an object/map with the format: 
* ```
*  { 
*    // [result] is the response the user gets when calling `/tokens` endpoint and recives the token
*    'body': result.body,  
*    'headers': result.headers.onlyStartsWith('cko')  
*  }.
* ```
* 
* Rreturns
* ```
* response: {
*    'statusCode': number;
*    'success': boolean;
*    'message': string | null;
*    'value': any;
*    'error': any;
* }
* ```
*/
export const addSourceFromToken = functions.https.onCall(async (data, context) => {
  const response: {
    statusCode: number;
    success: boolean;
    message: string | null;
    value: any;
    error: any;
  } = {
    'statusCode': 401,
    'success': false,
    'message': null,
    'value': null,
    'error': {
      'type': 'unauthorized',
      'code': 'not-signed-in'
    },
  }

  if (context.auth == null || cko == null) {
    return response;
  }
  if (context.auth!.token.email_verified !== true) {
    response.error.code = "unverified-email-address";
    return response;
  }
  if (context.auth!.token.email == null) {
    response.statusCode = 403;
    response.error.code = 'no-email-registered';
    return response;
  }

  const uid = context.auth!.uid
  const email = context.auth!.token.email!;

  const token = data.body.token;
  if (typeof token !== 'string' || token == null) {
    response.statusCode = 400;
    response.error.type = 'bad-request';
    response.error.code = 'no-token-provided';
    return response;
  }

  // Initiate Checkout and Firestore
  const db = admin.firestore();
  try {
    db.settings({ ignoreUndefinedProperties: true });
  } catch (_) { }


  const userCkoDoc = db.doc(`cko_users_payments/${uid}`);
  try {
    // Delete previous cards
    try {
      const cko_customer: any = await cko.customers.get(email);
      await cko_customer.instruments.forEach(async (element: any) => {
        try {
          await cko!.instruments.delete(element.id);
        } catch (_) { }
      });
      cko.customers.update(cko_customer.id, { 'name': uid });
    } catch (_) { }

    // Request the payment
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

    // Check if it was approved
    if (result.approved === false) {
      response.statusCode = 406;
      response.error.type = 'declined';
      response.error.code = 'declined';
      response.message = `Status: ${result.status}`;
      return response;
    }

    // Create a batch and stage the changes
    const batch = db.batch();

    if (result.status !== "Pending") {
      /** 
       * Payouts require a first and last name that i get from the card name
       * so if the name has no spaces in between, payouts = false
       */
      const payoutsBasedOnName = typeof result.source.name == 'string' ? (result.source.name as string).split(' ').length >= 2 : false;

      /* 
      TODO
      if(result.source.payouts == null){
        // check if card accepts payout
        // 1- call support and ask for a way
        // 2- try a payout then refund it ? (can you refund it?, maybe charge back?)
        checkCardPayout();
      }
      */
      batch.set(db.doc(`Users/${uid}/private/card`), {
        'expiry_month': result.source.expiry_month,
        'expiry_year': result.source.expiry_year,
        'name': result.source.name,
        'scheme': result.source.scheme,
        'last4': result.source.last4,
        'bin': result.source.bin,
        'payouts': result.source.payouts ?? payoutsBasedOnName,
      });

      batch.set(admin.firestore().doc(`Users/${uid}/private/checklist`), {
        'hasCard': true,
        'cardPayouts': result.source.payouts ?? payoutsBasedOnName,
      }, { merge: true });

      batch.set(userCkoDoc, {
        'init_payment_id': result.id,
        'customer': {
          'id': result.customer.id,
          'email': result.customer.email,
        },
        'source': result.source,
      });
    }
    batch.set(userCkoDoc.collection('payments').doc(result.id), {
      'first_token_headers': data.headers,
      [result.status]: result
    });

    // Commit
    await batch.commit();
    response.success = true;
    response.message = result.status;

    if (result.status === "Pending") {
      // Requires redirecting the user
      response.statusCode = 202;
      response.value = {
        'redircet_link': result._links.redirect.href,
      };
    } else {
      response.statusCode = 201;
      response.value = {
        'payouts': result.source.payouts
      };
    }

    response.error = null;
    return response;
  } catch (error) {
    response.statusCode = 500;
    response.error.type = 'internal-server-error';
    response.error.code = 'internal-server-error';

    if (typeof error === 'object' && error != null) {
      const http_code = (error as any).http_code;
      // if there's no http code log it and return 500
      if (typeof http_code === 'undefined') {
        functions.logger.error('An unexpected error occured.', 'No http code for error type.', error);
        return response;
      }

      // 401 - Unauthorized
      if (http_code == 401) {
        functions.logger.error("Checkout returned 401-Unauthorized. Check the keys or if there's any extra authentication required", error);
        return response;
      }

      // 422 - Invalid data was sent
      if (http_code == 422) {
        functions.logger.log("422 error:", error);
        response.statusCode = 400;
        response.error.type = 'bad-request';
        response.error.code = 'invalid-data';
        return response;
      }

      // 429 - Too many requests or duplicate request detected
      if (http_code == 429) {
        functions.logger.log("429 error:", error);
        response.statusCode = 429;
        response.error.type = 'too-many-requests';
        response.error.code = 'too-many-requests';
        return response;
      }

      // 502 - Bad gateway
      if (http_code == 502) {
        response.statusCode = 502;
        response.error.type = 'bad-gateway';
        response.error.code = 'bad-gateway';
        return response;
      }
    }

    functions.logger.error('An unexpected error occured', error);
    return response;
  }
});

export const deleteCard = functions.https.onCall(async (data, context) => {
  const response: {
    statusCode: number;
    success: boolean;
    message: string | null;
    value: any;
    error: any;
  } = {
    'statusCode': 401,
    'success': false,
    'message': null,
    'value': null,
    'error': {
      'type': 'unauthorized',
      'code': 'not-signed-in'
    },
  }

  if (context.auth?.uid == null || context.auth.token.email == null || cko == null) {
    return response;
  }
  const uid = context.auth.uid;

  const hasCard = (await admin.firestore().doc(`Users/${uid}/private/checklist`).get()).data()?.hasCard;
  if (!hasCard) {
    response.statusCode = 404;
    response.error.type = 'Not Found';
    response.error.code = 'user-has-no-card';
    return response;
  }

  // Delete previous cards
  try {
    const cko_customer: any = await cko.customers.get(context.auth.token.email);

    if (cko_customer.default != null) {
      const instruments = cko_customer.instruments;
      for (const key in instruments) {
        if (Object.prototype.hasOwnProperty.call(instruments, key)) {
          const instrument = instruments[key];
          try {
            await cko.instruments.delete(instrument.id);
          } catch (error) { }
        }
      }
      cko.customers.update(cko_customer.id, { 'name': uid, 'default': null });
    }
  } catch (_) { }

  const batch = admin.firestore().batch();
  const userCkoDoc = admin.firestore().doc(`cko_users_payments/${uid}`);

  batch.delete(admin.firestore().doc(`Users/${uid}/private/card`));

  batch.set(admin.firestore().doc(`Users/${uid}/private/checklist`), {
    'hasCard': false,
    'cardPayouts': false,
  }, { merge: true });

  batch.update(userCkoDoc, {
    'init_payment_id': null,
    'source': null,
  });

  await batch.commit();

  response.success = true;
  response.error = null;
  response.message = 'Success';
  response.statusCode = 200;
  return response;
});
