import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:secdart_analyzer/src/errors.dart';
import 'package:test/test.dart';

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

    expect(result, isNotEmpty);
    expect(result.where((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
  }

  void test_lambdaAsParameter() {
    var program = '''
        import "package:secdart/secdart.dart";
        void callWithSecret(void f(@low bool)) {
          @high bool secret = true;
          f(secret);
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    expect(result.where((e) => e.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
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

    expect(
        result.where((e) => e.errorCode == SecurityErrorCode.RETURN_TYPE_ERROR),
        isNotEmpty);
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

    expect(result.where((e) => e.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
  }

  void test_functionAsParameterWithInLineSignature() {
    var program = '''
         import "package:secdart/secdart.dart";
         
          @latent("H","H")
          @high
          typedef int BinOp(@low int a,@low int b);         
        
          @latent("H","L")
          @bot int g(int f(@high int a,@high int b)){            
            return f(1,2);
          }
          @bot int h(){
            BinOp f = (x,y)=> x + y;
            //error here BinOp is not subtype of the type of g's argument
            return g(f); 
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    expect(result.where((e) => e.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
  }

  void test_functionAsParameterWithInLineSignatureOk() {
    var program = '''
         import "package:secdart/secdart.dart";
         
          @latent("H","H")
          @high
          typedef int BinOp(@top int a,@top int b);         
        
          @latent("H","L")
          @bot int g(int f(@high int a,@high int b)){            
            return f(1,2);
          }
          @low int h(){
            BinOp f = (x,y)=> x + y;
            //BinOp IS subtype of the type of g's argument
            return g(f); 
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    expect(result, isEmpty);
  }
}
