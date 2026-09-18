# Quick User Guide

## What is the app for?

IntonTrainer 2-Ch is a program for practicing Chinese tones using reference audio recordings. The user listens to a sample, records their own phrase, and compares their intonation with the reference using a graph and similarity percentage. The desktop build is on [intontrainer.by](https://intontrainer.by/#download-inton2-ch). The Android edition is on [Google Play](https://play.google.com/store/apps/details?id=by.intoncore.intontrainer2.zh).

## Brief: How to use (typical scenario)

1. Open the app and go to the main screen.
2. Go to "Sample Categories" and select the desired folder.
3. Open "Sample Files" and select the desired wav file.
4. Tap to listen to the reference phrase.
5. Say the same phrase into the microphone (in the selected training mode).
6. View the similarity percentage and graphs; repeat the attempt several times if necessary.

The main screen is used to start training and review overall progress. The training screen is used to listen to the sample, record, and analyze one attempt. The recordings screen is used to view and compare saved attempts.

## Which screens do you really need?

- Main screen - Start training and overall metrics (average accuracy, files mastered, progress). Use it to see your overall results and start new sessions.
- Sample categories -> Sample files - select the desired phrase group and specific pattern for training.
- Training screen - the main work area: listen to the sample, record yourself, see the similarity percentage and pitch graphs.
- Recordings screen - store and view past attempts to compare your progress.

Advanced analysis and detailed graphs are only useful once you're practicing regularly and want to understand where exactly your pitch is slipping.

## Training modes - which to choose

You have three modes available, but for a quick guide, this is sufficient:

- Automatic mode

The app automatically starts recording when you speak and automatically stops when you're quiet. Convenient for quick, uninterrupted practice once you've mastered how the training works. 

- Guided Mode

First, the sample is played, followed by a short pause, then the app waits for your response and records it. This is the best choice for beginners and for practicing new phrases step by step.

- Manual Mode

You start and stop recording manually. This is mainly useful in noisy environments or if you want full manual control.

If the user is unsure which mode to choose, the default recommended mode is Guided or Automatic, depending on how comfortable they are speaking immediately after the sample.

## What the indicators mean

- On the training screen, you see the percentage of similarity with the sample; the closer to 100%, the better your intonation matches.
- The trend arrow shows whether the new attempt is better or worse than the previous one.
- Results History-a quick feed of the latest percentages to see if your results are stabilizing.
- On the main screen, the average accuracy and number of files mastered show your overall progress across all samples.

For most users, the percentage of similarity is sufficient and they should strive to maintain a consistently high score for the same file.

## Recommended Working Style

- Practice in a quiet room and speak clearly into the microphone.
- Use a high-quality microphone — a dedicated external mic or a good built-in laptop microphone. Poor microphone quality distorts pitch tracking and makes similarity scores less reliable.
- Select a small set of phrases and repeat each one several times before moving on to the next.
- Do not change advanced analysis settings (VAD, DTW, DSP) unless you have obvious recognition issues or are debugging.
- When changing rooms or microphones, run automatic calibration to ensure the app correctly identifies speech.

## Settings that can be adjusted

For the average user, only the basic settings are useful:

- Interface language (Russian/English).
- Theme (light/dark), primary color, font size - purely visual parameters.
- Training mode (automatic/guided/manual).
- Automatic recording stop and automatic calibration - should be left on unless there is a specific reason to disable them.

_It's best to leave the default settings for VAD, thresholds, DTW, pitch parameters, and other settings._