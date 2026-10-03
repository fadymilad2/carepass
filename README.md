# CarePass

Flutter healthcare membership app using Firebase, Paystack, notifications, and a health assistant.

## Structure

- `lib/core`: routing, theme, dependency registration, notifications, and utilities.
- `lib/features/<feature>/data`: remote data sources, models, and repositories.
- `lib/features/<feature>/domain`: entities, repository contracts, and use cases.
- `lib/features/<feature>/presentation/bloc`: separate BLoC, event, and state files.
- `lib/features/<feature>/presentation/pages`: page entry points.
- `lib/features/<feature>/presentation/widgets`: shared and page-specific components.
- `functions/src`: backend modules grouped by responsibility.
- `test/features` and `functions/test`: regression tests.

Page-private widget files and BLoC event/state files use Dart `part` directives. Import the page or BLoC entry point, not its parts. Shared widgets retain normal imports.

## Development

Use Flutter compatible with `pubspec.yaml`, Node.js 22, and Java 21 or newer for the Firestore emulator. Configure FlutterFire for your project; `lib/firebase_options.dart` is intentionally ignored. Run `flutter pub get` and `npm ci --prefix functions`.

Phone authentication uses normal app verification. For configured Firebase test phone numbers only, opt in with `--dart-define=FIREBASE_TEST_PHONE_AUTH=true` in a debug build.

## Verification

```sh
flutter analyze
flutter test
npm test --prefix functions
npx -y firebase-tools@latest emulators:exec --only firestore --project demo-carepass --config firebase.test.json "node --test functions/test/firestore.rules.test.js"
flutter build apk --debug
```

Emulator tests use a demo project and must never be pointed at production.

## Backend configuration

Functions require `PAYSTACK_SECRET_KEY`, `GEMINI_API_KEY`, and `GOOGLE_MAPS_API_KEY` secrets. The model diagnostic reads `GEMINI_API_KEY` from the environment. Never put secret values in source files.

See [the review and rollout notes](docs/refactor-review.md).
