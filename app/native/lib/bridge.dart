// Bridge with native request handling for file.open, file.save, file.list
// Uses path_provider to map repo-style paths into the app's documents directory.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

      // If it's a response to a previous native->web request, complete the pending future
      if (id != null && type.endsWith('.response')) {
        final completer = _pending.remove(id);
        if (completer != null && !completer.isCompleted) {
          completer.complete(msg['payload'] is Map
              ? Map<String, dynamic>.from(msg['payload'])
              : {'payload': msg['payload']});
          return;
        }
      }

      // Otherwise treat it as an inbound request from the web editor and handle it
      if (type.startsWith('file.')) {
        _handleFileRequest(msg);
        return;
      }

      // Unhandled event
      print('Bridge received event: $raw');
    } catch (e) {
      print('Bridge.handleJsMessage: failed to parse message: $e');
    }
  }

  Future<Directory> _getRootDir() async {
    final dir = await getApplicationDocumentsDirectory();
    // We'll store projects under <app-docs>/projects
    final root = Directory(p.join(dir.path, 'projects'));
    if (!(await root.exists())) {
      await root.create(recursive: true);
    }
    return root;
  }

  // Map a repository-style path like "projects/demo/sample.txt" to a file under app documents
  Future<File> _fileForPath(String path) async {
    final root = await _getRootDir();
    // Normalize and prevent escaping the root
    final normalized = p.normalize(path).replaceAll('\\', '/');
    final parts = normalized.split('/');
    // If path begins with 'projects', remove that segment because root is already projects/
    if (parts.isNotEmpty && parts[0] == 'projects') {
      parts.removeAt(0);
    }
    final filePath = p.join(root.path, p.joinAll(parts));
    return File(filePath);
  }

  Future<void> _sendToWeb(Map<String, dynamic> message) async {
    if (_controller == null) return;
    final jsonStr = jsonEncode(message);
    final js = "window.onNativeMessage && window.onNativeMessage($jsonStr);";
    try {
      await _controller!.runJavascript(js);
    } catch (e) {
      print('Failed to send message to web: $e');
    }
  }

  Future<void> _handleFileRequest(Map<String, dynamic> msg) async {
    final type = msg['type']?.toString() ?? '';
    final id = msg['id']?.toString();
    final payload = msg['payload'] ?? {};

    if (type == 'file.open') {
      final path = payload['path']?.toString() ?? '';
      final file = await _fileForPath(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        final mtime = (await file.lastModified()).toUtc().toIso8601String();
        final response = {
          'type': 'file.open.response',
          'id': id,
          'ok': true,
          'payload': {
            'path': path,
            'content': content,
            'encoding': 'utf8',
            'mtime': mtime,
          }
        };
        await _sendToWeb(response);
      } else {
        // If the file doesn't exist but is under demo project, create a sample file on-demand
        if (path.startsWith('projects/demo')) {
          await _ensureSampleFiles();
          final file2 = await _fileForPath(path);
          if (await file2.exists()) {
            final content = await file2.readAsString();
            final mtime = (await file2.lastModified()).toUtc().toIso8601String();
            final response = {
              'type': 'file.open.response',
              'id': id,
              'ok': true,
              'payload': {
                'path': path,
                'content': content,
                'encoding': 'utf8',
                'mtime': mtime,
              }
            };
            await _sendToWeb(response);
            return;
          }
        }

        final response = {
          'type': 'file.open.response',
          'id': id,
          'ok': false,
          'error': {'code': 404, 'message': 'File not found'}
        };
        await _sendToWeb(response);
      }
    } else if (type == 'file.save') {
      final path = payload['path']?.toString() ?? '';
      final content = payload['content']?.toString() ?? '';
      final file = await _fileForPath(path);
      final parent = file.parent;
      if (!(await parent.exists())) {
        await parent.create(recursive: true);
      }
      await file.writeAsString(content);
      final mtime = (await file.lastModified()).toUtc().toIso8601String();
      final response = {
        'type': 'file.save.response',
        'id': id,
        'ok': true,
        'payload': {'path': path, 'mtime': mtime}
      };
      await _sendToWeb(response);
    } else if (type == 'file.list') {
      final path = payload['path']?.toString() ?? '';
      final recursive = payload['recursive'] == true;
      Directory dir;
      if (path.isEmpty || path == 'projects') {
        dir = await _getRootDir();
      } else {
        final file = await _fileForPath(path);
        dir = file.existsSync() && FileSystemEntity.isDirectorySync(file.path)
            ? Directory(file.path)
            : file.parent;
      }

      if (!(await dir.exists())) {
        final response = {
          'type': 'file.list.response',
          'id': id,
          'ok': true,
          'payload': {'entries': []}
        };
        await _sendToWeb(response);
        return;
      }

      final entries = <Map<String, dynamic>>[];
      await for (final entity
          in dir.list(recursive: recursive, followLinks: false)) {
        final stat = await entity.stat();
        final relPath = p.relative(entity.path, from: (await _getRootDir()).path);
        entries.add({
          'name': p.basename(entity.path),
          'path': p.join('projects', relPath),
          'type': stat.type == FileSystemEntityType.directory ? 'dir' : 'file',
          'size': stat.size,
          'mtime': stat.modified.toUtc().toIso8601String(),
        });
      }

      final response = {
        'type': 'file.list.response',
        'id': id,
        'ok': true,
        'payload': {'entries': entries}
      };
      await _sendToWeb(response);
    } else {
      // Unknown file.* request
      final response = {
        'type': '$type.response',
        'id': id,
        'ok': false,
        'error': {'code': 400, 'message': 'Unknown file request'}
      };
      await _sendToWeb(response);
    }
  }

  // Create a couple of sample files under projects/demo if they don't exist
  Future<void> _ensureSampleFiles() async {
    final sampleTxt = await _fileForPath('projects/demo/sample.txt');
    if (!(await sampleTxt.exists())) {
      await sampleTxt.parent.create(recursive: true);
      await sampleTxt.writeAsString('''// Sample project file\n// Edit this text and press Save from the editor.\n\nfunction hello() {\n  console.log('Hello from sample project');\n}\n\nhello();\n''');
    }

    final sampleHtml = await _fileForPath('projects/demo/index.html');
    if (!(await sampleHtml.exists())) {
      await sampleHtml.writeAsString('''<!doctype html>\n<html><head><meta charset=\"utf-8\"><title>Demo</title></head><body><h1>Demo Project</h1><script>console.log('Demo loaded');</script></body></html>\n''');
    }
  }
}
