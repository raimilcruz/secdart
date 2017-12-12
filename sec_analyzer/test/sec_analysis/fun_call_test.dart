import 'package:test/test.dart';
import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionCallTest);
  });
}
@reflectiveTest
class FunctionCallTest extends AbstractSecDartTest{
   void test_FunctionCallTest1(){
     var program =
       '''
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
     var source = newSource("/test.dart",program);
     expect(typeCheckSecurityForSource(source),isTrue);
   }
   void test_f2(){
      var program =
      '''
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

      var source = newSource("/test.dart",program);
      expect(typeCheckSecurityForSource(source), isFalse);
   }
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
   void test_basicTest(){
     var program =
     '''
        import "package:secdart/secdart.dart";
        void callFoo(foo){
          foo();
        }
      ''';
     var source = newSource("/test.dart",program);
     expect(typeCheckSecurityForSource(source),isTrue);
   }
}