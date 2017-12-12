import 'package:test/test.dart';
import '../test-helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IdentifierTests);
  });
}
@reflectiveTest
class IdentifierTests extends AbstractSecDartTest{
  void test_forwardCall(){
    var program =
    '''
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
    var source = newSource("/test.dart",program);
    expect(typeCheckSecurityForSource(source),isTrue);
  }
  void test_callToFunctionInAnotherFile(){
    var program1 =
    '''
          import "package:secdart/secdart.dart";
          void g(){
          }
      ''';
    var program2 =
    '''
          import "package:secdart/secdart.dart";
          import "secdart/test3.dart";
          void f(){
            g();
          }
      ''';
    var source1 = newSource("/test1.dart",program1);
    addSource(source1);
    var source2 = newSource("/test2.dart",program2);
    typeCheckSecurityForSource(source1);
    expect(typeCheckSecurityForSource(source2),isTrue);
  }
  void test_callToStandardLibraryFunction(){
    var program1 =
    '''
          import "package:secdart/secdart.dart";
          void g(@high int a){
            print(a);
          }
      ''';
    var source1 = newSource("/test2.dart",program1);
    expect(typeCheckSecurityForSource(source1),isFalse);
  }
}