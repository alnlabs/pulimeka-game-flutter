# AdMob — iOS app (`com.alnlabs.pulimeka`)

iOS needs its **own** AdMob app and ad units (not the Android IDs).

## 1. Add the iOS app in AdMob

1. [AdMob](https://apps.admob.com/) → **Apps** → **Add app**.
2. Platform: **iOS**.
3. Is the app listed on a supported app store? → **No** (until App Store) or **Yes** if already live.
4. App name: **Puli Meka**.
5. Bundle ID: **`com.alnlabs.pulimeka`** (must match Xcode).

Copy the **App ID** (`ca-app-pub-XXXXXXXX~YYYYYYYY`).

## 2. Create ad units (iOS app selected)

| Format        | Suggested name   | Paste into |
|---------------|------------------|------------|
| Banner        | iOS Banner       | `admob_ios_prod_config.dart` → `bannerAdUnitId` |
| Interstitial  | iOS Interstitial | `interstitialAdUnitId` |
| Rewarded      | iOS Hint reward  | `rewardedAdUnitId` |

## Configured so far

| Format | Unit ID |
|--------|---------|
| App ID | `ca-app-pub-5227558935673781~4570923137` |
| Banner | `ca-app-pub-5227558935673781/9140561834` |
| Interstitial | `ca-app-pub-5227558935673781/6715532874` |
| Rewarded | `ca-app-pub-5227558935673781/5402451204` |

All iOS prod units are in `admob_ios_prod_config.dart` and `ios/Flutter/AdMob.xcconfig`.

## 3. Paste into the project

**File:** `lib/src/config/admob_ios_prod_config.dart`

```dart
static const String applicationId = 'ca-app-pub-XXXX~YYYY';
static const String bannerAdUnitId = 'ca-app-pub-XXXX/ZZZZ';
static const String interstitialAdUnitId = 'ca-app-pub-XXXX/ZZZZ';
static const String rewardedAdUnitId = 'ca-app-pub-XXXX/ZZZZ';
```

**Also set the same iOS App ID** in:

- `ios/Flutter/Release.xcconfig` → `GAD_APPLICATION_ID=...`
- `ios/Flutter/Profile.xcconfig` → `GAD_APPLICATION_ID=...`

(Debug uses Google’s test app ID in `Debug.xcconfig` — leave as is.)

## 4. Test on device (release)

```bash
./scripts/run_ios_device.sh --release
```

Live ads on iOS release only run when `AdmobIosProdConfig.isConfigured` is true (app id + banner + interstitial set).

## Android reference (do not use on iOS)

| | Android |
|---|---------|
| App ID | `ca-app-pub-5227558935673781~6530756504` |
| Banner | `.../8457225467` |
| Interstitial | `.../3600199191` |
| Rewarded | `.../2017436045` |

See `docs/ADMOB_UNITS.md`.
