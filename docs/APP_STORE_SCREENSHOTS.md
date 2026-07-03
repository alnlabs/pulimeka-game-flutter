# App Store screenshots

## Which slot to use

Upload to **iPhone 6.5" Display** on the version page.

| Slot | Exact size | Folder |
|------|------------|--------|
| **6.5" Display** | **1242 × 2688** | `docs/app-store-screenshots/ios-6.5-inch/` |
| 6.7" Display | 1284 × 2778 | `docs/app-store-screenshots/ios-6.7-inch/` |

**Wrong format error?** You likely used **1284×2778** in the **6.5"** slot. Use **1242×2688** instead.

## Ready-to-upload files

```
docs/app-store-screenshots/ios-6.5-inch/
```

8 PNGs at **1242×2688**, RGB (no alpha).

## Regenerate

```bash
./scripts/resize_app_store_screenshots.sh path/to/your/pngs
```

For 6.7": add `docs/app-store-screenshots/ios-6.7-inch 6.7` as third argument.

## Steps in Connect

1. **Remove** all red/error screenshots on the version page
2. Drag PNGs from `ios-6.5-inch/` into **iPhone 6.5" Display**
3. **Save**

Do not use WhatsApp-compressed images (~471×1024).

## Best quality (optional)

Xcode → **iPhone 15 Pro Max** simulator → **Cmd+S** → resize with script if needed.
