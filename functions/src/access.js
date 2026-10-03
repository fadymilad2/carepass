const { HttpsError } = require('firebase-functions/v2/https');
const { getFirestore } = require('firebase-admin/firestore');

async function requireAdmin(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Must be signed in.');
  const admin = await getFirestore().collection('admin_users').doc(request.auth.uid).get();
  if (!admin.exists || admin.data().isActive !== true) {
    throw new HttpsError('permission-denied', 'Not an active admin.');
  }
}
module.exports = { requireAdmin };
