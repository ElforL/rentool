const firebase = require('@firebase/rules-unit-testing');
const { describe, it, afterAll, beforeEach } = require('@jest/globals');

const PROJECT_ID = "rentool-5a78c";
const myUid = "user_abc";
const theirUid = "user_xyc";
const myToolId = "tool_abc";
const theirToolId = "tool_xyz";

process.env['FIRESTORE_EMULATOR_HOST'] = "localhost:8080";

function myAuth(isEmailVerified) {
  return { uid: myUid, email: 'test@gmail.com', email_verified: isEmailVerified };
}

function getFirestore(auth) {
  return firebase.initializeTestApp({ projectId: PROJECT_ID, auth: auth }).firestore();
}

function getAdminFirestore() {
  return firebase.initializeAdminApp({ projectId: PROJECT_ID }).firestore();
}

beforeEach(async () => {
  await firebase.clearFirestoreData({ projectId: PROJECT_ID })
});

describe("`Users/` access rules", () => {
  /** 
   * Returns:
   * ```
   *  'name': 'Test Name',
   *  'photoURL': null,
   *  'rating': rating,
   *  'numOfReviews': numOfReviews,
   * ``` */
  function userDoc(rating, numOfReviews) {
    return {
      'name': 'Test Name',
      'photoURL': null,
      'rating': rating,
      'numOfReviews': numOfReviews,
    }
  }

  it("R- Signed out user CAN read other user's document", async () => {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${theirUid}`).set(userDoc(3, 1));

    const db = getFirestore(null);
    const testDoc = db.collection('Users').doc(theirUid);
    await firebase.assertSucceeds(testDoc.get());
  });

  it("R- Signed in user CAN read other's user document", async () => {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${theirUid}`).set(userDoc(3, 1));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(theirUid);
    await firebase.assertSucceeds(testDoc.get());
  });

  it("R- Signed in user CAN read own user document", async () => {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${myUid}`).set(userDoc(3, 1));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid);
    await firebase.assertSucceeds(testDoc.get());
  });

  it("C- Signed in user CAN'T create other user's document", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(theirUid);
    await firebase.assertFails(testDoc.set(userDoc(0, 0)));
  });

  it("C- Signed in user CAN create own user document if rating == numOfReviews == 0", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid);
    await firebase.assertSucceeds(testDoc.set(userDoc(0, 0)));
  });

  it("C- Signed in user CAN'T create own user document if rating != 0 & numOfReviews == 0", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid);
    await firebase.assertFails(testDoc.set(userDoc(1, 0)));
  });

  it("C- Signed in user CAN'T create own user document if rating == 0 & numOfReviews != 0", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid);
    await firebase.assertFails(testDoc.set(userDoc(0, 1)));
  });

  it("C- Signed in user CAN'T create own user document if rating != 0 & numOfReviews != 0", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid);
    await firebase.assertFails(testDoc.set(userDoc(2, 1)));
  });

  it("U- Signed out user CAN'T change other user's document", async () => {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${theirUid}`).set(userDoc(3.3, 23));

    const db = getFirestore(null);
    const testDoc = db.collection('Users').doc(theirUid);
    await firebase.assertFails(testDoc.update({
      'name': 'Changed value',
    }));
  });

  it("U- Signed in user CAN'T update other user's document", async () => {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${theirUid}`).set(userDoc(3.3, 23));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(theirUid);
    await firebase.assertFails(testDoc.update({
      'name': 'Changed value',
    }));
  });

  it("U- Signed in user CAN'T update own user document", async () => {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${myUid}`).set(userDoc(3.3, 23));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid);
    await firebase.assertFails(testDoc.update({
      'name': 'new Name',
      'photoURL': 'https://www.google.com/images/branding/googlelogo/1x/googlelogo_light_color_272x92dp.png',
    }));
  });

  it("D- Signed in user CAN'T delete other user's document", async () => {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${theirUid}`).set(userDoc(3.3, 23));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(theirUid);
    await firebase.assertFails(testDoc.delete());
  });

  it("D- Signed in user CAN'T delete own user document", async () => {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${myUid}`).set(userDoc(3.3, 23));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid);
    await firebase.assertFails(testDoc.delete());
  });
});

