// Flutter minimal app that loads the web-editor asset into a WebView
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile IDE - Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: EditorWebView(),
    );
  }
}

class EditorWebView extends StatefulWidget {
  @override
  State<EditorWebView> createState() => _EditorWebViewState();
}

class _EditorWebViewState extends State<EditorWebView> {
  WebViewController? _controller;
  String? _initialUrlData;

  @override
  void initState() {
    super.initState();
    _loadEditorHtml();
  }

  Future<void> _loadEditorHtml() async {
    // Load the bundled web-editor/index.html from assets
    // Make sure you add the file to pubspec.yaml under assets:
    // assets:
    //   - assets/web-editor/index.html
    final html = await rootBundle.loadString('assets/web-editor/index.html');
    final uri = Uri.dataFromString(
      html,
      mimeType: 'text/html',
      encoding: utf8,
    ).toString();
    setState(() {
      _initialUrlData = uri;
    });
  }

  void _onWebViewCreated(WebViewController controller) {
    _controller = controller;
    Bridge().setController(controller);
  }

  // A convenience to ask the web editor to save current buffer (demo)
  Future<void> _sendSave() async {
    final msg = {
      'type': 'file.save',
      'id': '${DateTime.now().millisecondsSinceEpoch}',
      'payload': {
        'path': 'projects/demo/sample.txt',
        'content': 'Hello from Flutter save at ${DateTime.now()}',
        'encoding': 'utf8'
      }
    };
    try {
      final res = await Bridge().sendRequest(msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save response: ${res ?? 'no payload'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a placeholder while HTML is loading
    if (_initialUrlData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Mobile IDE - Demo')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Mobile IDE - Demo')),
      body: WebView(
        initialUrl: _initialUrlData,
        javascriptMode: JavascriptMode.unrestricted,
        javascriptChannels: {
          JavascriptChannel(
            name: 'NativeBridge',
            onMessageReceived: (msg) {
              // msg.message is a String sent from JS
              Bridge().handleJsMessage(msg.message);
            },
          ),
        },
        onWebViewCreated: _onWebViewCreated,
        onPageFinished: (url) {
          // Example: request the editor to open a sample file once page is ready
          final openMsg = {
            'type': 'file.open',
            'id': 'open_${DateTime.now().millisecondsSinceEpoch}',
            'payload': {'path': 'projects/demo/sample.txt'}
          };
          Bridge().sendRequest(openMsg).catchError((e) {
            // ignore for demo
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendSave,
        tooltip: 'Save (demo)',
        child: Icon(Icons.save),
      ),
    );
  }
}
