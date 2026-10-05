# Account deletion

## Status

Deployed to carepass-b0220 on 2026-10-05 after explicit user approval. All ten functions are ACTIVE and live Firestore rules match the scoped rules. The deletion endpoint rejects unauthenticated requests with HTTP 401 / UNAUTHENTICATED. The cleanup worker is ACTIVE with RETRY_POLICY_RETRY and the account_deletions/{uid} creation trigger. No real account was deleted; full deletion was tested using synthetic accounts in local Firebase emulators. The rebuilt signed AAB is ready to use with this backend.

## Behaviour

Account → Delete Account → confirmation. The server uses the authenticated UID, ignores supplied UIDs and requires a sign-in within five minutes. Otherwise the user is instructed to sign out and sign in again. Administrator accounts cannot use customer self-service deletion. Duplicate taps are blocked, failure allows retry, and success appears only after server confirmation followed by sign-out.

The server removes the Firebase Authentication account, `users/{uid}` recursively (including family, membership, favorites, notifications, payments and checkups), and matching `payment_orders` recursively. A private `account_deletions/{uid}` record retains only status/timestamps and the UID to block stale-session recreation and support retries. This is disclosed in the confirmation dialog. Payment-provider records, backups and operational logs are outside this deletion; no refund is issued. Reflect the scope in the eventual privacy policy.

A retrying Firestore creation trigger completes partial cleanup after transient failures. Deletion across Auth and Firestore is not atomic; a partial failure can leave the account locked while the worker retries. Payment creation/fulfillment and reminder writes check the deletion marker in transactions.

## Approved deployment completed

The live rules differ from the repository baseline. `firestore.account-deletion.rules` preserves the fetched live rules and changes only `isOwner` to reject deletion-marker UIDs. `firestore.rules` has the equivalent guard. Use the scoped configuration below; re-fetch/compare live rules before deploying if another administrator has edited them.

```powershell
npx firebase-tools deploy --project carepass-b0220 --config firebase.account-deletion.json --only 'firestore:rules,functions:deleteMyAccount,functions:finishAccountDeletion,functions:initializeExpressPayPayment,functions:verifyExpressPayPayment,functions:expressPayWebhook,functions:initializePaystackPayment,functions:verifyPaystackPayment,functions:paystackWebhook,functions:activateFreeSubscription,functions:triggerExpiryRemindersManually' --non-interactive --force
```

This adds two deletion functions and updates eight existing functions with deletion safeguards. Deployment itself deletes no account. Unauthenticated rejection and the retry trigger were verified after deployment. A full production deletion test still requires an explicitly designated disposable account before release.

## Checks completed

- 22 backend unit tests pass, including caller isolation, paginated/nested deletion, failures/retries and payment guards.
- 2 Flutter BLoC tests pass: confirmed success, duplicate suppression, retry and reuse after a new sign-in.
- 10 emulator tests pass, including real synthetic Auth/Firestore deletion and repository security rules.
- 2 scoped live-rule emulator tests pass, including normal profile/catalog access.
- Flutter analysis passes; signed Android AAB build succeeds.

Emulator command (integration tests refuse to run without emulator endpoints):

```powershell
npx firebase-tools emulators:exec --project demo-carepass --config firebase.deletion-emulators.json --only firestore,auth 'node --test functions/test/firestore.rules.test.js functions/test/account_deletion.integration.test.js functions/test/account_deletion_live_rules.test.js'
```

References: [Firebase callable functions](https://firebase.google.com/docs/functions/callable) and [Admin user deletion](https://firebase.google.com/docs/auth/admin/manage-users#delete_a_user).
