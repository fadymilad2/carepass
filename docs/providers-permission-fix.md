# Providers permission fix — 2026-09-23

## Diagnosis

Production rules were last updated on 2026-07-04. Provider reads were public,
but `users/{uid}/favorites` had no rule. The signed-in provider loader reads
favorites after querying providers, so the denied favorites query failed the
entire list. Guests skip this query, explaining the sign-in-dependent behavior.

## Narrow deployment

`firestore.providers-hotfix.rules` copies the deployed rules with only one added
favorites match. It allows owner-only get/list/delete and validates create/update
against an existing provider, matching string ID and an exact one-field payload.
It does not add administrator or guest access to favorites.

The existing local `firestore.rules` contains a broader, un-deployed hardening
change and was deliberately not deployed as part of this fix; doing so would
change unrelated admin, profile, settings and service-category behavior.
The original deployed source and release metadata are retained in
`firestore-deployed-before-providers-fix.json` for comparison/recovery.

Use `firebase.providers-hotfix.json` for this narrow rules deployment. Before any
future default rules deployment, reconcile the local hardening version with the
production collections and administrative workflows.

## Validation

Five emulator tests reproduce the original denial, verify the app's exact
provider/favorites queries, preserve guest catalog reads, reject cross-user CRUD
and list access, and reject forged IDs, missing providers, extra fields and wrong
types. Owner favorite creation, update and deletion succeed. No production
documents are read or changed by these tests.

The rules are a scoped fix tested against these access patterns; this is not a
security certification of the inherited production rules. Review the broader
rules before expanding rollout.

```powershell
npx -y firebase-tools@latest emulators:exec --config firebase.providers-hotfix.json --project demo-providers-after --only firestore "node --test functions/test/provider_favorites.rules.test.js"
npx -y firebase-tools@latest deploy --config firebase.providers-hotfix.json --project carepass-b0220 --only firestore:rules --non-interactive
```
