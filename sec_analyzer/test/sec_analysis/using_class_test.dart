import 'package:test/test.dart';

import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import "package:secdart_analyzer/src/errors.dart";

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UsingClasses);
  });
}

@reflectiveTest
class UsingClasses extends AbstractSecDartTest {
  void test_usingMethodOfMap() {
    var program = '''
         import "package:secdart/secdart.dart";
            void mapFoo(){
              var map = new Map();
              var key = map.keys.toList();
            }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    expect(result, isEmpty);
  }

  void test_usingNoSecDartClasses_1() {
    var program = '''
         import "package:secdart/secdart.dart";
          @latent("L","L")
          void foo (@high String a) {
            @low String s = a.trimLeft();
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    expect(result.where((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW),
        isNotEmpty);
  }

  void test_usingNoSecDartClasses_2() {
    var program = '''
         import "package:secdart/secdart.dart";
          @latent("L","L")
          void foo (@low String a) {
            @low String s = a.trimLeft();
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    expect(result, isEmpty);
  }

  void test_propertyAccess_synthetic() {
    var program = '''
         import "package:secdart/secdart.dart";
          class Person{
            @top
            String name;           
          }
         @high String getName(@high Person p){
            return p.name;
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    expect(
        result.where((e) => e.errorCode == SecurityErrorCode.RETURN_TYPE_ERROR),
        isNotEmpty);
  }

  void test_propertyAccess_explicit() {
    var program = '''
         import "package:secdart/secdart.dart";
          class Person{
            @top
            int get age;           
          }
         @high int get(@high Person p){
            return p.age;
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(
        result.any((e) => e.errorCode == SecurityErrorCode.RETURN_TYPE_ERROR));
  }
}
