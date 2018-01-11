import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartEstandarErrorsTests);
  });
}

@reflectiveTest
class DartEstandarErrorsTests extends AbstractSecDartTest {
  void test_strongModeError1() {
    var program = '''
        import "package:secdart/secdart.dart";
    
        int foo (bool secret) {  
          int a  = false;
          return a;
        }

        ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, includeDartErrors: true);

    assert(result.length > 0);
  }
}
