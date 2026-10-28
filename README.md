# AutoSched AI

A Flutter mobile app for student schedules, tasks, and AI-assisted planning.

## Features

- Firebase authentication and Cloud Firestore storage
- AI assistant powered by Groq
- Schedule extraction with text recognition and barcode scanning
- Local reminders and notifications
- Profile photo uploads through Cloudinary

## Run locally

1. Install Flutter with Dart compatible with `^3.10.7`.
2. Run `flutter pub get`.
3. Configure Firebase for your own project if needed. The included Firebase configuration identifies the current project; access is controlled by its Firebase rules.
4. Connect an Android or iOS device, then run:

```sh
flutter run --dart-define=GROQ_API_KEY=your_key
```

The AI assistant requires a Groq API key. Optional Cloudinary overrides can be supplied with `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_UPLOAD_PRESET`, and `CLOUDINARY_PROFILE_FOLDER` dart-defines.

For production, keep AI API keys on a backend rather than embedding them in the mobile app.

## Checks

```sh
flutter analyze
flutter test
```
