import { Checkout } from 'checkout-sdk-node';

const cko = new Checkout('sk_test_f1a1d5bb-9b4b-4660-b6b8-f769158fa21e');

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
  currency: string,
  cus_email: string | undefined,
  cus_id: string | undefined,
  reference: string | undefined,
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
    "reference": reference,
    "amount": amount,
    "currency": currency,
    "customer": {
      "id": cus_id,
      "email": cus_email,
    }
  });
}