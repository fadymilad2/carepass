# CarePass store preparation

Prepared for application ID `com.fady.carepass`, version `1.0.0+1`.

## Contents

- `google-play/listing.md`: ready-to-edit Google Play description and release notes.
- `apple-store/listing.md`: ready-to-edit App Store description, subtitle and reviewer guidance.
- `branding/`: copies of the original CarePass logo and icon.
- `branding/carepass-icon-opaque.png`: opaque icon artwork (1254 × 1254); export at 512 × 512 for Google Play and 1024 × 1024 for Apple before upload.
- `google-play/feature-graphic.png`: 1024 × 500 RGB feature graphic; editable SVG included.
- `google-play/carepass-1.0.0-1.aab`: signed release bundle, built successfully.
- `google-play/upload-certificate.pem`: public upload certificate; this contains no private key.
- `google-play/screenshots/`: four actual release-app captures, 1080 × 1920. Use the RGB JPEG exports; original PNG captures are also included.
- `video/carepass-android-preview.mp4`: 24.33-second, 1080 × 1920, 30-fps silent recording of public Android browsing. It is not an iOS app preview.
- `apple-store/BUILD-AND-CAPTURE.md`: Mac build and real iOS capture handoff.

## Signing backup — keep private

The Android upload key is `android/upload-keystore.jks` and its passwords are in `android/key.properties`. Both are ignored by Git. Back up both securely outside this computer. They are deliberately excluded from this store-materials folder. Do not send them to reviewers or include them in a public download.

The upload certificate identifies Fady. Public developer/seller names are set by your store accounts, independently of the package name.

## Before submission

- Verify the public support mailbox and privacy page. The values in the drafts come from the app, and the privacy URL has not been verified as publicly accessible.
- Implement and test account deletion: `AccountRepositoryImpl.deleteAccount()` currently returns success without deleting anything.
- Review the provider rating display: the captured details screen shows `4.9 (0 reviews)`. Confirm the rating source and correct that inconsistency before using the captures publicly.
- Complete Google Data safety, the health-app declaration, Apple App Privacy and age-rating questionnaires against actual app/backend behaviour and installed SDKs.
- Test phone authentication with the new Firebase app registrations. Add Google Play's app-signing SHA-1/SHA-256 certificates after enrolling in Play App Signing; the upload certificate alone does not cover Play-installed builds.
- Provide reviewer access for phone-authenticated membership features. Verify payments with the payment provider's supported test procedure.
- Finish iOS signing, APNs, a Mac build and actual iPhone/iPad captures.
- Original icon exports have transparent, rounded corners. An opaque artwork variant is provided, but exact-size store icon exports remain necessary.
- Review the screenshots/video before publishing. They include emulator status icons and current catalog/promotional data; confirm that the displayed discounts and provider details are approved and current.

Google Play uses an Android App Bundle (AAB). Apple uses an iOS archive/build uploaded through Xcode or an approved upload tool; an AAB cannot be used there.

For Google Play, screenshots must show actual app use. A preview video is linked through YouTube, so a local MP4 still needs to be uploaded to your own YouTube account and its URL entered in Play Console. No store submission or video publication is performed by this package.

Source: [Google Play preview-asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151).
