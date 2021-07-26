const assert = require('assert');
const firebase = require('@firebase/rules-unit-testing');
const { describe, it, afterAll, beforeEach } = require('@jest/globals');
const { Console } = require('console');

const PROJECT_ID = "rentool-5a78c";
const myUid = "user_abc";
const theirUid = "user_xyc";
const myToolId = "tool_abc";
const theirToolId = "tool_xyz";

process.env['FIRESTORE_EMULATOR_HOST'] = "localhost:8080";

function myAuth(isEmailVerified) {
  return { uid: myUid, email:'test@gmail.com', email_verified: isEmailVerified };
}

function getFirestore(auth) {
  return firebase.initializeTestApp({ projectId: PROJECT_ID, auth: auth }).firestore();
}

function getAdminFirestore() {
  return firebase.initializeAdminApp({ projectId: PROJECT_ID }).firestore();
}

beforeEach(async ()=>{
  await firebase.clearFirestoreData({projectId: PROJECT_ID})
});

describe("`Users` rules", () => {
  it("Signed in user CAN read own user document", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid);
    await firebase.assertSucceeds(testDoc.get());
  });

  it("Signed in user CAN read other's user document", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(theirUid);
    await firebase.assertSucceeds(testDoc.get());
  });

  it("Guest user CAN read other's user document", async () => {
    const db = getFirestore(null);
    const testDoc = db.collection('Users').doc(theirUid);
    await firebase.assertSucceeds(testDoc.get());
  });

  it("Signed in user CAN change own user document", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid);
    // TODO change to valid and full fields (for all tests aswell)
    await firebase.assertSucceeds(testDoc.set({
      'name': 'Test Name',
      'rating': 0,
    }));
  });

  it("Signed in user CAN'T change other's user document", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(theirUid);
    await firebase.assertFails(testDoc.set({ 'foo': 'bar' }));
  });

  it("Guest user CAN'T change other's user document", async () => {
    const db = getFirestore(null);
    const testDoc = db.collection('Users').doc(theirUid);
    await firebase.assertFails(testDoc.set({ 'foo': 'bar' }));
  });
  
  // PRIVATE DOCS

  it("User CAN'T read other user's private docs", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(theirUid).collection('private').doc('ID');
    await firebase.assertFails(testDoc.get());
  });

  it("User CAN read own private docs", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('ID');
    await firebase.assertSucceeds(testDoc.get());
  });

  it("User CAN set new ID", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('ID');
    await firebase.assertSucceeds(testDoc.set({ 'idNumber': '1122334455' }));
  });

  it("User CAN'T update ID", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('ID');
    testDoc.set({ 'idNumber': '1122334455' })
    await firebase.assertFails(testDoc.update({ 'idNumber': '5522334455' }));
  });

  function card(name = 'FOO BAR') {
    return {
      number: 112233445566,
      name_on_card: name,
      ccv: '987',
      expYear: 12,
      expMonth: 2020
    };
  }

  it("User CAN set first card", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('creditCard');
    await firebase.assertSucceeds(testDoc.set(card()));
  });

  it("User CAN set new card", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('creditCard');
    testDoc.set(card());
    await firebase.assertSucceeds(testDoc.set(card('TEST NAME')));
  });

  it("User CAN update card", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Users').doc(myUid).collection('private').doc('creditCard');
    testDoc.set(card());
    await firebase.assertSucceeds(testDoc.update({ 'name': 'BAR FOO' }));
  });
});

