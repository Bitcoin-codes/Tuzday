# Tuzday — Mobile IDE Starter (basic-file-io)

This branch adds basic native file I/O handlers so the web-editor can open, list, and save files in the app's documents directory.

What changed (branch: feature/basic-file-io)
- Added native request handling in `app/native/lib/bridge.dart` for:
  - file.open
  - file.save
  - file.list
  These map `projects/...` paths into the in-app documents directory and respond with the JSON message contract expected by the web editor.

- Added `path_provider` and `path` to `app/native/pubspec.yaml`.
- Added a sample project under `app/projects/demo` (sample.txt and index.html).
- The Bridge automatically creates the demo files on-demand when the editor requests them.

How to test locally
1. From the repo root, open a terminal:
   cd app/native
   flutter pub get
2. Run the app on a device/emulator:
   flutter run
3. When the web editor loads, click "Open sample.txt" to request the sample file. The native bridge will create and return the sample file if it doesn't already exist.
4. Edit the file in the editor and click "Save". The bridge will write the file into the app's documents/projects/demo/ path.

Notes & next steps
- This is intentionally minimal and suitable for local debugging and development. For production you should:
  - Add strict validation and size limits for incoming content.
  - Implement file locking or simple conflict detection (mtime/sha) to avoid overwrites.
  - Expand to support git.action, auth.request, and run.execute message handling.

If you'd like, I can now open a pull request from this branch into main, or push these changes directly to main. Which do you prefer?