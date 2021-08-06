import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * handle tools' `acceptedRequestID` field changes
 * - if a new requst was added this function changes the request's `isAccepted` to true
 * - if `acceptedRequestID` changed to null this function changes the old request's `isAccepted` to false (if it still exist)
*/
export const toolUpdated = functions.firestore.document('Tools/{toolID}')
  .onUpdate(async (change, context) => {
    /** did `acceptedRequestID` field changed */
    const oldData = change.before.data();
    const newData = change.after.data();

    const changedAcceptedID = oldData.acceptedRequestID != newData.acceptedRequestID;
    if (changedAcceptedID) {
      const toolID = change.after.id;
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
          'renter_ids_ok': false,
          'renter_pics_urls': [],
          // if the meeting was done and succesful and a rent object/doc was created
          'rent_started': false,
          // any errors that could occur with the meeting e.g., payment fail, database error... etc
          // TODO consider changing it to list in case there were multiple erros
          'error': null,
        });

        // Send notification to renter
        addNotification(renterUID, 'REQ_ACC', {
          'notificationBodyArgs': [newData.name],
          'toolID': context.params.toolID,
          'requestID': context.params.requestID,
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

export const requestWrite = functions.firestore.document('Tools/{toolID}/requests/{requestID}')
  .onWrite(async (change, context) => {
    const toolDoc = admin.firestore().doc(`Tools/${context.params.toolID}`);
    if (!change.after.exists) {
      // DELETE
      const docData = change.before.data()!;
      // if the request was accepted, remove its ID from `acceptedRequestID`
      if (docData && docData.isAccepted == true) {
        await toolDoc.update({ 'acceptedRequestID': null });
      }

      // delete the request snippet in the user subcollection
      const renterUID = docData.renterUID;
      const renterRequestDoc = admin.firestore().doc(`Users/${renterUID}/requests/${docData.toolID}`);
      await renterRequestDoc.delete();

      // send notification to renter
      const toolDocData = await toolDoc.get();
      const toolName = toolDocData.data()?.name;
      return addNotification(docData.renterUID, 'REQ_DEL', {
        'notificationBodyArgs': [toolName],
        'toolID': context.params.toolID,
        'requestID': context.params.requestID,
        'toolName': toolName,
      });
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
    return admin.firestore().doc(`idsList/${idNumber}`).set({ 'uid': uid, 'time': snapshot.createTime });
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

/**
 * create a new doc in the user's notification collections which also invokes `newNotification()` and sends the user an FCM message
 * @param userUID the user's uid
 * @param code
 * Notifications codes:
 * - `REQ_REC`: request recived
 * - `REQ_ACC`: request accepted
 * - `REQ_DEL`: request deleted
 * - `REN_START`: rent started
 * - `REN_END`: rent ended
 * - `DC_DAM`: disagreement case settled and tool is damaged
 * - `DC_NDAM`: disagreement case settled and tool is not damaged
 * @param data the notification data required for each code
 * - `REQ_REC`: toolID, requestID, toolName, renterName
 * - `REQ_ACC`: toolID, requestID, toolName,
 * - `REQ_DEL`: toolID, requestID, toolName,
 * - `REN_START`: toolID, toolName, renterName, ownerName, renterUID
 * - `REN_END`: toolID, toolName, renterName, ownerName, renterUID
 * - `DC_DAM`: toolID, toolName
 * - `DC_NDAM`: toolID, toolName
 * @returns A Promise resolved with a DocumentReference pointing to the newly created document after it has been written to the backend.
 */
function addNotification(userUID: string, code: string, data: any)
  : Promise<FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>> {
  const notifsCollection = admin.firestore().collection(`Users/${userUID}/notifications`);
  return notifsCollection.add({
    'code': code,
    'data': data,
    'time': admin.firestore.FieldValue.serverTimestamp(),
    'isRead': false,
  });
}