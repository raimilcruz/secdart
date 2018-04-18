import 'package:test/test.dart';

import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionCallTest);
  });
}

@reflectiveTest
class FunctionCallTest extends AbstractSecDartTest {
  void test_FunctionCallTest1() {
    var program = '''
       import "package:secdart/secdart.dart";

       @latent("H","H")
       @high foo (@high int s) {
        return 1;
        }
        
        @latent("H","H")
        @high callFoo(){
          foo(5);
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);
    assert(!containsInvalidFlow(result));
  }

  void test_f2() {
    var program = '''
        import "package:secdart/secdart.dart";
        @latent("H","L")
        @high foo (@high int s) {
          return 1;
        }
        
        @latent("L","H")
        @high callFoo(){
          foo(5);
        }
        ''';

    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(!containsInvalidFlow(result));
  }

  void test_forwardCall() {
    var program = '''
       import "package:secdart/secdart.dart";
       
        @latent("H","H")
        @high callFoo(){
          foo(5);
        }

       @latent("H","H")
       @high foo (@high int s) {
        return 1;
        }
        
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(!containsInvalidFlow(result));
  }

  void test_callToFunctionInstance() {
    var program = '''
       import "package:secdart/secdart.dart";
        void foo(Function comp) {
           comp(1,2);
        }

      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);
    expect(result.isEmpty, isTrue);
  }
}
