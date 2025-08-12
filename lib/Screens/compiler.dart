import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/rust.dart';
import 'package:highlight/languages/ruby.dart';
import 'package:highlight/languages/julia.dart';

const String backendUrl = 'https://compiler.arilak.tech/compile';

class CodeCompilerScreen extends StatefulWidget {
  const CodeCompilerScreen({super.key});

  @override
  _CodeCompilerScreenState createState() => _CodeCompilerScreenState();
}

class _CodeCompilerScreenState extends State<CodeCompilerScreen> {
  String _output = 'Your output will appear here...';
  String _selectedLanguage = 'py';
  bool _isLoading = false;

  CodeController? _codeController;

  final Map<String, String> _supportedLanguages = {
    'py': 'Python',
    'js': 'JavaScript',
    'java': 'Java',
    'c': 'C',
    'cpp': 'C++',
    'rs': 'Rust',
    'rb': 'Ruby',
    'jl': 'Julia',
  };

  final Map<String, Mode> _highlightLanguages = {
    'py': python,
    'js': javascript,
    'java': java,
    'c': cpp,
    'cpp': cpp,
    'rs': rust,
    'rb': ruby,
    'jl': julia,
  };

  final Map<String, String> _boilerplate = {
    'py': '# Start typing your Python code here\n',
    'js': '// Start typing your JavaScript code here\n',
    'java': '''
public class Main {
    public static void main(String[] args) {
        //CURSOR//
    }
}
''',
    'c': '''
#include <stdio.h>

int main() {
    //CURSOR//
    return 0;
}
''',
    'cpp': '''
#include <iostream>

int main() {
    //CURSOR//
    return 0;
}
''',
    'rs': '''
fn main() {
    //CURSOR//
}
''',
    'rb': '# Start typing your Ruby code here\n',
    'jl': '# Start typing your Julia code here\n',
  };

  @override
  void initState() {
    super.initState();
    _setBoilerplateCode(_selectedLanguage);
  }

  void _setBoilerplateCode(String langKey) {
    String template = _boilerplate[langKey] ?? '';
    int cursorPosition = template.indexOf('//CURSOR//');
    if (cursorPosition != -1) {
      template = template.replaceAll('//CURSOR//', '');
    } else {
      cursorPosition = template.length;
    }

    _codeController?.dispose();
    _codeController = CodeController(
      text: template,
      language: _highlightLanguages[langKey],
    );

    Future.delayed(const Duration(milliseconds: 50), () {
      _codeController?.selection = TextSelection.fromPosition(
        TextPosition(offset: cursorPosition),
      );
    });
  }

  void _onLanguageChanged(String? newLangKey) {
    if (newLangKey != null) {
      setState(() {
        _selectedLanguage = newLangKey;
        _setBoilerplateCode(newLangKey);
      });
    }
  }

  Future<void> _runCode() async {
    final code = _codeController?.text ?? '';
    if (code.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some code to run.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _output = 'Executing...';
    });

    try {
      final response = await http
          .post(
            Uri.parse(backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'language': _selectedLanguage, 'code': code}),
          )
          .timeout(const Duration(seconds: 20));

      final responseBody = json.decode(response.body);

      setState(() {
        if (response.statusCode == 200) {
          _output =
              responseBody['output'] ??
              responseBody['error'] ??
              'No output received.';
        } else {
          _output =
              'Error: ${responseBody['error'] ?? 'An unknown error occurred.'}';
        }
      });
    } catch (e) {
      setState(() {
        _output =
            'Failed to connect to the server or request timed out.\nPlease check your connection and try again.\n\nError: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    final codeEditorWidget = Expanded(
      flex: isDesktop ? 1 : 3,
      child: CodeTheme(
        data: CodeThemeData(styles: monokaiSublimeTheme),
        child: CodeField(
          controller: _codeController!,
          expands: true,
          textStyle: const TextStyle(fontFamily: 'monospace'),
        ),
      ),
    );

    final outputConsoleWidget = Expanded(
      flex: isDesktop ? 1 : 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Output:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D34),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _output,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Code Compiler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    underline: Container(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.tealAccent,
                    ),
                    items:
                        _supportedLanguages.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                    onChanged: _onLanguageChanged,
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runCode,
                    icon:
                        _isLoading
                            ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 3,
                              ),
                            )
                            : const Icon(Icons.play_arrow, color: Colors.black),
                    label: Text(
                      _isLoading ? 'Running...' : 'Run',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  isDesktop
                      ? Row(
                        children: [
                          codeEditorWidget,
                          const SizedBox(width: 12),
                          outputConsoleWidget,
                        ],
                      )
                      : Column(
                        children: [
                          codeEditorWidget,
                          const SizedBox(height: 12),
                          outputConsoleWidget,
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
