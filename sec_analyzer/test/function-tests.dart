//
// Contains test for global functions with gradual security typing annotations
//

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'test-helpers.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionDefinitionTest);
  });
}
@reflectiveTest
class FunctionDefinitionTest extends AbstractSecDartTest{
  void test_explicitFlow(){
    var program =
    '''
        import "package:secdart/secdart.dart";
        int foo (@high int a1) {
          @low var a = a1;
          return 1;
        }
      ''';
    var source = newSource("/test.dart",program);
    expect(typeCheckSecurityForSource(source),isFalse);
  }
  void test_secureFlow(){
    var program =
    '''
        import "package:secdart/secdart.dart";
        int foo (@high int a1) {
          @high var a = a1;
          return 1;
        }
        ''';

    var source = newSource("/test.dart",program);
    expect(typeCheckSecurityForSource(source), isTrue);
  }
  void test_secureFlow2(){
    var program =
    '''
        import "package:secdart/secdart.dart";
         int foo (int a1) {
          @low var a = a1;
          return 1;
        }
        ''';

    var source = newSource("/test.dart",program);
    expect(typeCheckSecurityForSource(source), isTrue);
  }
  void test_secureFlow3(){
    var program =
    '''
        import "package:secdart/secdart.dart";
        int foo (int a1) {
          var a = a1;
          return 1;
        }
        ''';

    var source = newSource("/test.dart",program);
    expect(typeCheckSecurityForSource(source), isTrue);
  }
}