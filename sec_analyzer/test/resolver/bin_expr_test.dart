import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/security_label.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:analyzer/dart/ast/ast.dart';

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
         int foo (@high int a1, @low int a2) {            
            return a1 + a2;
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var binaryExpression =
        AstQuery.toList(unit).where((n) => n is BinaryExpression).first;

    var securityType = binaryExpression.getProperty(SEC_TYPE_PROPERTY);
    expect(securityType is InterfaceSecurityType, isTrue);
    expect(securityType.label, new HighLabel());
  }

  void test_flowSensitiveSum2() {
    var program = '''
          import "package:secdart/secdart.dart";
          int foo (@low int a1, @low int a2) {
            return a1 + a2;
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var binaryExpression =
        AstQuery.toList(unit).where((n) => n is BinaryExpression).first;

    var securityType = binaryExpression.getProperty(SEC_TYPE_PROPERTY);
    expect(securityType is InterfaceSecurityType, isTrue);
    expect(securityType.label, new LowLabel());
  }

  void test_relaxedModeBinOp() {
    var program = '''
          import "package:secdart/secdart.dart";          
          int foo (@high int a1, @dynl int a2) {
            return a1 + a2;
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var binaryExpression =
        AstQuery.toList(unit).where((n) => n is BinaryExpression).first;

    var securityType = binaryExpression.getProperty(SEC_TYPE_PROPERTY);
    expect(securityType is InterfaceSecurityType, isTrue);
    expect(securityType.label, new DynamicLabel());
  }

  void test_strictModeBinOp() {
    var program = '''
          import "package:secdart/secdart.dart";          
          void foo (@high int a1, @dynl int a2) {
            return a1 + a2;
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source, intervalMode: true);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var binaryExpression =
        AstQuery.toList(unit).where((n) => n is BinaryExpression).first;

    var securityType = binaryExpression.getProperty(SEC_TYPE_PROPERTY);
    expect(securityType is InterfaceSecurityType, isTrue);
    expect(
        securityType.label, new IntervalLabel(new HighLabel(), new TopLabel()));
  }
}
