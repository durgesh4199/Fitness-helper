# Firebase setup (sign-in + cloud backup)

This app builds and runs completely fine without any of this — Firebase is
optional. `AuthProvider.isAvailable` is false without it, the app skips the
sign-in screen entirely, and everything works exactly as before (fully
local storage). This doc is for turning on real sign-in + cloud backup.

## 1. Register the Android app in your Firebase project

In the [Firebase console](https://console.firebase.google.com/) → your
project → Project settings → Your apps → Add app → Android:

- **Package name**: `com.durgeshpatil.fitness_tracker` (must match exactly)
- Nickname/SHA-1 are optional at this step for email/password sign-in, but
  **Google Sign-In needs a SHA-1** registered (see step 4).

Download the `google-services.json` it gives you and place it at:

```
android/app/google-services.json
```

That path is gitignored by default (see `android/.gitignore`) since this
repo doesn't ship a real one. `google-services.json` isn't a secret the way
an API server key is — it ends up inside the compiled APK either way — so
committing it to your own fork/repo once you have it is fine if you want CI
to build with real config too. Just un-gitignore it (remove the
`app/google-services.json` line in `android/.gitignore`) when you do.

## 2. Enable sign-in providers

Firebase console → Authentication → Sign-in method → enable:

- **Email/Password**
- **Google**

## 3. Create a Firestore database (for cloud backup)

Firebase console → Firestore Database → Create database → **Native mode**,
any region. Then set these security rules (Firestore → Rules) so each user
can only ever read/write their own backup document:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/backup/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 4. Google Sign-In: register a SHA-1

Google Sign-In on Android requires the SHA-1 fingerprint of whatever key
signs the APK to be registered in Firebase console → Project settings →
Your apps → (the Android app) → Add fingerprint.

- **Debug builds**: run `cd android && ./gradlew signingReport` and copy the
  `SHA1` under the `debug` variant. This differs per machine, so register it
  from whichever machine(s) you'll run debug builds on.
- **Release builds**: use the release keystore described below — its SHA-1
  stays stable across every build, which is what you want for anything you
  actually ship.

## 5. Release signing (recommended alongside Google Sign-In)

Without this, release builds sign with the debug key (which changes on every
fresh CI checkout), so Google Sign-In won't work in a release APK built that
way. To fix that:

1. Copy `android/key.properties.example` to `android/key.properties` (already
   gitignored) and fill in real values.
2. Put your `.jks` keystore file at the path referenced by `storeFile` in
   that file (conventionally `android/app/your-keystore.jks` — also
   gitignored, see `android/.gitignore`).
3. Register that keystore's SHA-1 in Firebase console (step 4).

**Keep the keystore file and passwords somewhere safe and durable.** If you
ever publish a release built with this keystore (e.g. to the Play Store),
losing it means you can never publish an update under that same app
identity again — there's no recovery path.

## What's already wired up in code

- `AuthProvider` (`lib/providers/auth_provider.dart`) — email/password +
  Google sign-in/up, sign-out, password reset. Safe to construct even
  without Firebase configured (`isAvailable` reports false instead of
  throwing).
- `AuthScreen` + the `_AuthGate` in `lib/main.dart` — shown whenever
  `isAvailable` is true and no one is signed in.
- `CloudBackupService` (`lib/services/cloud_backup_service.dart`) — pushes/
  pulls the same snapshot shape as the existing local JSON backup, to
  `users/{uid}/backup/latest` in Firestore. Wired into Profile → Data as
  "Back up to cloud" / "Restore from cloud", shown only when signed in.
