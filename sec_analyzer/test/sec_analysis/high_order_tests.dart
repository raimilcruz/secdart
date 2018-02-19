import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:secdart_analyzer/src/errors.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HighOrderFunctionTest);
  });
}

@reflectiveTest
class HighOrderFunctionTest extends AbstractSecDartTest {
  void test_callingDynamicFunctionPassedAsParameter() {
    var program = '''
        import "package:secdart/secdart.dart";
        void foo (f) {
          f();
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(!containsInvalidFlow(result));
  }

  void test_receivingFunctionTypeAliasOk() {
    var program = '''
        import "package:secdart/secdart.dart";
        typedef int BinOp(int a, int b);
        int foo (BinOp f, int a, int b) {
          return f(a,b);
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(!containsInvalidFlow(result));
  }

  void test_receivingFunctionTypeAliasBad() {
    var program = '''
        import "package:secdart/secdart.dart";
        
        @latent("H","H")
        @high typedef int BinOp(@low int a, int b);
        
        @latent("L","L")
        int foo (BinOp f, @high int a, int b) {
          return f(a,b);
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(result.isNotEmpty);
    assert(result.any((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }

  void test_3() {
    var program = '''
        import "package:secdart/secdart.dart";
        void callWithSecret(void f(@low bool)) {
          @high bool secret = true;
          f(secret);
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(result.any((e) => e.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }

  void test_mapWrapper() {
    var program = '''
        import "package:secdart/secdart.dart";
         @low Iterable<int> mapWrapper(@high List<int> a){
          return a.map((x)=>1);
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(
        result.any((e) => e.errorCode == SecurityErrorCode.RETURN_TYPE_ERROR));
  }

  void test_functionAsParameterError() {
    var program = '''
         import "package:secdart/secdart.dart";

          @latent("H","H")
          @high
          typedef int BinOp(@high int a,@high int b);
          
          @top
          typedef int BinOp1(@high int a,@high int b);
        
          @latent("H","L")
          @bot int g(BinOp f){            
            return f(1,2);
          }
          @bot int h(){
            BinOp1 f = (x,y)=> x + y;
            //error here BinOp1 is not subtype BinOp
            return g(f); 
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(result.any((e) => e.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }
}
