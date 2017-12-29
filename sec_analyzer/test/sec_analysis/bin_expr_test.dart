import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BinaryExprTest);
  });
}

@reflectiveTest
class BinaryExprTest extends AbstractSecDartTest {
  void test_flowSensitiveSum() {
    //Sum bad. Sum produces a high confidential result that will be assigned to a low confidential variable
    var program = '''
         import "package:secdart/secdart.dart";
         @latent("H","L")
         @high int foo (@high int a1, @low int a2) {
            @low var a = a1 + a2;
            return 1;
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(containsInvalidFlow(result));
  }

  void test_sumOk() {
    var program = '''
          import "package:secdart/secdart.dart";
          @latent("L","L")
          @high int foo (@low int a1, @low int a2) {
            @low var a = a2 + a2;
            return 1;
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(result.isEmpty);
    assert(!containsInvalidFlow(result));
  }

  void test_relaxedModeBinOp() {
    var program = '''
          import "package:secdart/secdart.dart";          
          void foo (@high int a1, @dynl int a2) {
            @low var a = a1 + a2;
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    assert(result.isEmpty);
    assert(!containsInvalidFlow(result));
  }

  void test_strictModeBinOp() {
    var program = '''
          import "package:secdart/secdart.dart";          
          void foo (@high int a1, @dynl int a2) {
            @low var a = a1 + a2;
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: true);

    assert(containsInvalidFlow(result));
  }
}
