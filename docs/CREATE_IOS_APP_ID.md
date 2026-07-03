# Create iOS App ID & App Store Connect app

Your Xcode bundle id is already **`com.alnlabs.pulimeka`**. Register the same id in Apple’s portals (do not change spelling).

## Step 1 — Register Bundle ID (App ID)

1. Go to [Apple Developer → Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list).
2. Click **+** (Register an identifier).
3. Select **App IDs** → **Continue**.
4. Type: **App** → **Continue**.
5. Fill in:
   - **Description:** Puli Meka
   - **Bundle ID:** Explicit → **`com.alnlabs.pulimeka`**
6. **Capabilities:** see table below — for Puli Meka, leave **all unchecked** (default).
7. **Continue** → **Register**.

### App ID capabilities (what to enable)

| Capability | Enable? | Why |
|------------|---------|-----|
| Push Notifications | **No** | App does not use APNs |
| Sign in with Apple | **No** | No Apple login |
| iCloud / CloudKit | **No** | Uses Firebase + local storage only |
| Game Center | **No** | Not integrated |
| In-App Purchase | **No** | No IAP in app |
| Associated Domains | **No** | No universal links |
| App Groups | **No** | Not needed |
| HealthKit, Wallet, etc. | **No** | Not used |

**Internet, Firebase, and AdMob** do **not** require checking boxes on the App ID. They work with the default App ID + normal signing.

You can add capabilities later in the Developer portal and turn on matching entitlements in Xcode if you add features.

You now have an **App ID** (Bundle ID) Apple recognizes for signing and App Store.

## Step 2 — Create the app in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com/) → **Apps**.
2. Click **+** → **New App**.
3. Fill in:
   - **Platforms:** iOS
   - **Name:** Puli Meka (store name users see)
   - **Primary language:** English (or your choice)
   - **Bundle ID:** pick **`com.alnlabs.pulimeka`** from the dropdown (from Step 1)
   - **SKU:** `pulimeka-ios` (any unique string for your records)
   - **User access:** Full access (typical for solo dev)
4. **Create**.

This is your **App Store Connect app record** (not the AdMob app id).

## Step 3 — Note the App Store Apple ID (optional, after listing exists)

After the app exists (or is live), open the app in App Store Connect → **App Information** → **Apple ID** (numeric, e.g. `1234567890`).

Paste that into `lib/src/config/ios_store_config.dart`:

```dart
static const String appStoreId = '1234567890';
```

Or build with: `--dart-define=APP_STORE_ID=1234567890`

Used for “Rate app” / store links only. Not required to upload the first build.

## Step 4 — Signing in Xcode

```bash
open ios/Runner.xcworkspace
```

**Runner** → **Signing & Capabilities**:

- Team: your Apple Developer team
- Bundle Identifier: `com.alnlabs.pulimeka`
- **Automatically manage signing:** ON

Xcode will create/download provisioning profiles for that App ID.

## Already configured in this repo

| System | ID |
|--------|-----|
| Xcode bundle | `com.alnlabs.pulimeka` |
| AdMob iOS App ID | `ca-app-pub-5227558935673781~4570923137` |
| Firebase | `ios/Runner/GoogleService-Info.plist` |

AdMob and Firebase are separate from the Apple App ID (Bundle ID).

## Next

Publish flow: `docs/APP_STORE.md` and the publish steps in chat (Archive → Upload → TestFlight → Review).
