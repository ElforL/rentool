# Cloud Functions
This is the npm project folder of the system's cloud functions. and it contains the code for all the functions.

The deployed functions are:
-	`toolCreated` runs when a new document is created in the ‘Tools’ collection. Its job is to send the new tool’s data to Algolia.
-	`toolUpdated` runs when a tool document is updated, and it handles accepting a request by checking if the field acceptedRequestID was changed.
-	`toolDeleted` runs when a tool document is deleted. It deletes the tool’s data from Algolia, deletes the tool pictures and videos from storage, and deletes the ‘requests’ subcollection.
-	`requestWrite` runs when a tool-request document gets created, updated, or deleted. It handles sending notifications, creating a reference in the renter’s ‘requests’ subcollection, and handling the request if it was accepted before being deleted.
-	`IdCreated` runs when the user adds his/her id number. It adds the ID number to the ‘idsList’ collection and updates the user’s checklist document.
-	`deliverMeetingUpdated` runs when the delivery meeting document gets updated. It handles the flow of the meeting. For example, if a user sets his/her arrival to false all the next steps will be set to false which are media and IDs confirmation in this case. It also adds the users’ IDs in the meeting document when the ID confirmation step comes. And it starts the payment process and rent after IDs confirmation.
-	`dMeetPaymendDocUpdated` runs when the ‘private/payments_processing’ document of the delivery meeting gets updated. It handles the payment flow and verification for starting the rent.
-	`returnMeetingUpdated` runs when return meeting document gets updated. It handles the flow of the meeting and the payments requests and refunds at the end of the rent.
-	`disagreementCaseUpdated` runs when a disagreement case document gets updated. When a case is reviewed and a result is submitted, it sends a notification to the renter and owner of the decision and updates the return meeting document.
-	`addSourceFromToken` is an HTTPS callable function. It’s called when the user has a token for his/her credit/debit card and wants to add it to the system. The function will then call Checkout and verify the card. This will be explained further in [4.4.2 Adding a credit/debit card].
-	`deleteCard` is also HTTPS callable, and it’s called when the user wants to remove his/her credit/debit card from the system.
-	`payments` is also an HTTPS callable function. However, it’s not meant to be called by users and it’ll return a 401- Unauthorized error, but it’s used as a webhook endpoint between Checkout and the system. This function will be explained further in [4.4.1 Webhook].
-	`newUser` runs when a new user account is created and creates the user’s document in the ‘Users’ collection.
-	`updateUsername` is an HTTPS function called by users to update their username.
-	`updateUserPhoto` is an HTTPS function called by users to update their profile photos.
-	`banUser` is an HTTPS function callable only by an admin and it’s used to ban a user. It disables the user’s account in Firebase Authentication and adds the user’s ID number and UID in the ‘bannedList’ and ‘bannedUsers’ collections respectively. 
-	`reviewWrite` runs when a user review gets created, updated, or deleted and it updates the user’s rating. 
-	`newNotifications` runs when a new notification document is created and calls Firebase Cloud Messaging (FCM) API to send the notification to the user’s devices.
-	`adminChange` runs when a document is created, updated, or deleted in the ‘admins’ collection. When a document is created it takes the document ID (which is a UID) and sets the user with this UID as an admin. And the opposite if the document is deleted, where this function will unassign the user from the admin role.
