const assert = require('assert');
const firebase = require('@firebase/rules-unit-testing');
const { describe, it, afterAll, beforeEach } = require('@jest/globals');
const { Console } = require('console');

const PROJECT_ID = "rentool-5a78c";
const myUid = "user_abc";
const theirUid = "user_xyc";
const myToolId = "tool_abc";
const theirToolId = "tool_xyz";

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
    await firebase.assertSucceeds(testDoc.set({ 'foo': 'bar' }));
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
});

describe("`Tools` rules", () => {
  const myValidTool = {
    ownerUID: myUid,
    name:'Test Tool',
    description: "Test tool's description",
    location: 'Test city',
    isAvailable:  true,
    rentPrice:  23,
    insuranceAmount:  100,
    media:  null,
    acceptedRequestID:  null,
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
    await firebase.assertFails(testDoc.set({'foo':'bar'}));
  });

  // CREATE
  it("Signed in user with verified email but no ID nor credit card CAN'T create a tool document", async () => {
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.set(myValidTool));
  });
  it("Signed in user with verified email and ID but no credit card CAN'T create a tool document", async () => {
    const admin = getAdminFirestore();
    const idDoc = admin.collection('Users').doc(myUid).collection('private').doc('ID');
    await idDoc.set({'idNumber': 2233445566});
    
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.set(myValidTool));
  });
  it("Signed in user with verified email and credit card but no ID CAN'T create a tool document", async () => {
    const admin = getAdminFirestore();
    const creditDoc = admin.collection('Users').doc(myUid).collection('private').doc('creditCard');
    await creditDoc.set({'number': 112233445566});

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.set(myValidTool));
  });
  it("Signed in user with verified email, credit card and ID CAN create a tool document", async () => {
    const admin = getAdminFirestore();
    const idDoc = admin.collection('Users').doc(myUid).collection('private').doc('ID');
    const creditDoc = admin.collection('Users').doc(myUid).collection('private').doc('creditCard');
    await idDoc.set({'idNumber': 2233445566});
    await creditDoc.set({'number': 112233445566});
    
    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertSucceeds(testDoc.set(myValidTool));
  });
  it("Signed in user with unverified email but has credit card and ID CANT'T create a tool document", async () => {
    const admin = getAdminFirestore();
    const idDoc = admin.collection('Users').doc(myUid).collection('private').doc('ID');
    const creditDoc = admin.collection('Users').doc(myUid).collection('private').doc('creditCard');
    await idDoc.set({'idNumber': 2233445566});
    await creditDoc.set({'number': 112233445566});

    const db = getFirestore(myAuth(false));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertFails(testDoc.set({'ownerUID':myUid}));
  });

  it("Signed in user CAN update own tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(myToolId);
    await myToolDoc.set({'ownerUID': myUid});

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertSucceeds(testDoc.set(myValidTool));
  });
  it("Signed in user CAN'T update other's tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(theirToolId);
    await myToolDoc.set({'ownerUID': theirUid});

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.set({'ownerUID': theirUid, 'name': 'foo'}));
  });
  it("Guest user CAN'T update other's tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(theirToolId);
    await myToolDoc.set({'ownerUID': theirUid});

    const db = getFirestore(null);
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.set({'ownerUID': theirUid, 'name': 'foo'}));
  });

  it("Signed in user CAN delete own tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(myToolId);
    await myToolDoc.set({'ownerUID': myUid});

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(myToolId);
    await firebase.assertSucceeds(testDoc.delete());
  });
  it("Signed in user CAN'T delete other's tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(theirToolId);
    await myToolDoc.set({'ownerUID': theirUid});

    const db = getFirestore(myAuth(true));
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.delete());
  });
  it("Guest user CAN'T delete other's tool document", async () => {
    const admin = getAdminFirestore();
    const myToolDoc = admin.collection('Tools').doc(theirToolId);
    await myToolDoc.set({'ownerUID': theirUid});

    const db = getFirestore(null);
    const testDoc = db.collection('Tools').doc(theirToolId);
    await firebase.assertFails(testDoc.delete());
  });

});

afterAll(async() => {
  await firebase.clearFirestoreData({projectId: PROJECT_ID})
});