describe("`Tools` rules", () => {
  function myValidTool(iOwnerUID){
    return {
      ownerUID: iOwnerUID,
      name:'Test Tool',
      description: "Test tool's description",
      location: 'Test city',
      isAvailable:  true,
      rentPrice:  23,
      insuranceAmount:  100,
      media:  null,
      acceptedRequestID:  null,
      currentRent: null,
    }
  }

  function myValidRequest(iToolID){
    return {
      insuranceAmount: 20.1,
      isAccepted : false,
      isRented : false,
      numOfDays : 2,
      rentPrice : 3.4,
      toolID :iToolID
    }
  }

  // READ
  it("Signed in user CAN read a tool document", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertSucceeds(testDoc.get());
  });
  it("Guest user CAN read a tool document", async () => {
    const db = getFirestore(null);
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertSucceeds(testDoc.get());
  });

  it("Guest user CAN'T create a tool document", async () => {
    const db = getFirestore(null);
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.set(myValidTool('foo')));
  });

  // CREATE
  it("Signed in user with verified email but no ID nor credit card CAN'T create a tool document", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.set(myValidTool(myUid)));
  });
  it("Signed in user with verified email and ID but no credit card CAN'T create a tool document", async () => {
    const admin = getAdminFirestore();
    const idDoc = admin.collection('Users').doc(myUid).collection('private').doc('ID');
    await idDoc.set({'idNumber': 2233445566});
    
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.set(myValidTool(myUid)));
  });
  it("Signed in user with verified email and credit card but no ID CAN'T create a tool document", async () => {
    const admin = getAdminFirestore();
    const creditDoc = admin.collection('Users').doc(myUid).collection('private').doc('creditCard');
    await creditDoc.set({'number': 112233445566});

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.set(myValidTool(myUid)));
  });
  it("Signed in user with verified email, credit card and ID CAN create a tool document", async () => {
    const admin = getAdminFirestore();
    const idDoc = admin.collection('Users').doc(myUid).collection('private').doc('ID');
    const creditDoc = admin.collection('Users').doc(myUid).collection('private').doc('creditCard');
    await idDoc.set({'idNumber': 2233445566});
    await creditDoc.set({'number': 112233445566});
    
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertSucceeds(testDoc.set(myValidTool(myUid)));
  });
  it("Signed in user with unverified email but has credit card and ID CANT'T create a tool document", async () => {
    const admin = getAdminFirestore();
    const idDoc = admin.collection('Users').doc(myUid).collection('private').doc('ID');
    const creditDoc = admin.collection('Users').doc(myUid).collection('private').doc('creditCard');
    await idDoc.set({'idNumber': 2233445566});
    await creditDoc.set({'number': 112233445566});

    const db = getFirestore(myAuth(false));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.set(myValidTool(myUid)));
  });

  it("Signed in user CAN update own tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(myToolId);
    await myToolDoc.set(myValidTool(myUid));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertSucceeds(testDoc.update({'name': 'newTestName'}));
  });
  it("Signed in user CAN'T update other's tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(theirToolId);
    await myToolDoc.set(myValidTool(theirUid));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.update({'name': 'newTestName'}));
  });
  it("Guest user CAN'T update other's tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(theirToolId);
    await myToolDoc.set(myValidTool(theirUid));

    const db = getFirestore(null);
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.update({'name': 'foo'}));
  });

  it("Signed in user CAN delete own tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(myToolId);
    await myToolDoc.set(myValidTool(myUid));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertSucceeds(testDoc.delete());
  });
  it("Signed in user CAN'T delete other's tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(theirToolId);
    await myToolDoc.set(myValidTool(theirUid));

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.delete());
  });
  it("Guest user CAN'T delete other's tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(theirToolId);
    await myToolDoc.set(myValidTool(theirUid));

    const db = getFirestore(null);
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.delete());
  });

  it("Signed in user CAN'T accept a request if one is already accepted", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(myToolId);
    await myToolDoc.set(myValidTool(myUid));
    await myToolDoc.collection('requests').doc(theirUid).set(myValidRequest(myToolId));
    await myToolDoc.update({'acceptedRequestID': theirUid})

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.update({'acceptedRequestID': 'user_test'}));
  });

});

afterAll(async() => {
  await firebase.clearFirestoreData({projectId: PROJECT_ID})
});