//
// Contains test for global functions with gradual security typing annotations
//

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import '../test_helpers.dart';
import "package:secdart_analyzer/src/errors.dart";

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionDefinitionTest);
  });
}

@reflectiveTest
class FunctionDefinitionTest extends AbstractSecDartTest {
  void test_explicitFlow() {
    var program = '''
        import "package:secdart/secdart.dart";
        @low int foo (@high int a1) {
          return a1;
        }
      ''';
    var source = newSource("/test.dart", program);

    var result = typeCheckSecurityForSource(source);
    expect(
        result.where((e) => e.errorCode == SecurityErrorCode.RETURN_TYPE_ERROR),
        isNotEmpty);
  }

  void test_secureFlow() {
    var program = '''
        import "package:secdart/secdart.dart";
        @high int foo (@high int a1) {
          return a1;
        }
        ''';

    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);
    expect(containsInvalidFlow(result), isFalse);
  }

  void test_secureFlow2() {
    var program = '''
        import "package:secdart/secdart.dart";
        @low int foo (int a1) {
          return a1;
        }
        ''';

    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    expect(containsInvalidFlow(result), isFalse);
  }

  void test_secureFlow3() {
    var program = '''
        import "package:secdart/secdart.dart";
        int foo (int a1) {
          return a1;
        }
        ''';

    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);

    expect(containsInvalidFlow(result), isFalse);
  }

  //TODO: Move this for if-statement resolver.
  void test_functionReturnedExpression() {
    var program = '''
        import "package:secdart/secdart.dart";
        @low int foo (@high String pass ,@low String guess) {
          if(pass == guess){
            return 1;
          }
          else{
            return 2;
          }
        }
        ''';

    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source);
    var resultWithInterval =
        typeCheckSecurityForSource(source, intervalMode: true);

    expect(result, isEmpty);
    expect(
        resultWithInterval
            .where((e) => e.errorCode == SecurityErrorCode.RETURN_TYPE_ERROR),
        isNotEmpty);
  }

  //TODO: Move this to assignment tests
  void test_cannotLeakUsingFunctionArguments() {
    var program = '''
        import "package:secdart/secdart.dart";
        foo (@high String pass ,@low String guess) {
          guess = pass;
          //todo something public with guess           
        }
        ''';

    var source = newSource("/test.dart", program);
    var resultWithInterval =
        typeCheckSecurityForSource(source, intervalMode: true);

    assert(resultWithInterval
        .any((e) => e.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }
}
