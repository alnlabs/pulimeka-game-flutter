# Release signing (local only)

Place your Play Store upload keystore here:

- `puli-meka-release.jks` (not committed — see `.gitignore`)

Configure passwords in `android/keystore.properties` (also not committed).

One-time setup if you only have the keystore elsewhere:

```bash
cp /path/to/puli-meka-release.jks android/keystore/
cp android/keystore.properties.example android/keystore.properties
# edit keystore.properties with your passwords
```
