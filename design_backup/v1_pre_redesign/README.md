# Design backup: v1 (pre-redesign)

Snapshot of the **current** UI layout, theme, screens, widgets, help copy, and visual assets **before** the next layout/design pass.

**Created:** 2026-05-23

## What is included

| Path | Contents |
|------|----------|
| `lib/src/theme/` | Colors, typography, spacing (`app_theme.dart`) |
| `lib/src/widgets/` | Board, game view, home buttons, ads, dialogs, help sections |
| `lib/src/screens/` | Home, game, AI, online, settings, about, how-to-play, history |
| `lib/src/content/` | Hint help text |
| `lib/src/app.dart` | Routes / app shell |
| `assets/images/` | Tiger/goat icons, logo |
| `assets/fonts/` | Poppins family |
| `pubspec.yaml` | Asset & font registration (copy for reference) |

## What is *not* included (logic unchanged in redesign)

- `lib/src/controllers/`, `lib/src/models/`, `lib/src/services/` — game rules, AI, Firebase, hints logic, ads SDK wiring
- `lib/main.dart`, `firebase_options.dart`
- `assets/sounds/`
- Platform folders (`android/`, `ios/`)

## Restore this design

From the project root:

```bash
./design_backup/v1_pre_redesign/restore.sh
```

Or manually:

```bash
B=design_backup/v1_pre_redesign
cp -R "$B/lib/src/theme" lib/src/
cp -R "$B/lib/src/widgets" lib/src/
cp -R "$B/lib/src/screens" lib/src/
cp -R "$B/lib/src/content" lib/src/
cp "$B/lib/src/app.dart" lib/src/
cp -R "$B/assets/images" assets/
cp -R "$B/assets/fonts" assets/
```

Then run `flutter pub get` if you changed `pubspec.yaml`.

## New design work

Edit the live files under `lib/src/` and `assets/`. Keep this folder read-only as reference until v1 is no longer needed.
