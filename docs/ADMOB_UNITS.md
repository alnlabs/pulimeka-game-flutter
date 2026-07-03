# AdMob units (Puli Meka)

App in AdMob: **Puli Meka**  
App ID: `ca-app-pub-5227558935673781~6530756504`

## Already configured (banner + interstitial)

| Format        | Production unit ID                         | Where |
|---------------|--------------------------------------------|--------|
| Banner        | `ca-app-pub-5227558935673781/8457225467`   | `admob_prod_config.dart`, Android `app/env/prod/BANNER_AD_UNIT_ID` |
| Interstitial  | `ca-app-pub-5227558935673781/3600199191`   | `admob_prod_config.dart`, Android `app/env/prod/INTERSTITIAL_AD_UNIT_ID` |

No code changes needed for these.

## Rewarded (hint “Watch video”)

| Format   | Production unit ID                         |
|----------|--------------------------------------------|
| Rewarded | `ca-app-pub-5227558935673781/2017436045`   |

Configured in `admob_prod_config.dart`. New units can take **up to an hour** before ads serve reliably.

### Verify on a release build

```bash
./scripts/build_android_release.sh
# install the release APK/AAB or internal test track
```

- Home → offline/AI game → use all free hints → **Get a hint** → **Watch video** should appear and load a **real** ad (not “Test Ad”).
- Until `rewardedAdUnitId` is set, release builds only show **Short ad · skip when ready** (interstitial flow).

### Optional: override without editing Dart

```bash
flutter run --release --dart-define=REWARDED_AD_UNIT_ID=ca-app-pub-5227558935673781/XXXXXXXXXX
```

### iOS

Separate iOS app and units — see **`docs/ADMOB_IOS_UNITS.md`** and `lib/src/config/admob_ios_prod_config.dart`.
