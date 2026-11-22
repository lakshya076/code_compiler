import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:code_compiler/main.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const CodeCompiler());
  // Flush the delayed cursor placement in _setBoilerplateCode.
  await tester.pump(const Duration(milliseconds: 100));
}

/// Taps Run with [client] injected into package:http's top-level functions.
Future<void> tapRun(WidgetTester tester, http.Client client) async {
  await http.runWithClient(() async {
    await tester.tap(find.text('Run'));
    await tester.pump();
  }, () => client);
  await tester.pumpAndSettle();
}

Future<void> selectLanguage(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButton<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

String editorText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first).controller!.text;

void main() {
  testWidgets('initial screen shows Python, Run button and empty output', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Code Compiler'), findsOneWidget);
    expect(find.text('Python'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('Your output will appear here...'), findsOneWidget);
    expect(editorText(tester), contains('Python'));
  });

  testWidgets('switching language loads its boilerplate', (tester) async {
    await pumpApp(tester);

    await selectLanguage(tester, 'Java');
    expect(editorText(tester), contains('public class Main'));
    expect(editorText(tester), isNot(contains('//CURSOR//')));

    await selectLanguage(tester, 'Rust');
    expect(editorText(tester), contains('fn main()'));
  });

  testWidgets('Run posts language and code, shows output', (tester) async {
    late http.Request sent;
    final client = MockClient((req) async {
      sent = req;
      return http.Response(jsonEncode({'output': 'hello from backend\n'}), 200);
    });

    await pumpApp(tester);
    await selectLanguage(tester, 'C');
    await tapRun(tester, client);

    expect(sent.method, 'POST');
    expect(sent.url.path, '/compile');
    expect(sent.headers['Content-Type'], startsWith('application/json'));
    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body['language'], 'c');
    expect(body['code'], contains('#include <stdio.h>'));
    expect(find.textContaining('hello from backend'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget); // loading state cleared
  });

  testWidgets('compile error returned with 200 is shown', (tester) async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'error': 'SyntaxError: bad'}), 200),
    );

    await pumpApp(tester);
    await tapRun(tester, client);

    expect(find.text('SyntaxError: bad'), findsOneWidget);
  });

  testWidgets('non-200 response is shown as Error:', (tester) async {
    final client = MockClient(
      (_) async =>
          http.Response(jsonEncode({'error': 'Unsupported language'}), 400),
    );

    await pumpApp(tester);
    await tapRun(tester, client);

    expect(find.text('Error: Unsupported language'), findsOneWidget);
  });

  testWidgets('network failure shows connection error', (tester) async {
    final client = MockClient((_) async => throw http.ClientException('down'));

    await pumpApp(tester);
    await tapRun(tester, client);

    expect(
      find.textContaining('Failed to connect to the server'),
      findsOneWidget,
    );
  });

  testWidgets('empty code shows snackbar and sends nothing', (tester) async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response('{}', 200);
    });

    await pumpApp(tester);
    // enterText garbles CodeController's diffing, so set the text directly.
    tester.widget<TextField>(find.byType(TextField).first).controller!.text =
        '   ';
    await tester.pump();
    expect(editorText(tester), '   ');
    await tapRun(tester, client);

    expect(calls, 0);
    expect(find.text('Please enter some code to run.'), findsOneWidget);
  });
}
