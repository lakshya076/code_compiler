import 'package:flutter/material.dart';
import 'Screens/compiler.dart';

void main() {
  runApp(const CodeCompiler());
}

class CodeCompiler extends StatelessWidget {
  const CodeCompiler({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Online Compiler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D2D2D),
          elevation: 4,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.blueGrey,
          surface: Color(0xFF2D2D2D),
        ),
        useMaterial3: true,
      ),
      home: const CodeCompilerScreen(),
    );
  }
}
