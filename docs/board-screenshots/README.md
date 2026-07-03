# Board screenshots (generated)

PNG exports of each gameplay phase, rendered by the Flutter board widget in a headless test (no device or emulator required).

## Generate

```bash
./scripts/capture_board_screenshots.sh
```

## Output

| Folder | Contents |
|--------|----------|
| `phases/` | One board image per game phase (opening, tiger move, capture, placement, etc.) |
| `tutorial-pages/` | Full tutorial step composites (title + board layout) |

## Phase files

| File | Phase |
|------|--------|
| `01-opening.png` | Starting position |
| `02-tiger-starts.png` | Tigers move first |
| `03-tiger-move.png` | Tiger movement |
| `04-tiger-capture.png` | Jump capture |
| `05-goat-placement.png` | Goat placement |
| `06-goat-move.png` | Goat movement |
| `07-goats-win.png` | Goats win (trapped tigers) |
| `08-tigers-win.png` | Tigers win (12 captured) |

Regenerate after changing board layout or tutorial snapshots in `lib/src/tutorial/tutorial_snapshots.dart`.

PNG files are also copied to `assets/tutorial/phases/` for the in-app Visual Tutorial.
