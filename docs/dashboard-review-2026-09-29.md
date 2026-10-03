# Dashboard data review — 2026-09-29

## Scope and result

Reviewed local `D:/work/carepass_dashboard` data sources, models, overview/payment state management, filters, authentication, and notification reporting against the current CarePass payment writers in `D:/work/carepass/functions/src`.

Result: **not ready to certify dashboard figures as accurate**. This was a source review, not a signed-in browser audit or reconciliation with current production documents. No production data, rules, or dashboard source were changed. The dashboard Firebase configuration targets `carepass-b0220`.

`flutter analyze --no-pub` completed with 106 issues, including a blocking test compilation error (`test/widget_test.dart:16`, nonexistent `carepass_dashboard` class). Most other diagnostics concern deprecated APIs and lint warnings. Existing tests do not establish correctness of dashboard totals.

## Confirmed findings

1. **High — Sandbox receipts included in financial totals.** Overview datasource lines 61/113/180 and payments datasource line 105 select only `status == success`; none filter `environment`. The server explicitly writes `environment: sandbox` for sandbox receipts. Those records therefore increase revenue and appear alongside real receipts without a visible environment distinction. Separate environments; calculate production revenue from confirmed live receipts. Treat legacy records with missing environment explicitly rather than silently assuming their origin.

2. **High — Plan identifiers do not match report/filter assumptions.** The server stores the actual subscription plan document ID in `users.planName` and receipt `planId`. `overview_datasource.dart:148` queries fixed `standard/premium/annual` names, and `payments_page.dart:361` uses those fixed values for filtering. `user_model.dart:29` converts any otherwise unrecognized string longer than 20 characters to `Standard`, including UUID plan IDs. Join IDs to `subscription_plans`, retain the raw ID, and generate distribution and dropdown entries from those records. Do not silently relabel an unknown plan.

3. **High — Failure counts and success rate are not payment-attempt metrics.** `payments_datasource.dart:105-128` computes failures and success rate from the `payments` collection group. Current expressPay fulfillment writes a receipt only on success; declined/pending attempts do not create these receipts. As a result, a set of expressPay attempts can report 100% success even when some attempts failed. Use a properly authorized attempt source with terminal statuses persisted by server verification, or label this screen as successful receipts and remove misleading attempt metrics. Reading `payment_orders` alone is insufficient: current declined verification does not persist a failed order status.

4. **High — Discount usage reads a different field.** `discount_model.dart:30` reads `usedCount`, while both paid fulfillment and free activation increment `currentUses`. Dashboard usage totals, remaining-use labels and local validation therefore diverge from the server. Standardize on `currentUses` and reconcile legacy data without resetting counters. `usedByUserIds` is also not maintained by the current fulfillment path, so the dashboard's per-user validation is not evidence of server-side single-use enforcement.

5. **Medium — Active membership ignores expiry.** `overview_datasource.dart:37` and `UserEntity.isActive` inspect the status string only. An `active` record with a past `cardExpiryDate` remains counted until another operation changes its status. Current repository expiry updates are inside the manually invoked reminder function. Calculate effective membership from both status and valid future expiry, consistently across lists and statistics.

6. **Medium — Payment history, search and exports silently truncate.** `payments_datasource.dart:82` returns only `docs.take(100)` without pagination. Search at line 143 calls that method, so older matching receipts cannot be found. Export uses the loaded/filtered rows, while summary totals use all receipts. Add pagination with an explicit export-all path and communicate the displayed range.

7. **Medium — Date filters exclude the selected final day.** `payments_page.dart` passes date-picker `range.end` at midnight; `payments_datasource.dart:68` requires timestamps before that instant. Selecting the same start/end date returns no results, and a multi-day selection omits the final day. Use an inclusive start and exclusive start of the following day; use a defined reporting timezone. Several monthly aggregations also exclude exact month-start timestamps through strict `isAfter`.

8. **Medium — Search disregards selected filters.** `payments_bloc.dart:175` calls `_search(e.query)`, which reloads unfiltered payments. Results can contain a different plan, status or date while the selected filters remain visible. Apply query and filters to one coherent result set, and prevent stale async searches from overwriting newer selections.

9. **Medium — Read errors can look like empty data.** `get_overview.dart:28-30` converts chart/distribution/recent-transaction failures to empty arrays; only stats failure is surfaced. Permissions or query failures can thus look like genuinely absent records. Display a per-section error and retry rather than substituting empty results.

10. **High — Admin session restoration is permissive.** `auth_datasource.dart:101` fabricates a super-admin model when the admin record is missing. At line 107 it restores existing records without rejecting inactive admins. The sign-in path also attempts client-side auto-provisioning. Reject missing/inactive admin records and keep provisioning in an authorized administrative workflow. This is a confirmed client/session flaw; it is **not** proof of production database privilege escalation, which depends on deployed security rules. Production rules were not re-audited in this review.

11. **Medium — Notification delivery reporting overstates success.** `notifications_datasource.dart:186-188` records `isSent: true` and recipient count after caught push failures. Broadcast handling does not inspect the function's `{sent: 0, error: ...}` result. Recipient count is not confirmed delivery. Separate in-app record creation, push acceptance, and failure/unknown delivery; propagate failures accurately. No notifications were sent during review.

## Other compatibility observations

- Provider/service/plan model field names largely align with their mobile counterparts and the pricing backend; this is schema-level evidence, not a live end-to-end pass.
- Reads that order by `createdAt` exclude documents lacking that field. Several models assume string dates and do not accept Firestore Timestamp values. Assess existing data before normalizing or migrating.
- Revenue labels assume GHS even though receipts carry a currency field. Enforce single-currency reporting or separate totals if other currencies are permitted.
- The overview retrieves the entire payment collection group independently for several sections. This duplicates reads and will become costly as history grows; use a shared snapshot or server aggregates after correctness is fixed.

## Verification needed after correction

Test sandbox versus live receipts, real plan UUIDs, expired-but-active profiles, discount counters, more than 100 receipts, same-day/end-day filters, combined search and filters, missing/inactive admin records, partial read errors, and failed push responses. Then reconcile read-only aggregates against production records and verify the deployed UI with an authorized admin session. Do not certify all dashboard data from analyzer success alone.
