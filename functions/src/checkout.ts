import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Checkout } from 'checkout-sdk-node';

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

  if (context.auth == null) {
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
  const cko = new Checkout('sk_test_f1a1d5bb-9b4b-4660-b6b8-f769158fa21e');
  const db = admin.firestore();
  try {
    db.settings({ ignoreUndefinedProperties: true });
  } catch (_) { }


  const userCkoDoc = db.doc(`cko_users_payments/${uid}`);
  try {
    // Delete previous cards
    const cko_customer: any = await cko.customers.get(email);
    await cko_customer.instruments.forEach(async (element: any) => {
      try {
        await cko.instruments.delete(element.id);
      } catch (_) { }
    });


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
      batch.set(db.doc(`Users/${uid}/private/card`), {
        'expiry_month': result.source.expiry_month,
        'expiry_year': result.source.expiry_year,
        'name': result.source.name,
        'scheme': result.source.scheme,
        'last4': result.source.last4,
        'bin': result.source.bin,
      });
    }

    batch.set(userCkoDoc, {
      'init_payment_id': result.id,
      'customer': {
        'id': result.customer.id,
        'email': result.customer.email,
      },
      'source': result.source,
      'first_token_headers': data.headers,
    });
    batch.set(userCkoDoc.collection('payments').doc(result.id), result);

    // Commit
    await batch.commit();
    response.statusCode = result.status === "Pending" ? 202 : 201;
    response.success = true;
    response.message = result.status;
    response.value = {
      'customer_id': result.customer.id
    };
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