import 'package:test/test.dart';
import '../test-helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';


void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HighOrderFunctionTest);
  });
}
@reflectiveTest
class HighOrderFunctionTest extends AbstractSecDartTest {
  void test_callingFunctionPassedAsParameter() {
    var program =
    '''
        import "package:secdart/secdart.dart";
        void foo (f) {
          f();
        }
      ''';
    var source = newSource("/test.dart", program);
    expect(typeCheckSecurityForSource(source), isFalse);
  }
  void test_callingFunctionPassedAsParameter2() {
    var program =
    '''
        import "package:secdart/secdart.dart";
        void foo (void f()) {
          f();
        }
      ''';
    var source = newSource("/test.dart", program);
    expect(typeCheckSecurityForSource(source), isTrue);
  }
}

