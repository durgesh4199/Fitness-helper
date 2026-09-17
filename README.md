# Fitness Tracker

A Flutter app for tracking diet, workouts, and everyday health — built around
an Indian/regional food catalog and a nutrition-science layer that goes a
step past calorie counting: it estimates how *favorable* a logged meal's
context is for nutrient absorption, not just how much of a nutrient it
contains.

## What it does

**Diet tracking**
- Log food against a built-in catalog of ~2,000 items (curated Indian
  staples plus a large regional/Maharashtrian food list), or add your own
  custom foods and import/export them as CSV.
- Daily calorie, macro, sugar, and micronutrient (iron, calcium, magnesium,
  potassium, zinc, vitamin C) tracking against personalized targets.
- A categorical **Meal Impact Estimate** for diabetic users instead of a
  fabricated glucose number.
- Meal Quality Score — a plain checklist (protein, fiber, sugar, portion
  size, veg/fruit) per meal, not a pass/fail judgment.
- Meal-combination and single-food recommendations to help close the day's
  remaining nutrient gaps.
- Portion-size presets (small/medium/large) scaled off the catalog serving.

**Nutrient Bioavailability Engine**
- Estimates how favorable a meal's *context* looks for Iron, Zinc, Calcium,
  Protein quality, and Vitamins A/D/E/K — e.g. vitamin C alongside iron-rich
  food is an enhancer, tea/coffee and phytate-rich foods are inhibitors,
  sprouted legumes reduce the phytate penalty, dietary fat helps fat-soluble
  vitamin absorption.
- Deliberately never claims to measure actual absorption — every estimate is
  a category (Low/Moderate/High), each with an "About this estimate" note
  and an evidence-confidence label explaining how much is actually known.
- Only backed by well-established, category-level nutrition facts (e.g.
  heme iron only exists in meat/poultry/fish); nothing is fabricated per
  food — an unassessed food stays unassessed rather than being guessed at.
- Each meal gets a consolidated "Improve this meal" tip, plus a whole-day
  bioavailability summary on the Diet screen.

**Workouts**
- Log workouts with sets/reps/weight, RPE, and training load.
- Progressive-overload detection and rest-day/recovery guidance.
- Workout history, streaks, and weekly summaries.

**Body & wellness**
- Weight and body-measurement history with trend charts.
- Water intake tracking with a weekly average.
- A Daily Wellness Score and an auto-derived daily habit checklist.
- Step/sleep/heart-rate sync via Health Connect (Android), with a
  personalized walking-step goal.
- Pattern/correlation insights (e.g. sleep vs. steps) surfaced automatically
  once there's enough data.

**Account & data**
- Email/password and Google sign-in (Firebase Auth).
- Cloud backup and restore to Firestore, so your data follows your account
  across devices.
- A doctor-friendly PDF health summary export — profile, weight, activity,
  nutrition averages, and today's bioavailability context — clearly labeled
  as self-reported/synced data, not a medical record.

## Tech stack

- **Flutter / Dart** — cross-platform UI (targets Android; also builds for
  iOS/Windows/web)
- **Provider** — app state management
- **sqflite** — local on-device database (all diet/workout/health logs)
- **Firebase** — `firebase_auth` + `google_sign_in` for sign-in,
  `cloud_firestore` for cloud backup
- **health** — Health Connect integration (steps, sleep, heart rate)
- **fl_chart** / **percent_indicator** — charts and progress rings
- **pdf** / **share_plus** — the health-summary PDF export and sharing
- **csv** / **file_picker** — food catalog import/export
- **flutter_local_notifications** + **timezone** — movement/break reminders
- **google_fonts** — typography

## Project structure

```
lib/
  models/       Data models + pure logic (nutrition targets, meal quality,
                bioavailability analyzers, recommendation engines, etc.)
  providers/    Provider-based app state (nutrition, workouts, health, auth, ...)
  services/     Database, cloud backup, and PDF report services
  screens/      App screens (Home, Diet, Workouts, Progress, Profile, Auth, ...)
  widgets/      Reusable UI (bioavailability cards, expandable text, etc.)
  theme/        App color palette and light/dark theming
test/           Unit + widget tests (mirrors lib/ structure)
docs/           Setup guides (see FIREBASE_SETUP.md)
```

## Getting started

```bash
flutter pub get
flutter run
```

To build a release APK:

```bash
flutter build apk --release
```

Sign-in and cloud backup require Firebase configuration — see
[`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md). Without it, the app
still works fully for local diet/workout tracking; only sign-in and cloud
backup are unavailable (and the app logs why, rather than failing silently).

## Testing

```bash
flutter analyze
flutter test -j 1
```

(`-j 1` avoids concurrent access to the same local sqflite test database.)
