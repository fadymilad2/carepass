# Refactor and review — 2026-09-21

The existing feature-based data/domain/presentation structure is retained.
Pre-existing working-tree changes were used as the starting point, without resets
or replacement from Git. Generated assets and platform projects were not reorganized.

## Structural changes

- Events and states are separate files beside each BLoC.
- Page-specific components live in widget subfolders, preserving private Dart symbols through library parts.
- Navigation chrome is separate from route definitions.
- Notification initialization and stream lifecycle management live in a core service.
- Backend exports remain stable; implementations are separated into AI, payments, maps, notifications, and health-check modules.
- Payment quotation and fulfillment logic are shared by checkout and webhook paths.
- Dart formatting and deprecated API usage were cleaned up across the application.

## Corrected behavior

- Full-screen authenticated routes are guarded; missing provider route data produces a fallback page.
- OTP and profile forms keep their state during requests and failures; unfinished registration can resume after startup.
- Sign-out failures are reported, and account sign-out clears the push token.
- Notification subscriptions are cancelled, asynchronous widget updates are guarded, and large notification batches are chunked.
- Checkout drops stale/invalid discounts, ignores late discount validation, handles empty plan lists, and avoids null assertions during verification.
- Checkout callback matching checks the URL host; system back navigation cancels checkout.
- Server payment amounts come from stored plans and discount rules, including the existing individual-to-family upgrade calculation.
- Payment fulfillment checks ownership, currency and amount, records payment history, and handles repeated verification/webhooks idempotently.
- Free activation requires a zero amount in minor currency units and atomically records redemption.
- Health checks are authorized and counted in server transactions, with monthly resets and quota enforcement.
- Expired or malformed card dates no longer produce active cards with invented expiry dates.
- AI responses cannot restore a cleared conversation; suggestion metadata and error history are retained.
- Provider searches discard stale responses and retain filters. Nearby results use device coordinates with a 10 km radius. Favorites are stored per user.
- Service provider counts count distinct providers, and late area-filter results are discarded.
- Firestore access is scoped to owners/admins; clients cannot grant subscriptions or rewrite usage counters. Public catalog browsing remains available.
- Push broadcasts require an active admin. Maps URL resolution validates destinations, including redirects.
- The malformed iOS scene configuration plist is repaired.
- A hardcoded diagnostic API key was removed, and compatible backend dependency updates eliminated the reported audit findings.

## Validation

Automated checks cover Dart source and regression tests, backend pricing/payment/URL behavior,
Firestore ownership and privilege boundaries, and concurrent health-check usage.
The emulator uses `demo-carepass`, with no production writes.

- Dart analyzer: no issues.
- Flutter regression suite: 10 tests passed, covering checkout, AI, providers, card expiry and home subscription status.
- Node backend suite: 7 tests passed.
- Firestore emulator suite: 8 tests passed, including concurrent quota enforcement.
- Backend dependency audit: zero vulnerabilities after compatible updates.
- iOS plist: parsed successfully with a dictionary-valued scene manifest.
- All 29 authored JSON, XML and plist configuration files parsed successfully.
- ARM64 Android debug build: succeeded with `gradlew.bat app:assembleDebug --offline -Ptarget-platform=android-arm64 --console=plain`.
- The multi-ABI Android build could not complete: Flutter's `armeabi_v7a_debug` engine JAR was not cached, and the online artifact download stalled. Other Flutter engine ABIs remain unverified.

Device-only flows still need a staging smoke test: real OTP delivery, iOS push permissions,
GPS permission prompts, Paystack's hosted checkout, and the production webhook.
An iOS build cannot be performed on this Windows machine.

## Rollout requirements

No application, function, or security-rule deployment was performed.

1. Rotate the API key previously embedded in `functions/test-models.js`; removal from the working tree does not revoke it or erase Git history.
2. Deploy the backend and matching Firestore rules together before releasing the updated app. Older clients that write health-check counters directly will be denied by the new rules.
3. Newly initialized payments create server-owned `payment_orders`. Complete or reconcile in-flight payments created by the previous backend before switching versions; those older references do not have order records and must not be silently accepted by the new fulfillment path.
4. Free-plan/discount redemption receipts prevent repeated activation for the same account, plan and discount. Repeated promotional redemption or renewal policy should be confirmed before production rollout.
5. Admin access uses existing active `admin_users` documents provisioned through trusted server tooling. Clients cannot create their own admin records.
6. The existing 20% charge calculation was preserved; this review did not validate tax policy.
7. Android release signing still uses the repository's existing debug configuration. Configure production signing separately before publishing.

The tests verify the listed regressions and access boundaries; they do not establish that every possible runtime or production configuration issue is eliminated.
