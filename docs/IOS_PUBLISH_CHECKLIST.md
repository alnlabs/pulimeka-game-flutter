# iOS App Store publish checklist (2.0.4 build 16)

## Admin role but can't upload?

**App Store Connect Admin** and **Apple Developer signing** are separate.

| Portal | What Admin can do |
|--------|-------------------|
| [App Store Connect](https://appstoreconnect.apple.com) | Manage app listing, TestFlight, users |
| [Apple Developer](https://developer.apple.com/account) | Create **Distribution** certificates & upload signing |

You need **both**:

1. Active **Apple Developer Program** membership ($99/year) on team **GQ5YBDCV3L**
2. Your Apple ID listed at **developer.apple.com → Account → People** as **Admin** or **Developer** (not App Store Connect only)
3. An **Apple Distribution** certificate in Keychain (not just Apple Development)

### Check your access

1. Sign in at [developer.apple.com/account](https://developer.apple.com/account)
2. **Membership** → status must be **Active**
3. **People** → your email must appear with role **Admin**, **Account Holder**, or **Developer**
4. **Certificates** → you should be able to click **+** and create **Apple Distribution**

If you are **only** in App Store Connect (Users and Access) but **not** on developer.apple.com People, ask the **Account Holder** to invite you there with **Admin** role.

### Create Distribution certificate

**Option A — Xcode**

1. **Xcode → Settings → Accounts**
2. Select **nageshwar521.sg@gmail.com** → your team (verify Team ID in Xcode)
3. **Manage Certificates…** → **+** → **Apple Distribution**
4. If **+** is disabled, your Developer portal role or membership is the blocker (see above)

**Option B — Web**

1. [developer.apple.com → Certificates](https://developer.apple.com/account/resources/certificates/list)
2. **+** → **Apple Distribution** → follow CSR steps → download → double-click to install

Then re-run `./scripts/build_ios_release.sh` or **Distribute App** from Organizer.

### Using `nageshwar521.sg@gmail.com` (not the old Apple ID)

Your Mac may still have certificates for **nageshwar.uideveloper@gmail.com**. Switch fully in Xcode:

1. **Xcode → Settings → Accounts**
2. Click **+** → add **nageshwar521.sg@gmail.com** (if not listed)
3. Select that account → confirm team **GQ5YBDCV3L** appears (or note the new Team ID)
4. **Manage Certificates…** → **+** → **Apple Distribution** (under the new account)
5. Optional: remove the old **nageshwar.uideveloper@gmail.com** account to avoid Xcode picking the wrong cert
6. Open `ios/Runner.xcworkspace` → **Runner** → **Signing & Capabilities** → Team = team under **nageshwar521.sg@gmail.com**

If Team ID changed, update `DEVELOPMENT_TEAM` in `ios/Runner.xcodeproj/project.pbxproj` and `ios/ExportOptions.plist` to match.

Verify in Terminal (should show the new email):

```bash
security find-identity -v -p codesigning
```

You need **Apple Distribution: nageshwar521.sg@gmail.com** before App Store upload will work.

## 1. Sign in to Apple (one-time if not done)

1. Open **Xcode → Settings → Accounts**
2. Click **+** → **Apple ID** → sign in with **nageshwar521.sg@gmail.com**
3. Select your team (confirm Team ID — may still be **GQ5YBDCV3L**)
4. Click **Manage Certificates…** → **+** → **Apple Distribution** (if missing)

## 2. Build archive (already done)

```bash
./scripts/build_ios_release.sh
```

Archive path:

`build/ios/archive/Runner.xcarchive`

If IPA export fails with *No signing certificate "iOS Distribution"*, use Xcode Organizer (step 3).

## 3. Upload from Xcode Organizer

```bash
open build/ios/archive/Runner.xcarchive
```

Or: **Xcode → Window → Organizer** → select **Runner** archive (2.0.4, 16).

1. Click **Distribute App**
2. **App Store Connect** → **Upload**
3. **Automatically manage signing**
4. Upload

Xcode can create the Distribution certificate and provisioning profile during this flow.

## 4. App Store Connect

1. [App Store Connect](https://appstoreconnect.apple.com) → **Puli Meka**
2. **Privacy Policy URL:** `https://alnlabs.com/puli-meka/privacy-policy`
3. **TestFlight** → wait for processing → add build **16**
4. **App Store** tab → version **2.0.4** → select build **16**

### What's New

```
• Better display on iPad and larger screens
• Improved AI difficulty levels
• More reliable ad loading
• Bug fixes and performance improvements
```

### Export compliance

Build includes `ITSAppUsesNonExemptEncryption = false`. If prompted in Connect, answer **No** for custom encryption.

## 5. Optional: export IPA via CLI (after Distribution cert exists)

```bash
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist
```

Upload `build/ios/ipa/*.ipa` with [Transporter](https://apps.apple.com/app/transporter/id1450874784).
