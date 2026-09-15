# Google Play store listing copy

Paste these fields into Play Console:
**Grow users → Store presence → Main store listing**, plus **Store settings**.

Limits are Play’s published maxima (name 30, short description 80, full
description 4,000, What’s new 500). Counts below include spaces.

Do not add rankings, prices, “free”/“discount”, “#1”/“best”, keyword stuffing,
emojis, or decorative symbols. Keep the default listing in English; add Russian
as a translation.

**What’s new** is written per Play upload / git tag (`MAJOR.MINOR.PATCH`).
Keep an EN+RU block for each tag. The current internal-testing release is
**1.0.0**. When a later tag is uploaded, add a new What’s new section and
paste it into the Console release notes for that AAB.

| Field | EN | RU |
|---|---:|---:|
| App name | 30 / 30 | 30 / 30 |
| Short description | 74 / 80 | 70 / 80 |
| Full description | 2,040 / 4,000 | 2,050 / 4,000 |
| What’s new (1.0.0) | 192 / 500 | 186 / 500 |

---

## Store settings (shared)

| Field | Value |
|---|---|
| Package name | `by.intoncore.intontrainer2.zh` (set when creating the Play app; cannot change later) |
| Default language | English (United States) |
| Additional language | Russian |
| App type | App |
| Category | Education |
| Tags | Language learning (add others only if Play offers them and they fit) |
| Email (required) | zhitko.vladimir@gmail.com |
| Phone | leave empty unless you want a public number |
| Website | https://intontrainer.by/ |
| Privacy policy URL | https://intontrainer.by/intontrainer2policy.html |

The privacy-policy URL is also required under **App content** and **Data safety**.
It must stay identical to the in-app / website notice.

This listing is the **Chinese** edition (`by.intoncore.intontrainer2.zh`).
Later language apps (English, Russian, German, …) should reuse the same name
pattern, for example `Intonation Trainer 2 (English)` with package
`by.intoncore.intontrainer2.en` — each as its own Play listing. Those names
also fit in 30 characters (`(German)` is 29).

---

## English (default listing)

### App name

```
Intonation Trainer 2 (Chinese)
```

