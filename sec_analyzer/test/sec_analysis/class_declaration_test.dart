import 'package:test/test.dart';

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
           @low void f() {}
         }
         class B extends A{
           @top void f() {}
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    expect(
        result.where((x) =>
            x.errorCode == SecurityErrorCode.INVAlID_OVERRIDE_RETURN_LABEL),
        isNotEmpty);
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

    expect(
        result.where(
            (x) => x.errorCode == SecurityErrorCode.INVAlID_METHOD_OVERRIDE),
        isNotEmpty);
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

    expect(result.where((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
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

    expect(result.where((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
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
    var result = typeCheckSecurityForSource(source,
        config: intervalModeWithDefaultLatticeConfig);

    expect(result, isNotEmpty);
    expect(result.where((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
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

    expect(result, isEmpty);
  }

  void test_explicitConstructorOk() {
    var program = '''
       import "package:secdart/secdart.dart";
        void f(@low int b){
        }
        class A{
          A.other(@high int a){
            f(a);
          }
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source,
        config: intervalModeWithDefaultLatticeConfig);

    expect(result, isNotEmpty);
    expect(result.where((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
  }

  void test_callConstructor() {
    var program = '''
       import "package:secdart/secdart.dart";
        class A{
          A(@high int a){            
          }
        }
        void main(@top int x){
          A a = new A(x);
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source,
        config: intervalModeWithDefaultLatticeConfig);

    expect(result, isNotEmpty);
    expect(result.where((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
  }

  void test_setInstanceFieldInvalidFlow() {
    var program = '''
       import "package:secdart/secdart.dart";        
        class A{
          @high int _age;
          void setAge(@top int age){
            _age = age;
          }
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source,
        config: intervalModeWithDefaultLatticeConfig);

    expect(result, isNotEmpty);
    expect(result.where((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
  }

  void test_getInstanceFieldInvalidFlow() {
    var program = '''
       import "package:secdart/secdart.dart";
        void leak(@bot b){          
        }        
        class A{
          @high int _age;
          void callLeak(){
            leak(_age);
          }
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source,
        config: intervalModeWithDefaultLatticeConfig);

    expect(result.isNotEmpty, isTrue);
    expect(result.where((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
  }

  void test_clientSetFieldInvalidFlow() {
    var program = '''
       import "package:secdart/secdart.dart";
                 
        class A{
          @high int age;          
        }
        void main(){
          @bot A a = new A();
          @top var secret = 42;
          a.age = secret;
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source,
        config: intervalModeWithDefaultLatticeConfig);

    expect(result, isNotEmpty);
    expect(result.where((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
  }

  void test_clientGetFieldInvalidFlow() {
    var program = '''
       import "package:secdart/secdart.dart";
         void leak(@bot b){          
        }        
        class A{
          @high int age;          
        }
        void main(){
          @bot A a = new A();          
          leak(a.age);
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source,
        config: intervalModeWithDefaultLatticeConfig);

    expect(result.isNotEmpty, isTrue);
    expect(result.where((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
  }

  void test_IndexedExpression() {
    var program = '''
        import "package:secdart/secdart.dart";
        void foo(List l) {
          var a = l[1];
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source,
        config: intervalModeWithDefaultLatticeConfig);
    expect(result, isEmpty);
  }
}
