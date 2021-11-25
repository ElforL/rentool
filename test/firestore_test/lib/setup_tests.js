const admin = require("firebase-admin")

const PROJECT_ID = "rentool-5a78c";

const password = process.argv[2] //?? 'HardPass@20';
const adminEmailAddress = process.argv[3] //?? 'admin@test.com';
const emailVerifiedEmail = process.argv[4]// ?? 'verf@test.com';

admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: PROJECT_ID,
});

function getRandomInt(max) {
    return Math.floor(Math.random() * max);
}

function getRandomId() {
    var out = '';
    for (let i = 0; i < 10; i++) {
        var rand;
        if (i == 0) {
            rand = getRandomInt(9) + 1;
        } else {
            rand = getRandomInt(10);
        }
        out += rand;
    }
    return out;
}

async function addUser(email, password, name, emailVerified, id, isAdmin) {
    // Add user in Auth
    const user = await admin.auth().createUser({
        email: email,
        emailVerified: emailVerified,
        password: password,
        displayName: name,
        disabled: false,
    });

    if (isAdmin == true)
        admin.auth().setCustomUserClaims(user.uid, {'admin': true});

    // Set user's ID
    if (id != null)
        admin.firestore().doc(`Users/${user.uid}/private/ID`).set({
            'idNumber': id,
        }, { merge: true })

    return user;
}

addUser(adminEmailAddress, password, 'Admin', true, getRandomId(), true);
addUser(emailVerifiedEmail, password, 'Verified', true);
