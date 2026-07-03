# Run on a physical iPhone

## Crash on launch: `mprotect failed: 13 (Permission denied)`

If the app dies immediately on a **real iPhone** with a Dart VM stack trace and:

```text
mprotect failed: 13 (Permission denied)
comp=no, sim=no
```

you are running **Debug (JIT)** on the device. iOS blocks that on physical hardware (especially iOS 18.4+).

**Fix — use Release on device:**

```bash
./scripts/run_ios_device.sh --release
```

**From Xcode:** scheme **Runner** (default, Release), select your iPhone, **Product → Run**.

> **Important:** Do not use **Runner-Simulator** on a real iPhone — it uses Debug/JIT and will crash with `mprotect failed`.

| Scheme | Destination | Build |
|--------|-------------|-------|
| **Runner** (default) | iPhone or Simulator | Release |
| **Runner-Simulator** | Simulator only | Debug (hot reload) |
| **Runner-Device** | iPhone/iPad | Release |

The `UIScene lifecycle will soon be required` line is only a warning — not the crash.

## Quick run

```bash
./scripts/run_ios_device.sh              # Release (default on device)
./scripts/run_ios_device.sh --debug      # Hot reload (may crash on iOS 18.4+)
./scripts/run_ios_device.sh --release
./scripts/run_ios_device.sh --help
```

**Release** is the default on a physical iPhone (recommended on iOS 18+; debug/JIT often fails on device).

App Store / AdMob / `APP_STORE_ID`: see `docs/APP_STORE.md`.

## Error: invalid code signature / profile not trusted

If you see:

```text
Unable to launch com.alnlabs.pulimeka because it has an invalid code
signature, inadequate entitlements or its profile has not been explicitly
trusted by the user
```

The Xcode **build worked**; iOS **refused to start** the app. Fix on the phone:

### 1. Delete the app on iPhone

Long-press **Puli Meka** → Remove App → Delete App.

### 2. Trust your developer certificate

**Settings → General → VPN & Device Management**  
(or **Settings → General → Device Management** on older iOS)

Under **Developer App**, tap your Apple ID / team (**GQ5YBDCV3L**) → **Trust**.

If you do not see this section, install once from Xcode (step 4) and the prompt will appear.

### 3. Enable Developer Mode (iOS 16+)

**Settings → Privacy & Security → Developer Mode** → On → restart iPhone if asked.

### 4. Install once from Xcode (most reliable)

```bash
./scripts/open_xcode.sh
```

Always open **`Runner.xcworkspace`**, never `Runner.xcodeproj`. Opening the `.xcodeproj` causes errors like `Module 'firebase_core' not found` (and similar for other plugins) because CocoaPods is not part of that build.

## Xcode build fails but `./scripts/run_ios_device.sh` works

| Symptom | Fix |
|--------|-----|
| `Module '…' not found` (firebase, ads, etc.) | Open **`ios/Runner.xcworkspace`** via `./scripts/open_xcode.sh` — not `.xcodeproj` |
| `sandbox is not in sync with Podfile.lock` | `cd ios && pod install` (or use `./scripts/open_xcode.sh`) |
| Random link / framework errors after Clean | **Product → Clean Build Folder**, then build again from the **workspace** |
| Still stuck | `flutter clean && flutter pub get && cd ios && pod install`, delete Xcode Derived Data for Runner, reopen workspace |

**Prefer the CLI for day-to-day runs** — it always syncs pods and uses Release on device:

```bash
./scripts/run_ios_device.sh --release
```

Use Xcode when you need signing UI, Organizer archive, or debugging native iOS code.

1. Select **Runner** target → **Signing & Capabilities**
2. Team: **GQ5YBDCV3L**, Bundle ID: **com.alnlabs.pulimeka**
3. Select your iPhone as the run destination
4. Scheme: **Runner** (default Release — safe on device)
5. **Product → Run** (⌘R)
5. Keep the phone **unlocked**; accept “Trust This Computer?” on the device if prompted

After that, `./scripts/run_ios_device.sh` usually works again.

### 5. Clean reinstall from Flutter

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
./scripts/run_ios_device.sh
```

## App icon on the home screen

Icons are generated from `assets/images/playstore_icon.png` (same artwork as Android) into `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.

```bash
./scripts/generate_app_icons.sh
```

Then **delete the app on the iPhone** and reinstall (`./scripts/run_ios_device.sh`). iOS often caches the old icon until a fresh install.

## Other checks

- iPhone connected by cable; tap **Trust** on the device when Mac asks
- **Window → Devices and Simulators** in Xcode shows the phone without errors
- Free Apple Developer installs expire after ~7 days — rebuild and re-trust if needed
- Bundle ID must stay **com.alnlabs.pulimeka** (matches Firebase / AdMob config)

## Simulator (no signing)

```bash
./scripts/run_ios_simulator.sh
# or
flutter run
```

Hot reload works on the simulator.

**From Xcode:** use the **iPad/iPhone Simulator** destination. For hot reload use scheme **Runner-Simulator** (Debug) or `./scripts/run_ios_simulator.sh`. The default **Runner** scheme uses Release and also works on the simulator.

**Physical iPhone/iPad:** use `./scripts/run_ios_device.sh --release` (recommended) — not the simulator.
