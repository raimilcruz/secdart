import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as pathos;
import 'package:security_transformer/src/main.dart';
import 'package:security_transformer/security_compiler.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisClientTest);
  });
}

@reflectiveTest
class AnalysisClientTest {
  Future test_transformer() async {
    var missExpectedFile = false;
    final runner = new SecurityTransformerRunner();
    final sourcesDir = 'test/dart_files/sources';
    final expectedsDir = 'test/dart_files/expecteds';
    final sourcesPath =
    await dirContentsPath(pathos.join("test", "dart_files", "sources"));
    for (final sourcePath in sourcesPath) {
      final expectedPath =
          '$expectedsDir${sourcePath.substring(sourcesDir.length)}';
      print(
          'Comparing ${sourcePath} result of transform with ${expectedPath}.');
      final actual =
          await runner.transformAndFormat('security_transformer', sourcePath);
      String expected;
      try {
        expected = await new File(expectedPath).readAsString();
      } catch (e) {
        missExpectedFile = true;
        print('Could not open ${expectedPath} file.');
        print('Alert: Creating expected file.');
        await new File(expectedPath).writeAsString(actual);
        continue;
      }
      assert(actual == expected);
      print('Passed.');
    }
    if (missExpectedFile) {
      print('Alert: Some expected files were created.');
    }
  }

  Future test_transformer2() async {
    final secCompiler = new SecurityCompiler();
    final program = '''
       import "package:secdart/secdart.dart";
       @latent("H","L")
       @high int foo (@high int a1, @low int a2) {
          @low var a = a1 + a2;
          return 1;
        }
    ''';
    final compiled = secCompiler.compile(program);
    print(compiled);
    assert(compiled.length > 100);
  }
}
