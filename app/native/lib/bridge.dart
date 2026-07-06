// A tiny message bridge between Flutter and the WebView editor.
// - Sends requests by evaluating JS: window.onNativeMessage(msg)
// - Receives responses via the JavascriptChannel (NativeBridge) and handleJsMessage.
import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

class Bridge {
  static final Bridge _instance = Bridge._internal();
  factory Bridge() => _instance;
  Bridge._internal();

  WebViewController? _controller;
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};

  void setController(WebViewController controller) {
    _controller = controller;
  }

  // Send a request and return a Future that completes when a response with the same id arrives.
  Future<Map<String, dynamic>?> sendRequest(Map<String, dynamic> message,
      {Duration timeout = const Duration(seconds: 10)}) {
    final id = message['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    message['id'] = id;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;

    final jsonStr = jsonEncode(message);
    final js = "window.onNativeMessage && window.onNativeMessage($jsonStr);";

    if (_controller == null) {
      _pending.remove(id);
      return Future.error('WebViewController not set');
    }

    // Evaluate JS to deliver message to web editor
    _controller!.runJavascript(js).catchError((err) {
      if (!completer.isCompleted) {
        completer.completeError(err);
        _pending.remove(id);
      }
    });

    // Timeout to avoid waiting forever
    return completer.future.timeout(timeout, onTimeout: () {
      _pending.remove(id);
      throw TimeoutException('No response for message id=$id');
    }).then((m) => m);
  }

  // Called by main.dart when a message arrives from JS (NativeBridge.postMessage)
  void handleJsMessage(String raw) {
    try {
      final Map<String, dynamic> msg = jsonDecode(raw);
      final id = msg['id']?.toString();
      final type = msg['type']?.toString() ?? '';
      if (id != null && type.endsWith('.response')) {
        final completer = _pending.remove(id);
        if (completer != null && !completer.isCompleted) {
          completer.complete(msg['payload'] is Map
              ? Map<String, dynamic>.from(msg['payload'])
              : {'payload': msg['payload']});
          return;
        }
      }

      // Otherwise treat as unsolicited event -> you can handle here
      // Example: print incoming events
      print('Bridge received event: $raw');
    } catch (e) {
      print('Bridge.handleJsMessage: failed to parse message: $e');
    }
  }
}
