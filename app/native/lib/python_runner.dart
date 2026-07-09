// python_runner.dart
// Pyodide runner removed in this branch. For local Python execution you can
// implement a native integration or reintroduce a runner, but this file is
// intentionally left as a placeholder to avoid WebView-based execution.

// If you need a runner implemented, consider one of:
// - Native embedding via dart:ffi (compile CPython for platforms)
// - A lightweight remote execution API (cloud runner)
// - A reintroduced Pyodide WebView runner (previous branch: feature/flutter-python)

class PythonRunner {
  static final PythonRunner _instance = PythonRunner._internal();
  factory PythonRunner() => _instance;
  PythonRunner._internal();

  // Placeholder: runtime removed
  void init() {
    throw UnimplementedError('Python runner has been removed in this branch.');
  }

  void setController(Object controller) {
    throw UnimplementedError('Python runner has been removed in this branch.');
  }

  Future<Map<String, dynamic>> runCode(String code) async {
    throw UnimplementedError('Python runner has been removed in this branch.');
  }
}
