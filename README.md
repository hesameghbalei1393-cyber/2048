# MergeMint 2048 — Eight⁸ Studio

A clean Flutter implementation of the 2048 number puzzle. The game is offline and uses only Flutter (no third-party Dart packages).

## Features
- Swipe to move tiles in all four directions
- Merge matching tiles and keep score
- Undo the previous move
- Start a new game
- Persian/English interface toggle
- About dialog for Eight⁸ Studio

## Build
Requires Flutter stable and Java 17. Run `flutter pub get`, then `flutter run` for testing.

For a signed release APK using GitHub Actions, configure the repository secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, and `KEY_ALIAS` with the same permanent keystore used for any previously published version. Never generate a different key for an update to an existing Myket app.
