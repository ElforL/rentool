import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { addNotification } from './fcm';
import *  as algolia from 'algoliasearch';

const isOnLocalEmulator = process.env.FUNCTIONS_EMULATOR == 'true';
const env = functions.config();
let algoliIndex: algolia.SearchIndex | undefined;
if (typeof env.algolia != 'undefined') {
  const index = isOnLocalEmulator ? 'tools_test' : 'tools';
  algoliIndex = algolia.default(env.algolia.appid, env.algolia.apikey).initIndex(index);
}

export const toolCreated = functions.firestore.document('Tools/{toolID}')
  .onCreate((snapshot, context) => {
    const toolID = snapshot.id;
    const data = snapshot.data();
    
    if(algoliIndex == null) return null;
    
    return algoliIndex.saveObject({
      objectID: toolID,
      ...data
    });
  });

/**
 * handle tools' `acceptedRequestID` field changes
 * - if a new requst was added this function changes the request's `isAccepted` to true
 * - if `acceptedRequestID` changed to null this function changes the old request's `isAccepted` to false (if it still exist)
*/
export const toolUpdated = functions.firestore.document('Tools/{toolID}')
  .onUpdate(async (change, context) => {
    const oldData = change.before.data();
    const newData = change.after.data();
    const toolID = change.after.id;

    await algoliIndex?.partialUpdateObject({
      objectID: toolID,
      ...newData
    });

    /** did `acceptedRequestID` field changed */
    const changedAcceptedID = oldData.acceptedRequestID != newData.acceptedRequestID;
    if (changedAcceptedID) {
      const oldRequestID = oldData.acceptedRequestID;
      const newRequestID = newData.acceptedRequestID;
      if (newRequestID != null) {
        const requestDoc = admin.firestore().doc(`Tools/${toolID}/requests/${newRequestID}`);
        const requestData = (await requestDoc.get()).data()!;
        const renterUID = requestData.renterUID;
        // create a deliver_meeting doc
        await admin.firestore().doc(`Tools/${toolID}/deliver_meetings/${newRequestID}`).set({
          'isActive': true,
          'ownerUID': newData.ownerUID,
          'owner_arrived': false,
          'owner_pics_ok': false,
          'owner_ids_ok': false,
          'owner_pics_urls': [],
          'renterUID': renterUID,
          'renter_arrived': false,
          'renter_pics_ok': false,
          'owner_id': null,
          'renter_id': null,
          'renter_ids_ok': false,
          'renter_pics_urls': [],

          'processing_payment': true, // both confirmed ids and awaiting payment capturing and payouts
          'payments_successful': null, // payments processing is done and successful
          'renter_action_required': false, // should check doc([meeting_doc]/private/{uid})
          'owner_action_required': false, // should check doc([meeting_doc]/private/{uid})

          // if the meeting was done and succesful and a rent object/doc was created
          'rent_started': false,
          // any errors that could occur with the meeting e.g., payment fail, database error... etc
          'errors': [],
        });

        // Send notification to renter
        addNotification(renterUID, 'REQ_ACC', {
          'notificationBodyArgs': [newData.name],
          'toolID': context.params.toolID,
          'requestID': newRequestID,
          'toolName': newData.name,
        });

        // accepted a new request
        return admin.firestore().doc(`Tools/${toolID}/requests/${newRequestID}`).update({ 'isAccepted': true });
      } else {
        // changed acceptedRequestID to null
        // i.e., canceled accepted request

        // set its meeting to inactive
        await admin.firestore().doc(`Tools/${toolID}/deliver_meetings/${oldRequestID}`).update({ 'isActive': false });

        // change the request's `isAccepted` to false if it still exist (i.e., it wasn't deleted)
        const oldRequestDoc = await admin.firestore().doc(`Tools/${toolID}/requests/${oldRequestID}`);
        if ((await oldRequestDoc.get()).exists) {
          return oldRequestDoc.update({ 'isAccepted': false });
        } else {
          return null;
        }
      }
    } else {
      return null;
    }
  });

export const toolDeleted = functions.firestore.document('Tools/{toolID}')
  .onDelete(async (snapshot, context) => {
    // When the tool is deleted, the requests need to be deleted as well.
    // deleteCollection() and deleteQueryBatch() are used to delete collection(Tools/${toolID}/requests)

    // Q: why are These functions decalred inside the function instead of outside?
    // They are placed in this scope to prevent them from being in the other cloud functions containers.
    // learn more: [How cloud functions work](https://firebase.google.com/docs/functions#how_does_it_work)

    async function deleteCollection(collectionPath: string, batchSize: number) {
      const collectionRef = admin.firestore().collection(collectionPath);
      const query = collectionRef.orderBy('__name__').limit(batchSize);

      return new Promise((resolve, reject) => {
        deleteQueryBatch(query, resolve).catch(reject);
      });
    }


    async function deleteQueryBatch(query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData>, resolve: (value: unknown) => void) {
      const snapshot = await query.get();

      const batchSize = snapshot.size;
      if (batchSize === 0) {
        // When there are no documents left, we are done
        resolve(null);
        return;
      }

      // Delete documents in a batch
      const batch = admin.firestore().batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();

      // Recurse on the next process tick, to avoid
      // exploding the stack.
      process.nextTick(() => {
        deleteQueryBatch(query, resolve);
      });
    }

    const toolID = context.params.toolID;

    await algoliIndex?.deleteObject(toolID);

    try {
      await admin.storage().bucket(`rentool-5a78c.appspot.com`).deleteFiles({ prefix: `tools_media/${toolID}/` })
    } catch (error) {
      functions.logger.error(error);
    }
    return deleteCollection(`Tools/${toolID}/requests`, 10);
  });


