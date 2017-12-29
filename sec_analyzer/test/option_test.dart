import 'package:secdart_analyzer/src/options.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:test/test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SecDartOptionsTest);
  });
}

@reflectiveTest
class SecDartOptionsTest {
  void test_buildEmpty() {
    final options = new SecDartOptions.defaults();
    expect(options.intervalMode, isFalse);
  }

  void test_buildYaml_defaults() {
    final options = new SecDartOptions.from('''
analyzer:
  plugins:
    secdart:
      enabled: true
''');
    expect(options.intervalMode, isFalse);
  }

  void test_buildYaml_intervals_false() {
    final options = new SecDartOptions.from('''
analyzer:
  plugins:
    secdart:
      enabled: true
      intervals: true
''');
    expect(options.intervalMode, isTrue);
  }

  void test_buildYaml_intervals_true() {
    final options = new SecDartOptions.from('''
analyzer:
  plugins:
    secdart:
      enabled: true
      intervals: false
''');
    expect(options.intervalMode, isFalse);
  }

  void test_buildYaml_selfLoading() {
    final options = new SecDartOptions.from('''
analyzer:
  plugins:
    secdart_analyzer_plugin:
      enabled: true
      intervals: true
''');
    expect(options.intervalMode, isTrue);
  }

  void test_buildYaml_selfLoadingIgnoredIfNotEnabled() {
    final options = new SecDartOptions.from('''
analyzer:
  plugins:
    secdart:
      enabled: true

    secdart_analyzer_plugin:
      enabled: false
      intervals: true

''');
    expect(options.intervalMode, isFalse);
  }

  void test_buildYaml_secdartIgnoredIfNotEnabled() {
    final options = new SecDartOptions.from('''
analyzer:
  plugins:
    secdart:
      enabled: false
      intervals: true
      
    secdart_analyzer_plugin:
      enabled: true

''');
    expect(options.intervalMode, isFalse);
  }
}
