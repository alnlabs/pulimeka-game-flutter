# Play Store (Android update)

Continues listing **com.alnlabs.pulimekagame** (native app `2.0.1+4` → Flutter `2.0.3+7`).

## In the repo

| Item | Location |
|------|----------|
| Application id | `android/app/build.gradle` |
| AdMob app id | `android/app/src/main/AndroidManifest.xml` + `lib/src/config/admob_prod_config.dart` |
| Ad unit ids | `lib/src/config/admob_prod_config.dart` |
| Firebase | `android/app/google-services.json` |
| Signing keystore | `android/keystore/puli-meka-release.jks` (local, gitignored) |
| Signing config | `android/keystore.properties` (local, gitignored) |

## Build

```bash
./scripts/build_android_release.sh
```

Upload: `release/puli-meka-<version>-release.aab`

Bump `pubspec.yaml` version before each upload.

## Signing setup (one-time)

```bash
cp android/keystore.properties.example android/keystore.properties
# Copy your Play upload .jks into android/keystore/puli-meka-release.jks
# Edit keystore.properties with store/key passwords
```

See `android/keystore/README.md`.
