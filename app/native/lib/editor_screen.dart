// Flutter-native code editor screen (Pyodide runner removed)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/themes/monokai-sublime.dart';
import 'package:highlight/highlight_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Note: Python runner removed — this editor remains fully native Flutter.

class EditorScreen extends StatefulWidget {
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late CodeController _codeController;
  String _currentPath = 'projects/demo/sample.txt';
  String _output = '';
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    // Initialize syntax highlighting language
    var language = python;
    _codeController = CodeController(language: language, text: """# Tuzday sample\nprint('Hello from Tuzday')\n""");

    // Load sample on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openFile(_currentPath);
    });
  }

  Future<Directory> _getRootDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(dir.path, 'projects'));
    if (!(await root.exists())) await root.create(recursive: true);
    return root;
  }

  Future<File> _fileForPath(String path) async {
    final root = await _getRootDir();
    final normalized = p.normalize(path).replaceAll('\\\\', '/');
    final parts = normalized.split('/');
    if (parts.isNotEmpty && parts[0] == 'projects') parts.removeAt(0);
    final filePath = p.join(root.path, p.joinAll(parts));
    return File(filePath);
  }

  Future<void> _ensureSampleFiles() async {
    final sampleTxt = await _fileForPath('projects/demo/sample.txt');
    if (!(await sampleTxt.exists())) {
      await sampleTxt.parent.create(recursive: true);
      await sampleTxt.writeAsString("""# Sample project file\n\nprint('This is a sample project file for Tuzday Mobile IDE demo.')\n""");
    }
    final sampleHtml = await _fileForPath('projects/demo/index.html');
    if (!(await sampleHtml.exists())) {
      await sampleHtml.writeAsString('<!doctype html><html><body><h1>Tuzday Demo Project</h1></body></html>');
    }
  }

  Future<void> _openFile(String path) async {
    await _ensureSampleFiles();
    final file = await _fileForPath(path);
    if (await file.exists()) {
      final content = await file.readAsString();
      setState(() {
        _currentPath = path;
        _codeController.text = content;
      });
    } else {
      // create if missing
      await file.create(recursive: true);
      await file.writeAsString('');
      setState(() {
        _currentPath = path;
        _codeController.text = '';
      });
    }
  }

  Future<void> _saveFile() async {
    final file = await _fileForPath(_currentPath);
    if (!(await file.parent.exists())) await file.parent.create(recursive: true);
    await file.writeAsString(_codeController.text);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved $_currentPath')));
  }

  Future<void> _runCode() async {
    // Pyodide/runner removed — placeholder behavior
    setState(() {
      _output = 'Python execution has been removed from this branch.\nImplement a native runner or reintroduce the Pyodide runner from feature/flutter-python.';
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tuzday — Mobile IDE'),
        actions: [
          IconButton(
            icon: Icon(Icons.folder_open),
            onPressed: () async {
              // For demo, re-open sample
              await _openFile('projects/demo/sample.txt');
            },
            tooltip: 'Open sample',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveFile,
            tooltip: 'Save',
          ),
          IconButton(
            icon: _isRunning ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.play_arrow),
            onPressed: _runCode,
            tooltip: 'Run Python (removed)',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CodeField(
                controller: _codeController,
                textStyle: TextStyle(fontFamily: 'SourceCodePro', fontSize: 14),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black87,
              width: double.infinity,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(8),
                child: Text(
                  _output,
                  style: TextStyle(color: Colors.white, fontFamily: 'SourceCodePro'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
