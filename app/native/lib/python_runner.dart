// PythonRunner: hosts a hidden WebView that loads Pyodide and executes Python code on request.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

class PythonRunner {
  static final PythonRunner _instance = PythonRunner._internal();
  factory PythonRunner() => _instance;
  PythonRunner._internal();

  WebViewController? _controller;
  bool _ready = false;
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};

  Future<void> init() async {
    // no-op: the widget will set controller when created
  }

  void setController(WebViewController controller) {
    _controller = controller;
  }

  // Called by the WebView JS channel when messages arrive
  void handleJsMessage(String raw) {
    try {
      final Map<String, dynamic> msg = jsonDecode(raw);
      final type = msg['type']?.toString() ?? '';
      final id = msg['id']?.toString();
      if (type == 'pyodide.ready') {
        _ready = true;
        return;
      }
      if (type == 'run.execute.response' && id != null) {
        final completer = _pending.remove(id);
        if (completer != null && !completer.isCompleted) {
          completer.complete(msg['payload'] ?? {});
        }
      }
    } catch (e) {
      print('PythonRunner.handleJsMessage parse error: $e');
    }
  }

  Future<Map<String, dynamic>> runCode(String code,
      {Duration timeout = const Duration(seconds: 30)}) async {
    if (_controller == null) throw 'Python runner not initialized';
    final id = 'run_${DateTime.now().millisecondsSinceEpoch}';
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    final msg = {'type': 'run.execute', 'id': id, 'payload': {'code': code}};
    final jsonStr = jsonEncode(msg);
    final js = "window.onNativeMessage && window.onNativeMessage($jsonStr);";
    await _controller!.runJavascript(js);
    return completer.future.timeout(timeout, onTimeout: () {
      _pending.remove(id);
      throw TimeoutException('Python run timed out');
    });
  }
}

// A widget that mounts the hidden WebView running the pyodide runner HTML asset.
class PythonRunnerWidget extends StatefulWidget {
  @override
  State<PythonRunnerWidget> createState() => _PythonRunnerWidgetState();
}

class _PythonRunnerWidgetState extends State<PythonRunnerWidget> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _loadRunnerHtml();
  }

  Future<void> _loadRunnerHtml() async {
    final html = await rootBundle.loadString('assets/pyodide_runner.html');
    final uri = Uri.dataFromString(html, mimeType: 'text/html', encoding: utf8).toString();
    if (_controller != null) {
      await _controller!.loadUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: 'about:blank',
      javascriptMode: JavascriptMode.unrestricted,
      javascriptChannels: {
        JavascriptChannel(
          name: 'PythonRunner',
          onMessageReceived: (msg) {
            PythonRunner().handleJsMessage(msg.message);
          },
        ),
      },
      onWebViewCreated: (controller) async {
        _controller = controller;
        PythonRunner().setController(controller);
        final html = await rootBundle.loadString('assets/pyodide_runner.html');
        final uri = Uri.dataFromString(html, mimeType: 'text/html', encoding: utf8).toString();
        await controller.loadUrl(uri);
      },
    );
  }
}
