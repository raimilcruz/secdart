import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import "package:secdart_analyzer/src/errors.dart";

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclaration);
  });
}

@reflectiveTest
class ClassDeclaration extends AbstractSecDartTest {
  void test_classDefinition() {
    var program = '''
         import "package:secdart/secdart.dart";
         
         class A{
           @low void f(){
           }
         }
         class B extends A{
           @top void f() {}
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(result.any(
        (x) => x.errorCode == SecurityErrorCode.INVAlID_OVERRIDE_RETURN_LABEL));
  }

  void test_classDefinition2() {
    var program = '''
         import "package:secdart/secdart.dart";
         
         class A{
           void f(@low a){
           }
         }
         class B extends A{
           void f(@bot a) {}
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(result
        .any((x) => x.errorCode == SecurityErrorCode.INVAlID_METHOD_OVERRIDE));
  }

  void test_methodInvocation() {
    var program = '''
         import "package:secdart/secdart.dart";
         
         class A{
           void f(@high a){}
         }
         class B{
           void f(@top b){} 
         }
         g(@top int c, bool b){
           A a = b ? new A():new B();
           a.f(c);
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(result.any((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }

  void test_ImplicitFlow() {
    var program = '''
         import "package:secdart/secdart.dart";
         
         class A{
           @latent("L","L")
           @low int f(){
            return 1;
           }
         }
         class B extends A{           
           @low int f(){
            return 2;
           } 
         }
         @latent("H","H")         
         g(@high bool a){
           @high A c = a? new A():new B();
           @low int f = c.f();           
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(result.any((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }

  void test_ImplicitFlow2() {
    var program = '''
         import "package:secdart/secdart.dart";
         
         class A{
           @low int f(){
            return 1;
           }
         }
         class B extends A{                      
           @low int f(){
            return 2;
           } 
         }                  
         g(@high bool a){           
           @low int f = (a? new A():new B()).f();           
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: true);

    assert(result.any((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }

  void test_ImplicitFlow3() {
    var program = '''
         import "package:secdart/secdart.dart";
         
         class A{
           @low int f(){
            return 1;
           }
         }
         class B extends A{                      
           @low int f(){
            return 2;
           } 
         }                        
         g(@high bool a){           
           //remember A.f has implicitly @latent("?","?")
           @low int f = (a? new A():new B()).f();           
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(result.isEmpty);
  }
}
