# Play Console warnings (2.0.4+)

## 16 KB memory page size

Play may block updates with: **“Your app does not support 16 KB memory page sizes.”**

**Fix (in repo):**

- Android Gradle Plugin **8.5.1+** (`android/settings.gradle`)
- NDK **r28+** (`android/app/build.gradle` → `ndkVersion`)
- Rebuild: `flutter clean && ./scripts/build_android_release.sh`

**Also recommended:** upgrade Flutter to the latest stable (`flutter upgrade --force` if the SDK has local changes), then `flutter pub upgrade`.

Verify in Play Console → release → bundle details → **Memory page size** should show 16 KB support.

---

# Play Console warnings (2.0.3)

## 1. “28 devices no longer supported”

**Safe to proceed** for most apps.

Your old native APK included **x86 (32-bit)** libraries. Flutter only ships:

- `armeabi-v7a` (32-bit ARM phones)
- `arm64-v8a` (modern phones)
- `x86_64` (64-bit emulators / some tablets)

Flutter **no longer builds `x86`**, so Play drops a small set of old x86-only devices (often old tablets or rare hardware). Real phone users are almost all ARM.

In Play Console, open **Check changes to supported devices** on the release to see the list. If you are fine dropping those devices, continue the rollout.

## 2. “Upload debug symbols” (native code)

**Recommendation:** rebuild with the latest `android/app/build.gradle` (includes `ndk { debugSymbolLevel "FULL" }`), upload the new AAB, and the warning should clear on the next release.

Symbols are embedded in the App Bundle metadata. You do not need a separate file for basic native stacks.

Optional: after `./scripts/build_android_release.sh`, Java mapping is at:

`build/app/outputs/mapping/release/mapping.txt`

(Use only if Play asks for deobfuscation separately; Flutter/R8 may already attach mapping in the bundle.)
