# expressPay sandbox integration

The Flutter checkout now calls `initializeExpressPayPayment` and
`verifyExpressPayPayment`. The server creates a quoted order, submits it to
expressPay, stores the returned token privately, and opens hosted checkout.
Only a server-to-server Query response matching the order, token, amount and
currency can activate a subscription. Pending payments can be checked again;
webhooks also complete payments after the app is closed.

Reference: https://expresspaygh.com/developers/docs/accept-payments/merchant-api

The customer account identifier (`accountnumber`) is the Firebase UID, also used
as `username`. The official PHP SDK requires an account identifier and shows a
value longer than the Merchant API page's stated three-character maximum:
https://github.com/expresspaygh/expresspay-php-sdk . Confirm acceptance in sandbox;
if the account has different field constraints, clarify them with expressPay.

## Enter credentials locally

Do not put the Merchant ID or API key in Dart, Git, chat, or command arguments.
Run these commands in your own terminal from the project directory. Paste each
sandbox value only into the interactive secret prompt:

```powershell
npx -y firebase-tools@latest functions:secrets:set EXPRESSPAY_MERCHANT_ID --project carepass-b0220
npx -y firebase-tools@latest functions:secrets:set EXPRESSPAY_API_KEY --project carepass-b0220
```

If the global `npx` installation is broken on this Windows machine, use
`& 'C:/Program Files/nodejs/npx.cmd'` in place of `npx`.

Create the ignored file `functions/.env.carepass-b0220` with:

```dotenv
EXPRESSPAY_ENVIRONMENT=sandbox
EXPRESSPAY_SANDBOX_UIDS=FIREBASE_UID_OF_YOUR_TEST_ACCOUNT
```

Use the Firebase Authentication UID, not the phone number or email. Multiple
test UIDs can be comma-separated. Empty configuration denies sandbox checkout.
Use disposable test accounts: a successful sandbox payment activates the test
account's subscription in this project's database. Payment receipts are marked
`provider: expresspay`, `environment: sandbox`. Existing pricing, including the
20% addition, is preserved; that addition is not inferred from expressPay fees.

## Deploy when credentials and test account are ready

No deployment is performed by editing the source. Deploy only these endpoints
for the first sandbox test:

```powershell
npx -y firebase-tools@latest deploy --project carepass-b0220 --only functions:initializeExpressPayPayment,functions:verifyExpressPayPayment,functions:expressPayWebhook,functions:expressPayCallback
```

The code sends these HTTPS endpoints automatically to expressPay:

- Return URL: `https://us-central1-carepass-b0220.cloudfunctions.net/expressPayCallback`
- Notification URL: `https://us-central1-carepass-b0220.cloudfunctions.net/expressPayWebhook`

Notifications are not trusted as proof of payment: the server queries expressPay
using the saved token. If expressPay returns Invalid IP during setup, ask their
support about IP allowlisting for this sandbox account before configuring fixed
outbound networking. Do not assume the Blupay requirements apply to expressPay.

The existing Paystack server endpoints remain available for older app versions
and in-flight Paystack orders. The updated app uses expressPay only. Retire the
legacy endpoints separately after reconciling old payments and upgrading clients.
Free subscriptions continue to use the existing `activateFreeSubscription` endpoint.

## Test on a device

1. Sign in with an allowed test UID and a profile containing a name, phone and
   valid email. Use the updated app against the matching deployed Firebase project.
2. Choose a paid plan and confirm hosted expressPay sandbox checkout opens.
3. Use the test cards supplied by expressPay, or wallet `233541111111` for success
   and `233542222222` for failure. Enter test card details only on hosted checkout.
4. Confirm success activates once and creates one receipt with the correct amount.
5. Confirm declined payment does not activate the subscription.
6. For a pending wallet payment, check again from the pending screen, or return to
   the same checkout to finish paying without creating a new order. Closing the
   checkout must still check the order; a notification can activate it later even
   when the app is closed. Reopening the app should reflect the active subscription.
7. Repeat a notification/check: expiry and discount use must not increase again.
8. Test no network during verification, a cancelled checkout, and a free plan.

## Before live rollout

Get live credentials from expressPay and complete their account activation and
network requirements. Reconcile sandbox pending orders before switching secrets
and `EXPRESSPAY_ENVIRONMENT` to `live`; do not mix sandbox tokens with live keys.
Redeploy functions after secret changes. Complete a live smoke test before
releasing the app. Sandbox tests alone do not verify real charges or settlement.

## Local automated validation

```powershell
node --test functions/test/payment.test.js functions/test/expresspay.test.js
flutter analyze --no-pub
flutter test --no-pub test/features/payment
```

Local tests mock provider responses; they do not send requests with merchant
credentials. End-to-end sandbox checkout requires the real credentials and
publicly reachable deployed callback endpoints.
