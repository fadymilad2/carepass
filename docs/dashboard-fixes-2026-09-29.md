# Dashboard corrections — 2026-09-29

Implemented in `D:/work/carepass_dashboard`. This document supersedes the unresolved-source findings in `dashboard-review-2026-09-29.md` for the local dashboard source. The hosted dashboard has **not** been deployed in this task.

## Corrected behavior

- Revenue cards, revenue chart and recent revenue receipts include only successful, explicitly `live`, GHS receipts. Sandbox, unknown-environment and other-currency records remain available in the receipt history; environments are displayed and exported. No historic receipt environments were inferred or changed.
- Payment reporting explicitly describes receipts, not all payment attempts. The unsupported attempt success-rate card was replaced with the count of confirmed live GHS receipts. Pending/failed attempt tracking requires a separate server-backed feature and is not claimed by these figures.
- Plan UUIDs resolve against `subscription_plans`. Distribution and payment filters use actual data, and unknown plans remain visibly unknown rather than becoming Standard.
- Effective membership uses subscription status and expiry. Invalid expiry is shown as unknown, expired active records are excluded from active counts, and notification audiences use the same rule. Subscription extension accepts Timestamp/string expiry and updates transactionally.
- Payment history/search/export no longer silently truncate at 100 records. Search composes with plan/status/date filters and includes email and phone separately. Date filters include the final selected day; reports use Ghana time (UTC).
- CSV now triggers a real UTF-8 browser download, escapes cells, protects against spreadsheet formula interpretation, includes environment and plan ID, and retains the table state after export.
- Discount usage reads `currentUses`, matching the payment server. New codes initialize that counter. Editing a code does not overwrite a concurrently updated usage counter. Legacy `usedCount` is not treated as authoritative; no production counter migration was performed.
- Overview section read errors propagate to a retryable error screen instead of silently becoming empty charts. Payment summary failures are surfaced as well.
- Administrator restoration requires an existing active UID-based admin record. Removed client auto-provisioning, email fallback and super-admin fallback on read failure. Session observes server-confirmed admin changes, rejects inactive/missing records, and gates protected UI while identity is being checked. This does not change deployed Firestore authorization rules.
- Notification history distinguishes push acceptance, partial failure, failure, unknown response, and no-token cases from in-app record creation. Broadcast delivery count remains unknown. Failures reach the operator and refresh history. Large in-app audiences are written in bounded batches. No real notification was sent during validation.
- Read models accept string dates and Firestore Timestamp values. Catalog/member list reads no longer discard records solely because `createdAt` or banner `order` is missing.

## Validation

- `flutter test --no-pub`: **20 tests passed**, using fake Firestore and fake callable responses. Includes mixed live/sandbox/legacy currencies, actual UUID plan mapping, expired profiles, 105 receipts and CSV, same-day boundaries, combined search/filters, counter races, missing/inactive admin restoration, partial read errors, and notification broadcast failure/unknown/acceptance plus 501 recipients.
- `flutter analyze --no-pub`: **zero errors**. 121 total diagnostics remain (3 warnings plus informational style/deprecation diagnostics); the former nonexistent widget-test constructor error was removed. Do not describe this as a lint-clean project.
- `flutter build web --release --no-pub`: succeeded; output in `D:/work/carepass_dashboard/build/web`. Existing optional WebAssembly incompatibility from `universal_html` and a Cupertino font warning were reported; the standard web build completed.

## Operational boundaries

No hosting deployment, Firestore data migration, security-rule deployment or payment-function deployment occurred. Production numbers still require read-only reconciliation in an authorized admin session after deployment. Historic receipts without an explicit environment are visibly unknown and excluded from confirmed live revenue. Do not relabel them without evidence.

The removal of the 100-row cap favors complete search/export with the existing architecture; the client still downloads the receipt history and renders the resulting rows. For large datasets, server-side reporting and pagination remain a scaling task, not a claim of this patch.

Original edited source files were backed up under `D:/work/carepass/.dart_tool/dashboard-before-fix` before modification because the dashboard folder is not a Git repository. That local backup is not version control and is not deployed.
