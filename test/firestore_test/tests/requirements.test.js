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

beforeEach(async () => {
	await firebase.clearFirestoreData({ projectId: PROJECT_ID })
});

describe("FR12 - The system must be able to determine if a user is authorized to create a new post.", () => {
	it("Signed out user CAN'T create a tool document", async () => {
		const db = getFirestore(null);
		const testDoc = db.collection('Tools').doc(theirToolId);
		await firebase.assertFails(testDoc.set(myValidTool('foo')));
	});
	it("Signed in user with verified email but no ID nor card CAN'T create a tool document", async () => {
		const db = getFirestore(myAuth(true));
		const testDoc = db.collection('Tools').doc(myToolId);
		await firebase.assertFails(testDoc.set(myValidTool(myUid)));
	});
	it("Signed in user with verified email and ID but no card CAN'T create a tool document", async () => {
		const admin = getAdminFirestore();
		const idDoc = admin.collection('Users').doc(myUid).collection('private').doc('ID');
		await idDoc.set({ 'idNumber': 2233445566 });

		const db = getFirestore(myAuth(true));
		const testDoc = db.collection('Tools').doc(myToolId);
		await firebase.assertFails(testDoc.set(myValidTool(myUid)));
	});
	it("Signed in user with verified email and card but no ID CAN'T create a tool document", async () => {
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
	it("Signed in user with unverified email but has an ID and card CANT'T create a tool document", async () => {
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
	it("Signed in user with verified email and ID and card CAN create a tool document", async () => {
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
});

describe("FR14 - The system must be able to determine if a user is authorized to edit or remove a post", () => {
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

	it("Signed in user CAN delete own tool document if it's not rented", async () => {
		const admin = getAdminFirestore();
		const myToolDoc = admin.collection('Tools').doc(myToolId);
		await myToolDoc.set(myValidTool(myUid));

		const db = getFirestore(myAuth(true));
		const testDoc = db.collection('Tools').doc(myToolId);
		await firebase.assertSucceeds(testDoc.delete());
	});
	it("Signed in user CAN'T delete own tool document if it's rented", async () => {
		const admin = getAdminFirestore();
		const myToolDoc = admin.collection('Tools').doc(myToolId);
		await myToolDoc.set(myValidTool(myUid, 'dsa'));

		const db = getFirestore(myAuth(true));
		const testDoc = db.collection('Tools').doc(myToolId);
		await firebase.assertFails(testDoc.delete());
	});

	it("Signed in user CAN'T delete other's tool document", async () => {
		const admin = getAdminFirestore();
		const myToolDoc = admin.collection('Tools').doc(theirToolId);
		await myToolDoc.set(myValidTool(theirUid));

		const db = getFirestore(myAuth(true));
		const testDoc = db.collection('Tools').doc(theirToolId);
		await firebase.assertFails(testDoc.delete());
	});
	it("Singed out user CAN'T delete other's tool document", async () => {
		const admin = getAdminFirestore();
		const myToolDoc = admin.collection('Tools').doc(theirToolId);
		await myToolDoc.set(myValidTool(theirUid));

		const db = getFirestore(null);
		const testDoc = db.collection('Tools').doc(theirToolId);
		await firebase.assertFails(testDoc.delete());
	});
});

describe("FR16.A - The system must be able to determine if a user is authorized to view tool-requests to a certain post.", () => {
	it("Signed out user CAN'T read a request document", async () => {
		const admin = getAdminFirestore();
		const requestID = 'req_1';
		await createToolWithRequest(admin, requestID, theirToolId, myValidTool(theirUid), myValidRequest(theirToolId, 'renterUid'));

		const db = getFirestore(null);
		const testDoc = db.doc(`Tools/${theirToolId}/requests/${requestID}`);
		await firebase.assertFails(testDoc.get());
	});
	it("Signed in user CAN'T read others' request document", async () => {
		const admin = getAdminFirestore();
		const requestID = 'req_1';
		await createToolWithRequest(admin, requestID, theirToolId, myValidTool(theirUid), myValidRequest(theirToolId, 'renterUid'));

		const db = getFirestore(myAuth(true));
		const testDoc = db.doc(`Tools/${theirToolId}/requests/${requestID}`);
		await firebase.assertFails(testDoc.get());
	});
	it("Signed in user CAN read own request document", async () => {
		const admin = getAdminFirestore();
		const requestID = 'req_1';
		await createToolWithRequest(admin, requestID, theirToolId, myValidTool(theirUid), myValidRequest(theirToolId, myUid));

		const db = getFirestore(myAuth(true));
		const testDoc = db.doc(`Tools/${theirToolId}/requests/${requestID}`);
		await firebase.assertSucceeds(testDoc.get());
	});
	it("Signed in user CAN read request on own tool", async () => {
		const admin = getAdminFirestore();
		const requestID = 'req_1';
		await createToolWithRequest(admin, requestID, myToolId, myValidTool(myUid), myValidRequest(myToolId, theirUid));

		const db = getFirestore(myAuth(true));
		const testDoc = db.doc(`Tools/${myToolId}/requests/${requestID}`);
		await firebase.assertSucceeds(testDoc.get());
	});
});
describe("FR16.B & FR18 - The system must be able to determine if a user is authorized to accept tool-requests to a certain post.", () => {
	it("Signed in user CAN update own tool's acceptedRequestID", async () => {
		const admin = getAdminFirestore();
		const myToolDoc = admin.collection('Tools').doc(myToolId);
		await createToolWithRequest(admin, 'newReqId', myToolId, myValidTool(myUid), myValidRequest(myToolId, theirUid), false)

		const db = getFirestore(myAuth(true));
		const testDoc = db.collection('Tools').doc(myToolId);
		await firebase.assertSucceeds(testDoc.update({ 'acceptedRequestID': 'newReqId' }));
	});
	it("Signed in user CAN'T update other tool's acceptedRequestID", async () => {
		const admin = getAdminFirestore();
		const myToolDoc = admin.collection('Tools').doc(theirToolId);
		await myToolDoc.set(myValidTool(theirUid));

		const db = getFirestore(myAuth(true));
		const testDoc = db.collection('Tools').doc(theirToolId);
		await firebase.assertFails(testDoc.update({ 'acceptedRequestID': 'newReqId' }));
	});
	it("Singed out user CAN'T update other tool's acceptedRequestID", async () => {
		const admin = getAdminFirestore();
		const myToolDoc = admin.collection('Tools').doc(theirToolId);
		await myToolDoc.set(myValidTool(theirUid));

		const db = getFirestore(null);
		const testDoc = db.collection('Tools').doc(theirToolId);
		await firebase.assertFails(testDoc.update({ 'acceptedRequestID': 'newReqId' }));
	});
});
describe("FR16.C - The system must be able to determine if a user is authorized to deny tool-requests to a certain post.", () => {
	it("Signed in user CAN delete own request document", async () => {
		const admin = getAdminFirestore();
		const requestID = 'req_1';
		await createToolWithRequest(admin, requestID, theirToolId, myValidTool(theirUid), myValidRequest(theirToolId, myUid));

		const db = getFirestore(myAuth(true));
		const testDoc = db.doc(`Tools/${theirToolId}/requests/${requestID}`);
		await firebase.assertSucceeds(testDoc.delete());
	});
	it("Signed in user CAN delete request on own tool", async () => {
		const admin = getAdminFirestore();
		const requestID = 'req_1';
		await createToolWithRequest(admin, requestID, myToolId, myValidTool(myUid), myValidRequest(myToolId, theirUid));

		const db = getFirestore(myAuth(true));
		const testDoc = db.doc(`Tools/${myToolId}/requests/${requestID}`);
		await firebase.assertSucceeds(testDoc.delete());
	});
	it("Signed in user CAN'T delete own request document if it's renter", async () => {
		const admin = getAdminFirestore();
		const requestID = 'req_1';
		await createToolWithRequest(admin, requestID, theirToolId, myValidTool(theirUid), myValidRequest(theirToolId, myUid, true, true));

		const db = getFirestore(myAuth(true));
		const testDoc = db.doc(`Tools/${theirToolId}/requests/${requestID}`);
		await firebase.assertFails(testDoc.delete());
	});
	it("Signed in user CAN'T delete request on own tool if it's renter", async () => {
		const admin = getAdminFirestore();
		const requestID = 'req_1';
		await createToolWithRequest(admin, requestID, myToolId, myValidTool(myUid), myValidRequest(myToolId, theirUid, true, true));

		const db = getFirestore(myAuth(true));
		const testDoc = db.doc(`Tools/${myToolId}/requests/${requestID}`);
		await firebase.assertFails(testDoc.delete());
	});
});

describe("FR20 - The system must be able to determine if a user is authorized to send, edit, or remove a tool-request to a tool-post.", () => {
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