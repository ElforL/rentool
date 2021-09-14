import * as admin from 'firebase-admin';

// // Start writing Firebase Functions
// // https://firebase.google.com/docs/functions/typescript

const isOnGithubActions = process.env.GITHUB_ACTIONS == 'true';

admin.initializeApp();

export * from './other_firestore_triggers';
export * from './meetings';
export * from './users';
if (!isOnGithubActions)
    exports.fcm = require('./fcm');
