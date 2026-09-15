# Play Console screenshots

Android captures uploaded to the **Intonation Trainer 2 (Chinese)** store listing.
Do not use the desktop images in `docs/screenshots/`.

Light theme, English UI, portrait. Each folder has the same six screens.
Phone capture order puts Settings before the scored training shot; both
tablet folders put the scored training shot before Settings.

| Screen | Phone `1080×2400` | 7-inch `1200×1920` | 10-inch `1600×2560` |
|---|---|---|---|
| Home (Start Training, progress) | `phone/Screenshot_1789417810.png` | `tablet7/Screenshot_1789418987.png` | `tablet10/Screenshot_1789419129.png` |
| Reference sample categories | `phone/Screenshot_1789417819.png` | `tablet7/Screenshot_1789418996.png` | `tablet10/Screenshot_1789419230.png` |
| One-tone phrase list | `phone/Screenshot_1789417826.png` | `tablet7/Screenshot_1789419000.png` | `tablet10/Screenshot_1789419233.png` |
| Training, reference contour | `phone/Screenshot_1789417934.png` | `tablet7/Screenshot_1789419004.png` | `tablet10/Screenshot_1789419237.png` |
| Training result (score + overlay) | `phone/Screenshot_1789418329.png` | `tablet7/Screenshot_1789419048.png` | `tablet10/Screenshot_1789419252.png` |
| Settings | `phone/Screenshot_1789417946.png` | `tablet7/Screenshot_1789419051.png` | `tablet10/Screenshot_1789419256.png` |

Recapture with:

```bash
./scripts/run_emulator.sh --screenshot home
./scripts/run_emulator.sh --tablet 7
./scripts/run_emulator.sh --tablet 10
```

New files go into `phone/`, `tablet7/`, or `tablet10/` next to these.
