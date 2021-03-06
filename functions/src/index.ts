import * as admin from 'firebase-admin';

// // Start writing Firebase Functions
// // https://firebase.google.com/docs/functions/typescript

const isOnGithubActions = process.env.GITHUB_ACTIONS == 'true';

admin.initializeApp();

export * from './other_firestore_triggers';
export * from './deliver_meetings';
export * from './return_meeting';
export * from './checkout';
export * from './checkout_webhook';
export * from './users';
if (!isOnGithubActions)
    exports.fcm = require('./fcm');
