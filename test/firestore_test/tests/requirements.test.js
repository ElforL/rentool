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

describe("FR14 - The system must be able to determine if a user is authorized to edit or remove a post", () => {
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

afterAll(async () => {
	await firebase.clearFirestoreData({ projectId: PROJECT_ID })
});