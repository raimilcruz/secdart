import 'package:test/test.dart';
import '../test_helpers.dart';
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
    var result = typeCheckSecurityForSource(source);

    assert(containsInvalidFlow(result));
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
    var result = typeCheckSecurityForSource(source);

    assert(containsInvalidFlow(result));
  }
  void test_3() {
    var program =
    '''
        import "package:secdart/secdart.dart";
        void callWithSecret(void f(@low bool)) {
          @high bool secret = true;
          f(secret);
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(containsInvalidFlow(result));
  }
}

