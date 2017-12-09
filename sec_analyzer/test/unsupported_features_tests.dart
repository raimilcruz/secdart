import 'package:test/test.dart';
import 'test-helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';


void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnsupportedFeaturesTest);
  });
}
@reflectiveTest
class UnsupportedFeaturesTest extends AbstractSecDartTest {
  void test_classIsNotSupported() {
    var program =
    '''class A{}
      ''';
    var source = newSource("/test.dart", program);
    expect(typeCheckSecurityForSource(source), isFalse);
  }
  void test_enumIsNotSupported() {
    var program =
    '''enum Color {
          red,
          green,
          blue
       }
      ''';
    var source = newSource("/test.dart", program);
    expect(typeCheckSecurityForSource(source), isFalse);
  }
  void test_throwIsNotSupported() {
    var program =
    '''void A(){
        throw new UnimplementedError();
      }
      ''';
    var source = newSource("/test.dart", program);
    expect(typeCheckSecurityForSource(source), isFalse);
  }
  void test_functionTypeAliasIsNotSupported() {
    var program =
    '''typedef int Compare(int a, int b);
      ''';
    var source = newSource("/test.dart", program);
    expect(typeCheckSecurityForSource(source), isFalse);
  }
}