const admin = require("firebase-admin")

const PROJECT_ID = "rentool-5a78c";

const password = process.argv[2] 
const adminEmailAddress = process.argv[3] 
const emailVerifiedEmail = process.argv[4]
const secondEmail = process.argv[5]

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


async function createTool(user, toolName, rentPrice, insurance, location, media = []) {
    const doc = await admin.firestore().collection('Tools').add({
        'ownerUID': user.uid,
        'name': toolName,
        'description': `this the tool of ${user.displayName}\nهذه الأداة ملك لـ ${user.displayName}`,
        'rentPrice': rentPrice,
        'insuranceAmount': insurance,
        'media': media,
        'location': location,
        'isAvailable': true,
        'acceptedRequestID': null,
        'currentRent': null,
    })

    console.log(`Created tool ${toolName} id= ${doc.id}, owner = ${user.displayName}`);
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
        admin.auth().setCustomUserClaims(user.uid, { 'admin': true });

    // Set user's ID
    if (id != null)
        admin.firestore().doc(`Users/${user.uid}/private/ID`).set({
            'idNumber': id,
        }, { merge: true })

    return user;
}

addUser(adminEmailAddress, password, 'Admin', true, getRandomId(), true);
addUser(emailVerifiedEmail, password, 'Verified', true);
addUser(secondEmail, password, 'Second', true, getRandomId())
// .then(async (user) => {
//     await createTool(user, 'The second tool', 7, 12, 'riyadh');
// });
