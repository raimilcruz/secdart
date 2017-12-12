import 'package:test/test.dart';
import '../test-helpers.dart';

import 'package:test_reflective_loader/test_reflective_loader.dart';


void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplicitFlowsTest);
  });
}
@reflectiveTest
class ImplicitFlowsTest extends AbstractSecDartTest {
  void test_implicitFlow1() {
    var program =
    '''
        import "package:secdart/secdart.dart";
        @latent("L","L")
        @low foo (@high bool s) {
          @low bool a = false;
          if(s){
            a = true; //Must be rejected (pc here must be H)
          }
          else{
            a = false;
          }
          return 1;
        }
      ''';
    var source = newSource("/test.dart", program);
    expect(typeCheckSecurityForSource(source), isFalse);
  }
  void test_noImplicitFlow() {
    var program =
    '''
        import "package:secdart/secdart.dart";
        @latent("L","L")
        @low foo (@low bool s) {
          @low bool a = false;
          if(s){
            a = true;
          }
          else{
            a = false;
          }
          return 1;
        }
      ''';
    var source = newSource("/test.dart", program);
    expect(typeCheckSecurityForSource(source), isTrue);
  }
}