// PRIVATE DOCS

describe("`Users/private/ID` access rules", () => {
  it("R- Signed out user CAN'T read other user's id doc", async () => {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${theirUid}/private/ID`).set({
      'idNumber': '1122334455',
    });

    const db = getFirestore(null);
    const testDoc = db.collection('Users').doc(theirUid).collection('private').doc('ID');
    await firebase.assertFails(testDoc.get());
  });

  it("R- Signed in user CAN'T read other user's id doc", async () => {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${theirUid}/private/ID`).set({
      'idNumber': '1122334455',
    });

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(theirUid).collection('private').doc('ID');
    await firebase.assertFails(testDoc.get());
  });

  it("R- Signed in user CAN read own id doc", async () => {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${myUid}/private/ID`).set({
      'idNumber': '1122334455',
    });

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('ID');
    await firebase.assertSucceeds(testDoc.get());
  });

  it("C- Signed out user CAN'T create other user's ID doc", async () => {
    const db = getFirestore(null);
    const testDoc = db.collection('Users').doc(theirUid).collection('private').doc('ID');
    await firebase.assertFails(testDoc.set({ 'idNumber': '1122334455' }));
  });

  it("C- Signed in user CAN'T create other user's ID doc", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(theirUid).collection('private').doc('ID');
    await firebase.assertFails(testDoc.set({ 'idNumber': '1122334455' }));
  });

  it("C- Signed in user CAN create own ID doc if it only contains 'idNumber'", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('ID');
    await firebase.assertSucceeds(testDoc.set({ 'idNumber': '1122334455' }));
  });

  it("C- Signed in user CAN't create own ID doc if it doesn't only contains 'idNumber'", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('ID');
    await firebase.assertFails(testDoc.set({
      'idNumber': '1122334455',
      'foo': 'bar'
    }));
  });

  it("C- Signed in user CAN't create own ID doc if it doesn't contains 'idNumber'", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('ID');
    await firebase.assertFails(testDoc.set({
      'foo': 'bar'
    }));
  });

  it("U- Signed in user CAN'T update own ID doc", async () => {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${theirUid}/private/ID`).set({
      'idNumber': '1122334455',
    });

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('ID');
    await firebase.assertFails(testDoc.update({ 'idNumber': '5522334455' }));
  });

  it("D- Signed in user CAN'T delete own ID doc", async () => {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${theirUid}/private/ID`).set({
      'idNumber': '1122334455',
    });

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('ID');
    await firebase.assertFails(testDoc.delete());
  });
});

describe("`Users/private/card` access rules", () => {
  async function createCardDoc(uid) {
    const admin = getAdminFirestore();
    await admin.doc(`Users/${uid}/private/card`).set({
      'bin': '123456',
      'last4': '1234',
    });
  }

  it("R- Signed out user CAN'T read other user's card doc", async () => {
    await createCardDoc(theirUid);

    const db = getFirestore(null);
    const testDoc = db.collection('Users').doc(theirUid).collection('private').doc('card');
    await firebase.assertFails(testDoc.get());
  });

  it("R- Signed in user CAN'T read other user's card doc", async () => {
    await createCardDoc(theirUid);

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(theirUid).collection('private').doc('card');
    await firebase.assertFails(testDoc.get());
  });

  it("R- Signed in user CAN read own card doc", async () => {
    await createCardDoc(myUid);

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('card');
    await firebase.assertSucceeds(testDoc.get());
  });

  it("C- Signed out user CAN'T create other user's card doc", async () => {
    const db = getFirestore(null);
    const testDoc = db.collection('Users').doc(theirUid).collection('private').doc('card');
    await firebase.assertFails(testDoc.set({
      'bin': '123456',
      'last4': '1234',
    }));
  });

  it("C- Signed in user CAN'T create other user's card doc", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(theirUid).collection('private').doc('card');
    await firebase.assertFails(testDoc.set({
      'bin': '123456',
      'last4': '1234',
    }));
  });

  it("C- Signed in user CAN'T create own card doc", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('card');
    await firebase.assertFails(testDoc.set({
      'bin': '123456',
      'last4': '1234',
    }));
  });

  it("U- Signed out user CAN'T update other user's card doc", async () => {
    await createCardDoc(theirUid);

    const db = getFirestore(null);
    const testDoc = db.collection('Users').doc(theirUid).collection('private').doc('card');
    await firebase.assertFails(testDoc.update({ 'last4': '4321' }));
  });

  it("U- Signed in user CAN'T update other user's card doc", async () => {
    await createCardDoc(theirUid);

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(theirUid).collection('private').doc('card');
    await firebase.assertFails(testDoc.update({ 'last4': '4321' }));
  });

  it("U- Signed in user CAN'T update own card doc", async () => {
    await createCardDoc(myUid);

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('card');
    await firebase.assertFails(testDoc.update({ 'last4': '4321' }));
  });

  it("D- Signed out user CAN'T delete other user's card doc", async () => {
    await createCardDoc(theirUid);

    const db = getFirestore(null);
    const testDoc = db.collection('Users').doc(theirUid).collection('private').doc('card');
    await firebase.assertFails(testDoc.delete());
  });

  it("D- Signed in user CAN'T delete other user's card doc", async () => {
    await createCardDoc(theirUid);

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(theirUid).collection('private').doc('card');
    await firebase.assertFails(testDoc.delete());
  });

  it("D- Signed in user CAN'T delete own card doc", async () => {
    await createCardDoc(myUid);

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('card');
    await firebase.assertFails(testDoc.delete());
  });
});

describe("`Tools` access rules", () => {
  function myValidTool(iOwnerUID, currentRent = null) {
    return {
      ownerUID: iOwnerUID,
      name: 'Test Tool',
      description: "Test tool's description",
      location: 'Test city',
      isAvailable: true,
      rentPrice: 23,
      insuranceAmount: 100,
      media: null,
      acceptedRequestID: null,
      currentRent: currentRent,
    }
  }

  // READ
  it("R- Signed in user CAN read a tool document", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertSucceeds(testDoc.get());
  });
  it("R- Signed out user CAN read a tool document", async () => {
    const db = getFirestore(null);
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertSucceeds(testDoc.get());
  });

  it("C- Signed out user CAN'T create a tool document", async () => {
    const db = getFirestore(null);
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.set(myValidTool('foo')));
  });

  // CREATE
  it("C- Signed in user with verified email but no ID nor card CAN'T create a tool document", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.set(myValidTool(myUid)));
  });
  it("C- Signed in user with verified email and ID but no card CAN'T create a tool document", async () => {
    const admin = getAdminFirestore();
    const idDoc = admin.collection('Users').doc(myUid).collection('private').doc('ID');
    await idDoc.set({ 'idNumber': 2233445566 });

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.set(myValidTool(myUid)));
  });
  it("C- Signed in user with verified email and card but no ID CAN'T create a tool document", async () => {
    const admin = getAdminFirestore();
    const cardDoc = admin.doc(`cko_users_payments/${myUid}`);
    await cardDoc.set({
      'customer.id': 'cus_2324123',
      'source.id': 'src_2gs324123',
    });

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.set(myValidTool(myUid)));
  });
  it("C- Signed in user with verified email and ID and card CAN create a tool document", async () => {
    const admin = getAdminFirestore();
    const idDoc = admin.collection('Users').doc(myUid).collection('private').doc('ID');
    await idDoc.set({ 'idNumber': 2233445566 });
    const cardDoc = admin.doc(`cko_users_payments/${myUid}`);
    await cardDoc.set({
      'customer': { 'id': 'cus_2324123' },
      'source': { 'id': 'src_2gs324123' },
    });

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertSucceeds(testDoc.set(myValidTool(myUid)));
  });
  it("C- Signed in user with unverified email but has an ID and card CANT'T create a tool document", async () => {
    const admin = getAdminFirestore();
    const idDoc = admin.collection('Users').doc(myUid).collection('private').doc('ID');
    await idDoc.set({ 'idNumber': 2233445566 });
    const cardDoc = admin.doc(`cko_users_payments/${myUid}`);
    await cardDoc.set({
      'customer.id': 'cus_2324123',
      'source.id': 'src_2gs324123',
    });

    const db = getFirestore(myAuth(false));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.set(myValidTool(myUid)));
  });

  it("U- Signed in user CAN update own tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(myToolId);
    await myToolDoc.set(myValidTool(myUid));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertSucceeds(testDoc.update({ 'name': 'newTestName' }));
  });
  it("U- Signed in user CAN'T update other's tool documents", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(theirToolId);
    await myToolDoc.set(myValidTool(theirUid));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.update({ 'name': 'newTestName' }));
  });
  it("U- Singed out user CAN'T update other's tool documents", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(theirToolId);
    await myToolDoc.set(myValidTool(theirUid));

    const db = getFirestore(null);
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.update({ 'name': 'foo' }));
  });

  it("D- Signed in user CAN delete own tool document if it's not rented", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(myToolId);
    await myToolDoc.set(myValidTool(myUid));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertSucceeds(testDoc.delete());
  });
  it("D- Signed in user CAN'T delete own tool document if it's rented", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(myToolId);
    await myToolDoc.set(myValidTool(myUid, 'dsa'));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.delete());
  });

  it("D- Signed in user CAN'T delete other's tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(theirToolId);
    await myToolDoc.set(myValidTool(theirUid));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.delete());
  });
  it("D- Singed out user CAN'T delete other's tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(theirToolId);
    await myToolDoc.set(myValidTool(theirUid));

    const db = getFirestore(null);
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.delete());
  });
});

describe("`Requests` access rules", () => {
  function myValidTool(iOwnerUID, currentRent = null) {
    return {
      ownerUID: iOwnerUID,
      name: 'Test Tool',
      description: "Test tool's description",
      location: 'Test city',
      isAvailable: true,
      rentPrice: 23,
      insuranceAmount: 100,
      media: null,
      acceptedRequestID: null,
      currentRent: currentRent,
    }
  }

  function myValidRequest(toolID, renterUID, isAccepted = false, isRented = false) {
    return {
      insuranceAmount: 20.1,
      isAccepted: isAccepted,
      isRented: isRented,
      numOfDays: 2,
      rentPrice: 3.4,
      toolID: toolID,
      renterUID: renterUID,
    }
  }

  async function createToolWithRequest(admin, requestID, toolId, tool, request, accepted = false) {
    const myToolDoc = admin.collection('Tools').doc(toolId);
    await myToolDoc.set(tool);
    await myToolDoc.collection('requests').doc(requestID).set(request);
    if (accepted) {
      await myToolDoc.update({
        'acceptedRequestID': requestID,
      });
    }
  }

  it("U- Owner CAN'T accept a request if one is already accepted", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(myToolId);
    await myToolDoc.set(myValidTool(myUid));
    const requestID = 'req_id';
    await myToolDoc.collection('requests').doc(requestID).set(myValidRequest(myToolId, theirUid));
    await myToolDoc.update({ 'acceptedRequestID': requestID })

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.update({ 'acceptedRequestID': 'user_test' }));
  });

  it("R- Signed out user CAN'T read a request document", async () => {
    const admin = getAdminFirestore();
    const requestID = 'req_1';
    await createToolWithRequest(admin, requestID, theirToolId, myValidTool(theirUid), myValidRequest(theirToolId, 'renterUid'));

    const db = getFirestore(null);
    const testDoc = db.doc(`Tools/${theirToolId}/requests/${requestID}`);
    await firebase.assertFails(testDoc.get());
  });
  it("R- Signed in user CAN'T read others' request document", async () => {
    const admin = getAdminFirestore();
    const requestID = 'req_1';
    await createToolWithRequest(admin, requestID, theirToolId, myValidTool(theirUid), myValidRequest(theirToolId, 'renterUid'));

    const db = getFirestore(myAuth(true));
    const testDoc = db.doc(`Tools/${theirToolId}/requests/${requestID}`);
    await firebase.assertFails(testDoc.get());
  });
  it("R- Signed in user CAN read own request document", async () => {
    const admin = getAdminFirestore();
    const requestID = 'req_1';
    await createToolWithRequest(admin, requestID, theirToolId, myValidTool(theirUid), myValidRequest(theirToolId, myUid));

    const db = getFirestore(myAuth(true));
    const testDoc = db.doc(`Tools/${theirToolId}/requests/${requestID}`);
    await firebase.assertSucceeds(testDoc.get());
  });
  it("R- Signed in user CAN read request on own tool", async () => {
    const admin = getAdminFirestore();
    const requestID = 'req_1';
    await createToolWithRequest(admin, requestID, myToolId, myValidTool(myUid), myValidRequest(myToolId, theirUid));

    const db = getFirestore(myAuth(true));
    const testDoc = db.doc(`Tools/${myToolId}/requests/${requestID}`);
    await firebase.assertSucceeds(testDoc.get());
  });

  it("C- Signed in user with unverified email and no ID nor card CAN'T send a request", async () => {
    const admin = getAdminFirestore();
    const theirToolDoc = admin.doc(`Tools/${theirToolId}`);
    await theirToolDoc.set(myValidTool(theirUid));

    const db = getFirestore(myAuth(false));
    const toolDoc = db.collection('Tools').doc(theirToolId);

    const requestID = 'req_id';
    const requestTestDoc = toolDoc.collection('requests').doc(requestID)

    await firebase.assertFails(requestTestDoc.set(myValidRequest(theirToolId, myUid)));
  });
  it("C- Signed in user with verified email and no ID nor card CAN'T send a request", async () => {
    const admin = getAdminFirestore();
    const theirToolDoc = admin.doc(`Tools/${theirToolId}`);
    await theirToolDoc.set(myValidTool(theirUid));

    const db = getFirestore(myAuth(true));
    const toolDoc = db.collection('Tools').doc(theirToolId);

    const requestID = 'req_id';
    const requestTestDoc = toolDoc.collection('requests').doc(requestID)

    await firebase.assertFails(requestTestDoc.set(myValidRequest(theirToolId, myUid)));
  });
  it("C- Signed in user with verified email and card but no ID CAN'T send a request", async () => {
    const admin = getAdminFirestore();
    const theirToolDoc = admin.doc(`Tools/${theirToolId}`);
    await theirToolDoc.set(myValidTool(theirUid));

    const idDoc = admin.collection('Users').doc(myUid).collection('private').doc('ID');
    await idDoc.set({ 'idNumber': 2233445566 });

    const db = getFirestore(myAuth(true));
    const toolDoc = db.collection('Tools').doc(theirToolId);

    const requestID = 'req_id';
    const requestTestDoc = toolDoc.collection('requests').doc(requestID)

    await firebase.assertFails(requestTestDoc.set(myValidRequest(theirToolId, myUid)));
  });
  it("C- Signed in user with verified email an ID but no card CAN'T send a request", async () => {
    const admin = getAdminFirestore();
    const theirToolDoc = admin.doc(`Tools/${theirToolId}`);
    await theirToolDoc.set(myValidTool(theirUid));

    const cardDoc = admin.doc(`cko_users_payments/${myUid}`);
    await cardDoc.set({
      'customer': { 'id': 'cus_2324123' },
      'source': { 'id': 'src_2gs324123' },
    });

    const db = getFirestore(myAuth(true));
    const toolDoc = db.collection('Tools').doc(theirToolId);

    const requestID = 'req_id';
    const requestTestDoc = toolDoc.collection('requests').doc(requestID)

    await firebase.assertFails(requestTestDoc.set(myValidRequest(theirToolId, myUid)));
  });
  it("C- Signed in user with verified email an ID and a card CAN send a request", async () => {
    const admin = getAdminFirestore();
    const theirToolDoc = admin.doc(`Tools/${theirToolId}`);
    await theirToolDoc.set(myValidTool(theirUid));

    const idDoc = admin.collection('Users').doc(myUid).collection('private').doc('ID');
    await idDoc.set({ 'idNumber': 2233445566 });
    const cardDoc = admin.doc(`cko_users_payments/${myUid}`);
    await cardDoc.set({
      'customer': { 'id': 'cus_2324123' },
      'source': { 'id': 'src_2gs324123' },
    });

    const db = getFirestore(myAuth(true));
    const toolDoc = db.collection('Tools').doc(theirToolId);

    const requestID = 'req_id';
    const requestTestDoc = toolDoc.collection('requests').doc(requestID)

    await firebase.assertSucceeds(requestTestDoc.set(myValidRequest(theirToolId, myUid)));
  });

  it("U- Signed in user CAN'T update own request document if it's accepted", async () => {
    const admin = getAdminFirestore();
    const requestID = 'req_1';
    await createToolWithRequest(admin, requestID, theirToolId, myValidTool(theirUid), myValidRequest(theirToolId, myUid, true));

    const db = getFirestore(myAuth(true));
    const testDoc = db.doc(`Tools/${theirToolId}/requests/${requestID}`);
    await firebase.assertFails(testDoc.update({ numOfDays: 5 }));
  });

  it("D- Signed in user CAN delete own request document", async () => {
    const admin = getAdminFirestore();
    const requestID = 'req_1';
    await createToolWithRequest(admin, requestID, theirToolId, myValidTool(theirUid), myValidRequest(theirToolId, myUid));

    const db = getFirestore(myAuth(true));
    const testDoc = db.doc(`Tools/${theirToolId}/requests/${requestID}`);
    await firebase.assertSucceeds(testDoc.delete());
  });
  it("D- Signed in user CAN delete request on own tool", async () => {
    const admin = getAdminFirestore();
    const requestID = 'req_1';
    await createToolWithRequest(admin, requestID, myToolId, myValidTool(myUid), myValidRequest(myToolId, theirUid));

    const db = getFirestore(myAuth(true));
    const testDoc = db.doc(`Tools/${myToolId}/requests/${requestID}`);
    await firebase.assertSucceeds(testDoc.delete());
  });
  it("D- Signed in user CAN'T delete own request document if it's renter", async () => {
    const admin = getAdminFirestore();
    const requestID = 'req_1';
    await createToolWithRequest(admin, requestID, theirToolId, myValidTool(theirUid), myValidRequest(theirToolId, myUid, true, true));

    const db = getFirestore(myAuth(true));
    const testDoc = db.doc(`Tools/${theirToolId}/requests/${requestID}`);
    await firebase.assertFails(testDoc.delete());
  });
  it("D- Signed in user CAN'T delete request on own tool if it's renter", async () => {
    const admin = getAdminFirestore();
    const requestID = 'req_1';
    await createToolWithRequest(admin, requestID, myToolId, myValidTool(myUid), myValidRequest(myToolId, theirUid, true, true));

    const db = getFirestore(myAuth(true));
    const testDoc = db.doc(`Tools/${myToolId}/requests/${requestID}`);
    await firebase.assertFails(testDoc.delete());
  });
});


afterAll(async () => {
  await firebase.clearFirestoreData({ projectId: PROJECT_ID })
});