# Tuzday — Mobile IDE Starter

This repository now contains a starter Mobile IDE demo: a minimal Flutter native shell that embeds a small web-based editor (CodeMirror) inside a WebView.

Paths added:
- app/native/lib/main.dart
- app/native/lib/bridge.dart
- app/native/pubspec.yaml
- app/web-editor/index.html
- app/web-editor/editor.js

Quick start (local development):
1. Install Flutter SDK and set up an emulator or device.
2. From the repository root, run `flutter pub get` in `app/native`.
3. Run the app: `flutter run` from `app/native`.

Notes:
- The web-editor files are referenced as assets in pubspec.yaml. For rapid iteration you can host the web editor locally and point the WebView to that URL instead of the bundled asset.
- This is a minimal proof-of-concept. For production use, replace CodeMirror 5 with CodeMirror 6, add secure token handling, and implement full native↔web message validation.
