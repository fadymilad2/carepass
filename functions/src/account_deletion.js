const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { requestDeletion, eraseAccount } = require('./account_deletion_service');

exports.deleteMyAccount = onCall({ timeoutSeconds: 540 }, async (request) => {
  try {
    return await requestDeletion(request, getFirestore(), getAuth());
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error('Account deletion did not complete', error.code);
    throw new HttpsError('internal', 'Deletion could not be confirmed. If accepted, cleanup will continue automatically. Please retry or contact support.');
  }
});

// Durable retries if the callable times out or a downstream service fails.
exports.finishAccountDeletion = onDocumentCreated(
  { document: 'account_deletions/{uid}', retry: true, timeoutSeconds: 540 },
  async (event) => {
    if (!event.data) return;
    await eraseAccount(getFirestore(), getAuth(), event.params.uid);
  },
);
