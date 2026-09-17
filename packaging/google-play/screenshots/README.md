# Play Console screenshots

Android captures uploaded to the **Intonation Trainer 2 (Chinese)** store listing.
Do not use the desktop images in `docs/screenshots/`.

Light theme, English UI, portrait. Each folder has the same six screens.
Filenames are `N_screen_name.png` and match the phone listing order.

| # | Screen | Phone `1080×2400` | 7-inch `1200×1920` | 10-inch `1600×2560` |
|---|---|---|---|---|
| 1 | Home (Start Training, progress) | `phone/1_home.png` | `tablet7/1_home.png` | `tablet10/1_home.png` |
| 2 | Reference sample categories | `phone/2_categories.png` | `tablet7/2_categories.png` | `tablet10/2_categories.png` |
| 3 | One-tone phrase list | `phone/3_phrase_list.png` | `tablet7/3_phrase_list.png` | `tablet10/3_phrase_list.png` |
| 4 | Training, reference contour | `phone/4_training.png` | `tablet7/4_training.png` | `tablet10/4_training.png` |
| 5 | Training result (score + overlay) | `phone/5_training_result.png` | `tablet7/5_training_result.png` | `tablet10/5_training_result.png` |
| 6 | Settings | `phone/6_settings.png` | `tablet7/6_settings.png` | `tablet10/6_settings.png` |

Recapture with:

```bash
./scripts/run_emulator.sh --screenshot home
./scripts/run_emulator.sh --screenshot categories
./scripts/run_emulator.sh --screenshot phrase_list
./scripts/run_emulator.sh --screenshot training
./scripts/run_emulator.sh --screenshot training_result
./scripts/run_emulator.sh --screenshot settings
./scripts/run_emulator.sh --tablet 7
./scripts/run_emulator.sh --tablet 10
```

Known `--screenshot` names write the numbered files above. New files go into
`phone/`, `tablet7/`, or `tablet10/` next to these.
