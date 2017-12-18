import 'dart:async';
import 'dart:io';

import 'package:security_transformer/src/main.dart';
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
    final sourcesPath = await dirContentsPath('test/dart_files/sources');
    final expectedsPath = await dirContentsPath('test/dart_files/expecteds');
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
}
