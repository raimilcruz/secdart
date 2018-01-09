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
    final runner = new SecurityTransformerRunner();

    final sourcesPath =
        await dirContentsPath(pathos.join("test", "dart_files", "sources"));
    final expectedsPath =
        await dirContentsPath(pathos.join("test", "dart_files", "expecteds"));
    assert(sourcesPath.length == expectedsPath.length);
    for (var i = 0; i < sourcesPath.length; i++) {
      print(
          'Comparing ${sourcesPath[i]} result of transform with ${expectedsPath[i]}.');
      final actual = await runner.transformAndFormat(
          'security_transformer', sourcesPath[i]);
      final expected = await new File(expectedsPath[i]).readAsString();
      assert(actual == expected);
      print('Passed.');
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
