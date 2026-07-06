// Flutter main app now loads the Flutter-native editor screen.
import 'package:flutter/material.dart';
import 'editor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuzday — Mobile IDE (Flutter + Python)',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EditorScreen(),
    );
  }
}