30 / 30 characters. Matches the Android launcher label (`QT_ANDROID_APP_NAME` /
manifest) and the current Chinese trainer on
[intontrainer.by](https://intontrainer.by/). The earlier **IntonTrainer-Zh-CN**
listing on that site is the previous version. The in-app home title
**Inton@Trainer 2.0** is branding only; do not put `@` in the Play name.

Keep the trained language in brackets so future editions stay distinct.

### Short description

```
Practice Chinese tones with on-device pitch comparison and visual feedback
```

### Full description

```
Intonation Trainer 2 (Chinese) is a practice tool for speech melody. Listen to a native reference, record the same phrase, and see how closely your pitch contour matches.

The app includes a Chinese-tone library: single tones, two-tone and four-tone phrases, useful everyday expressions, and short conversational lines in male and female voices.

How to practice
1. Open a phrase from the library.
2. Listen to the reference.
3. Say the same phrase into the microphone.
4. Check the similarity score and the overlaid pitch graphs.
5. Repeat until the contour is stable.

Training modes
- Guided: play the model, pause briefly, then record in a timed listen window. Useful when you are learning a new phrase.
- Automatic: the app detects speech and stops when you pause. Useful for fluent, hands-free drills.
- Manual: you start and stop recording. Useful in noisy rooms.

What you can review
- A similarity score and a trend against your previous attempt
- Recent scores for the same phrase
- Your pitch contour aligned with the reference
- Saved recordings with date, score, and the phrase you practiced
- Home-screen progress: average accuracy, mastered phrases, and overall completion
- Optional advanced graphs (waveforms, spectrograms, alignment) when you want more detail

The interface is available in English and Russian. Light and dark themes are supported.

Privacy and storage
The microphone is used only to record your training attempts. WAV files, scores, and settings stay in private app storage on your device. The app does not require Internet permission and does not upload your voice, scores, or settings. You can delete one recording, all recordings, or all user data in Settings.

For reliable results, practice in a quiet room and speak clearly toward the microphone. Recalibrate if you change rooms or devices.

Support
Website: https://intontrainer.by/
Email: zhitko.vladimir@gmail.com
Privacy policy: https://intontrainer.by/intontrainer2policy.html

Open-source licences and source notices are available in the app.
```

### What’s new (version 1.0.0)

```
Initial Android release. Practice bundled Chinese-tone phrases with guided, automatic, or manual recording. Compare your pitch contour with the reference on the device and keep scores locally.
```

### Graphic alt text (optional, ≤140 characters each)

Use these if Play Console asks for alt text on listing artwork.
Phone listing order is Home → library → phrase list → reference contour →
Settings → scored overlay. Tablet folders capture the scored overlay before
Settings; see `screenshots/README.md`.

| Asset | Alt text |
|---|---|
| App icon | Intonation Trainer 2 (Chinese) mark on a light square |
| Feature graphic | Chinese tone training graphic with listening, recording, a similarity score, and overlaid pitch contours |
| Phone screenshot 1 | Home screen with Start Training and progress statistics |
| Phone screenshot 2 | Phrase library with Chinese-tone category folders |
| Phone screenshot 3 | One-tone phrase list with practice filters |
| Phone screenshot 4 | Training screen showing the reference pitch contour |
| Phone screenshot 5 | Settings for language, theme, and guided recording |
| Phone screenshot 6 | Training result with a high score and overlaid pitch contours |

---

## Russian (translation)

Add locale **Russian** under Main store listing translations. Do not replace the
default English listing.

### App name

```
Тренер интонации 2 (китайский)
```

30 / 30 characters. Localized name for Russian search. The launcher on the
device remains **Intonation Trainer 2 (Chinese)**. If you prefer a single
brand across locales, use `Intonation Trainer 2 (Chinese)` here too.

### Short description

```
Тренируйте китайские тоны, сравнивая мелодику с эталоном на устройстве
```

### Full description

```
«Тренер интонации 2 (китайский)» помогает отрабатывать речевую мелодику: вы слушаете эталон, записываете ту же фразу и видите, насколько контур вашего тона совпадает с образцом.

В приложении есть библиотека китайских тонов: отдельные тоны, двух- и четырёхтонные фразы, полезные выражения и короткие разговорные реплики мужским и женским голосом.

Как заниматься
1. Откройте фразу из библиотеки.
2. Прослушайте эталон.
3. Произнесите ту же фразу в микрофон.
4. Посмотрите процент сходства и совмещённые графики тона.
5. Повторяйте фразу, пока контур не станет устойчивым.

Режимы тренировки
- С подсказкой: сначала эталон, короткая пауза, затем запись в ограниченном окне. Удобно для новых фраз.
- Автоматический: приложение само определяет речь и останавливает запись по паузе. Удобно для непрерывных повторов.
- Ручной: вы сами начинаете и останавливаете запись. Удобно в шумной обстановке.

Что можно смотреть
- Процент сходства и сравнение с предыдущей попыткой
- Недавние результаты по той же фразе
- Ваш контур тона рядом с эталоном
- Сохранённые записи с датой, оценкой и названием фразы
- Прогресс на главном экране: средняя точность, освоенные фразы и общее выполнение
- При необходимости — расширенные графики (волна, спектрограмма, выравнивание)

Интерфейс доступен на английском и русском языках. Есть светлая и тёмная темы.

Конфиденциальность и хранение
Микрофон используется только для учебных записей. WAV-файлы, оценки и настройки остаются в закрытом хранилище приложения на устройстве. Приложению не требуется разрешение Интернет, оно не отправляет голос, оценки и настройки. В настройках можно удалить одну запись, все записи или все пользовательские данные.

Для устойчивого результата занимайтесь в тихом помещении и говорите чётко в микрофон. Повторите калибровку, если сменили комнату или устройство.

Поддержка
Сайт: https://intontrainer.by/
Почта: zhitko.vladimir@gmail.com
Политика конфиденциальности: https://intontrainer.by/intontrainer2policy.html

Лицензии открытого ПО и сведения об исходном коде доступны в приложении.
```

### What’s new (version 1.0.0)

```
Первый выпуск для Android. Тренировка китайских тонов в режимах с подсказкой, автоматическом и ручном. Сравнение контура тона с эталоном на устройстве и локальное сохранение результатов.
```

### Graphic alt text (optional, ≤140 characters each)

| Asset | Alt text |
|---|---|
| Иконка | Знак Intonation Trainer 2 (Chinese) на светлом квадрате |
| Рекламный графический файл | Тренировка китайских тонов: прослушивание, запись, процент сходства и два контура тона |
| Скриншот 1 | Главный экран с кнопкой старта тренировки и статистикой прогресса |
| Скриншот 2 | Библиотека фраз с папками категорий тонов |
| Скриншот 3 | Список однотонных фраз с фильтрами практики |
| Скриншот 4 | Экран тренировки с эталонным контуром тона |
| Скриншот 5 | Настройки языка, темы и режима записи с подсказкой |
| Скриншот 6 | Результат тренировки с высокой оценкой и наложением контуров |

---

## Listing graphics (not text)

These files live next to this document and were uploaded to the Play listing.
Keep replacements in the same folders. Index: `screenshots/README.md`.

| Asset | Spec |
|---|---|
| App icon | `icon-512-zh.png` in this folder (512×512, 32-bit PNG with alpha, ≤1024 KB). Copied from `icon-512.png`; later editions use `icon-512-en.png`, etc. |
| Feature graphic | `feature-graphic-zh.png` (1024×500, 24-bit sRGB PNG, no alpha); editable source: `feature-graphic-zh.svg` |
| Phone screenshots | 6 portrait captures in `screenshots/phone/` (`1080×2400`) |
| 7-inch tablet screenshots | 6 portrait captures in `screenshots/tablet7/` (`1200×1920`) |
| 10-inch tablet screenshots | 6 portrait captures in `screenshots/tablet10/` (`1600×2560`) |

Do not upload the desktop captures in `docs/screenshots/` to Play. The listing
shots are Android emulator captures, in portrait, light theme, English UI.

Official field limits:
[Create and set up your app](https://support.google.com/googleplay/android-developer/answer/9859152),
[Store listing assets](https://support.google.com/googleplay/android-developer/answer/9866151),
[Metadata policy](https://support.google.com/googleplay/android-developer/answer/9898842).
