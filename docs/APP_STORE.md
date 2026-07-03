# iOS App Store

Bundle id: **com.alnlabs.pulimeka**. Version: `pubspec.yaml`.

**First time:** register Bundle ID + App Store Connect app → `docs/CREATE_IOS_APP_ID.md`

## AdMob (iOS-specific)

1. Create iOS app + units in AdMob → `docs/ADMOB_IOS_UNITS.md`
2. Paste IDs in `lib/src/config/admob_ios_prod_config.dart`
3. Set the same App ID in `ios/Flutter/AdMob.xcconfig` (`GAD_APPLICATION_ID`)

Android ads: `docs/ADMOB_UNITS.md` + `admob_prod_config.dart`.

## Run / build

```bash
./scripts/run_ios_device.sh
./scripts/build_ios_release.sh   # produces .ipa for Transporter
```

Or: `flutter build ios --release` then Xcode **Archive** (run flutter build first for dSYMs).

**iPhone only** in App Store (portrait game). Signing: `docs/ios-device-run.md`.

Apple may still review on **iPad** (iPhone compatibility mode). Test on iPad Simulator or device before submit; hint/status messages and snack bars must not clip.

### Upload errors

| Error | Fix |
|-------|-----|
| iPad orientations | Fixed: `UIRequiresFullScreen` + iPhone-only target |
| Flutter.framework dSYM | Xcode **Archive** runs **Generate Flutter dSYM** (dsymutil). Or use `./scripts/build_ios_release.sh` (`flutter build ipa`) |

## Privacy policy URL

Deploy `alnlabs-website` then use in App Store Connect:

**https://alnlabs.com/puli-meka/privacy-policy**

Source: `alnlabs-website/app/puli-meka/privacy-policy/page.jsx`

## Optional

Set `APP_STORE_ID` in `lib/src/config/ios_store_config.dart` for Rate app / store links.