export const requestWrite = functions.firestore.document('Tools/{toolID}/requests/{requestID}')
  .onWrite(async (change, context) => {
    const toolDoc = admin.firestore().doc(`Tools/${context.params.toolID}`);
    var toolDocData;
    if (!change.after.exists) {
      // DELETE
      const docData = change.before.data()!;
      // if the request was accepted, remove its ID from `acceptedRequestID`
      if (docData && docData.isAccepted == true) {
        toolDocData = await toolDoc.get();
        if (toolDocData.exists)
          await toolDoc.update({ 'acceptedRequestID': null });
      }

      // delete the request snippet in the user subcollection
      const renterUID = docData.renterUID;
      const renterRequestDoc = admin.firestore().doc(`Users/${renterUID}/requests/${docData.toolID}`);
      await renterRequestDoc.delete();

      // send notification to renter
      // IF it wasn't rented before (prevent notification when a rent ends and the request is moved)
      if (!docData.isRented) {
        if (toolDocData == null)
          toolDocData = await toolDoc.get();
        if (toolDocData.exists) {
          const toolName = toolDocData.data()?.name;
          return addNotification(docData.renterUID, 'REQ_DEL', {
            'notificationBodyArgs': [toolName],
            'toolID': context.params.toolID,
            'requestID': context.params.requestID,
            'toolName': toolName,
          });
        }
        else return null;
      } else {
        return null;
      }
    } else {
      // UPDATE OR CREATE
      const docData = change.after.data()!;

      if (!change.before.exists) {
        // if it was a new request
        // send notification to owner
        const toolDocData = await toolDoc.get();
        const toolName = toolDocData.data()?.name;
        const renterDoc = await admin.firestore().doc(`Users/${docData.renterUID}`).get();
        const renterName = renterDoc.data()?.name;
        await addNotification(toolDocData.data()!.ownerUID, 'REQ_REC', {
          'notificationBodyArgs': [toolName, renterName],
          'toolID': context.params.toolID,
          'requestID': context.params.requestID,
          'toolName': toolName,
          'renterName': renterName,
        });
      }

      // update/create the request snippet in the user's subcollection
      const renterUID = docData.renterUID;
      const renterRequestDoc = await admin.firestore().doc(`Users/${renterUID}/requests/${docData.toolID}`).get();
      if (renterRequestDoc.exists && renterRequestDoc.data()!.id != change.after.id) {
        // if the user already has a request doc for the tool in his `requests` subcollection (i.e., already sent a request to this tool)
        // then delete the new request
        return change.after.ref.delete();
      } else {
        // otherwise, create the request doc
        docData.id = change.after.id;
        return renterRequestDoc.ref.set(docData);
      }
    }
  });

// Creates an entry in db/idsList when the user sets thier ID number
export const IdCreated = functions.firestore.document('Users/{uid}/private/ID')
  .onCreate(async (snapshot, context) => {
    const idNumber = snapshot.data().idNumber;
    const uid = snapshot.ref.parent.parent!.id;
    const batch = admin.firestore().batch();
    batch.set(admin.firestore().doc(`idsList/${idNumber}`), {
      'uid': uid,
      'time': snapshot.createTime
    });
    batch.set(snapshot.ref.parent.doc('checklist'), {
      'hasId': true,
    }, { merge: true });
    return batch.commit();
  });

export const disagreementCaseUpdated = functions.firestore.document('/disagreementCases/{caseID}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();

    if (newData == null) return null;

    if (newData.Result_IsToolDamaged != null) {
      // a result has been set
      const isToolDamaged = newData.Result_IsToolDamaged;
      const toolID = newData.toolID;

      const toolDoc = await admin.firestore().doc(`Tools/${toolID}`).get();
      const toolName = toolDoc.data()?.name;

      const notifCode = isToolDamaged ? 'DC_DAM' : 'DC_NDAM';
      const notifData = {
        'notificationBodyArgs': [toolName],
        'toolID': toolID,
        'toolName': toolName,
      };
      addNotification(newData.renterUID, notifCode, notifData);
      addNotification(newData.ownerUID, notifCode, notifData);

      const requestID = newData.requestID;
      return admin.firestore().doc(`Tools/${toolID}/return_meetings/${requestID}`).update({
        'disagreementCaseSettled': true,
        'disagreementCaseResult': isToolDamaged,
      });
    }

    return null;
  });
