# Release validation

- Android release bundle built successfully with Flutter.
- Flutter analysis: no issues found.
- AAB signature verified by jarsigner; signing certificate subject is `CN=Fady, OU=CarePass, O=CarePass`.
- Android upload certificate SHA-1: `DE:57:43:1B:85:32:68:E6:35:26:93:68:CA:01:C4:73:F1:34:0D:84`.
- Android upload certificate SHA-256: `CA:E0:A7:4A:34:FB:3B:B0:82:C6:B6:1B:01:F4:55:1F:41:14:13:3C:08:82:D1:70:00:1A:46:27:0C:59:F2:DF`.
- Both upload-certificate hashes registered with the new Firebase Android app.
- AAB SHA-256: `3A172934CFBFC9C87911C834CC4AAF95C0F2A917AE5B9A568ABF5C76467F06FE`.
- Feature graphic verified as 1024 × 500 RGB PNG.
- Matching release APK installed and launched successfully on the Android emulator. Verified package ID `com.fady.carepass`, version `1.0.0`, build `1`, minimum SDK `24`, target SDK `36`.
- Public home, services, providers and provider-details screens opened and were captured. Authenticated account/help access was not tested.
- Four JPEG screenshots verified as 1080 × 1920 RGB.
- Recording decoded successfully: H.264, 1080 × 1920, 30 fps, 24.33 seconds, no audio. Exported from actual emulator screen recording; navigation transitions are abrupt on this emulator.
- iOS Firebase plist bundle ID verified as `com.fady.carepass`; iOS compilation is unverified on Windows.

The standard Android self-signed upload certificate is not a public-CA certificate. Jarsigner also reports no timestamp and ZIP entry-order warnings; it returns `jar verified`. Play Console upload validation has not been performed.

New Firebase registrations:

- Android: `1:375138173967:android:8ece45a3a7e4d57c524f7a`
- iOS: `1:375138173967:ios:e28a9e55783b0c19524f7a`

Existing web/macOS Firebase registrations remain in place. The ignored local `lib/firebase_options.dart` was updated for Android and iOS; preserve it when moving this workspace.

An analyzer pass and successful build do not verify purchases, authentication, account deletion, membership activation or store approval. See the release checklist before submission.
