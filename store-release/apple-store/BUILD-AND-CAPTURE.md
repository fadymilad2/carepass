# iOS handoff

This Windows workspace cannot compile, sign or capture the iOS app. Android screenshots must not be submitted as iOS screenshots.

On a Mac with Xcode and Flutter:

1. Restore dependencies and the local Firebase options file, which is ignored by Git.
2. Open the Runner workspace and select the Apple developer team. Use bundle ID `com.fady.carepass`.
3. Verify that `Runner/GoogleService-Info.plist` is included in the Runner target resources.
4. Configure APNs for the new Firebase iOS app, enable the required push capabilities and test phone authentication and notifications on a real device.
5. Test account creation/deletion, memberships, checkout, location permissions and provider navigation.
6. Produce an archive with `flutter build ipa --release`, then validate and upload through Xcode/App Store Connect.

Capture actual iOS screens for Home, Services, Providers, Membership and Help. Use consented test data for account and card screens.

- iPhone: capture an accepted 6.9-inch size, such as 1320 × 2868 or 1290 × 2796.
- iPad: the project supports iPad; capture a supported 13-inch size such as 2064 × 2752 or 2048 × 2732.
- Supply 1–10 screenshots per required device set.
- Optional app preview: 15–30 seconds of actual iOS usage; select the resolution for the target device from Apple's table.
- App icon: use an opaque 1024 × 1024 master with no pre-rounded outer corners. The original branding export contains transparency and needs a store export.

Sources: [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) and [app preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications/).
