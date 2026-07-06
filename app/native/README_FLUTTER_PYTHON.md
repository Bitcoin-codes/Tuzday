Updated branch for feature/flutter-python: added Flutter-native editor and Pyodide runner (hidden WebView).

Files added:
- app/native/lib/main.dart (entrypoint -> EditorScreen)
- app/native/lib/editor_screen.dart (native CodeField editor UI, Run/Save/Open)
- app/native/lib/python_runner.dart (hidden WebView that loads pyodide_runner.html and runs code)
- app/native/assets/pyodide_runner.html (loads Pyodide from CDN and executes Python)
- app/native/pubspec.yaml (updated to include code_text_field and highlight, and pyodide asset)

Notes:
- Pyodide is loaded from the CDN in the runner HTML. For production you may want to bundle Pyodide locally which increases app size.
- The editor uses code_text_field + highlight for Python syntax highlighting.
- The Python runner returns stdout/stderr combined in the response payload. Currently runs are synchronous (captures final output) and return after execution completes.

Next steps (optional):
- Add streaming output, execution timeouts enforced by HTML, and resource limits.
- Provide UI for selecting files/projects (file browser) instead of only the sample project.
- Replace CDN Pyodide with a bundled wasm for offline use.
