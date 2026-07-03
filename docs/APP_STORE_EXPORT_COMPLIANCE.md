# Export compliance (Missing Compliance)

App Store Connect shows **Missing Compliance** until you answer the encryption questionnaire for each build (unless declared in the app).

## Fix the build you already uploaded (no new IPA)

1. [App Store Connect](https://appstoreconnect.apple.com) → **Apps** → **Puli Meka**
2. **TestFlight** tab (or **App Store** → your version → build row)
3. Find build **10** (or latest) with yellow **Missing Compliance**
4. Click **Manage** (or the warning link)
5. Answer:

   **Does your app use encryption?**  
   → **Yes** (Firebase and AdMob use HTTPS)

   **Is your app exempt?** / **Does it qualify for exemption?**  
   → **Yes** — uses only standard encryption (HTTPS/TLS), no custom crypto

   Or choose: *“App uses encryption but is exempt under Category 5 Part 2”*

6. **Start Internal Testing** / save — status should clear to **Ready to Submit** / **Testing**

You do **not** need a new upload for this step on an existing build.

## Future uploads (already in project)

`ios/Runner/Info.plist` includes:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

That tells Apple the app only uses **exempt** encryption (standard HTTPS). New builds may skip the manual prompt.

Rebuild only if you want this key in the **next** IPA:

```bash
./scripts/build_ios_release.sh
```

## If asked for documentation

Puli Meka does **not** need annual ERN paperwork if you only use:

- HTTPS (Firebase, ads, URLs)
- Apple’s built-in security

You do **not** implement your own encryption.
