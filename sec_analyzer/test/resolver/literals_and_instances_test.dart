import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/security_label.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:analyzer/dart/ast/ast.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LiteralsAndInstancesTest);
  });
}

@reflectiveTest
class LiteralsAndInstancesTest extends AbstractSecDartTest {
  void test_lambda() {
    var program = '''
         import "package:secdart/secdart.dart";         
         int foo () {            
            var lambda = (x) => 1;
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var variableDeclaration =
        AstQuery.toList(unit).where((n) => n is VariableDeclaration).first;

    var lambda = AstQuery
        .toList(variableDeclaration)
        .where((n) => n is FunctionExpression)
        .first;

    var securityType = lambda.getProperty(SEC_TYPE_PROPERTY);
    assert(securityType is SecurityFunctionType);
    //the if is to get flow-sensitive type inference from dart.
    if (securityType is SecurityFunctionType) {
      expect(securityType.endLabel, new DynamicLabel());
      expect(securityType.beginLabel, new DynamicLabel());
      expect(securityType.returnType.label, new DynamicLabel());
      expect(securityType.argumentTypes.first.label, new DynamicLabel());
    }
  }

  void test_lambdaWithAnnotatedParameters() {
    var program = '''
         import "package:secdart/secdart.dart";         
         int foo () {            
            var lambda = (@low int x) => 1;
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var variableDeclaration =
        AstQuery.toList(unit).where((n) => n is VariableDeclaration).first;

    var lambda = AstQuery
        .toList(variableDeclaration)
        .where((n) => n is FunctionExpression)
        .first;

    var securityType = lambda.getProperty(SEC_TYPE_PROPERTY);
    assert(securityType is SecurityFunctionType);
    //the if is to get flow-sensitive type inference from dart.
    if (securityType is SecurityFunctionType) {
      expect(securityType.endLabel, new DynamicLabel());
      expect(securityType.beginLabel, new DynamicLabel());
      expect(securityType.returnType.label, new DynamicLabel());
      expect(securityType.argumentTypes.first.label, new LowLabel());
    }
  }

  void test_lambdaInHighContext() {
    var program = '''
         import "package:secdart/secdart.dart";
         @latent("H","L")         
         int foo () {            
            var lambda = () => 1;
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source, intervalMode: true);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var variableDeclaration =
        AstQuery.toList(unit).where((n) => n is VariableDeclaration).first;

    var lambda = AstQuery
        .toList(variableDeclaration)
        .where((n) => n is FunctionExpression)
        .first;

    var securityType = lambda.getProperty(SEC_TYPE_PROPERTY);
    assert(securityType is SecurityFunctionType);

    //the if is to get flow-sensitive type inference from dart.
    if (securityType is SecurityFunctionType) {
      expect(securityType.beginLabel,
          new IntervalLabel(new BotLabel(), new TopLabel()));
      expect(securityType.endLabel,
          new IntervalLabel(new BotLabel(), new TopLabel()));
      expect(securityType.returnType.label,
          new IntervalLabel(new HighLabel(), new TopLabel()));
    }
  }

  void test_intLiteral() {
    var program = '''
         import "package:secdart/secdart.dart";
         @latent("H","L")         
         int foo () {            
            return 1;
          }
      ''';

    var filter = (n) => n is IntegerLiteral;
    _checkLiteralSecType(program, filter, false, new DynamicLabel());
    _checkLiteralSecType(program, filter, true,
        new IntervalLabel(new HighLabel(), new TopLabel()));
  }

  void test_stringLiteral() {
    var program = '''
         import "package:secdart/secdart.dart";
         @latent("H","L")         
         String foo () {            
            return "";
          }
      ''';
    var filter = (n) => n is StringLiteral;
    _checkLiteralSecType(program, filter, false, new DynamicLabel());
    _checkLiteralSecType(program, filter, true,
        new IntervalLabel(new HighLabel(), new TopLabel()));
  }

  void test_BoolLiteral() {
    var program = '''
         import "package:secdart/secdart.dart";
         @latent("H","L")         
         bool foo () {            
            return true;
          }
      ''';
    var filter = (n) => n is BooleanLiteral;
    _checkLiteralSecType(program, filter, false, new DynamicLabel());
    _checkLiteralSecType(program, filter, true,
        new IntervalLabel(new HighLabel(), new TopLabel()));
  }

  void _checkLiteralSecType(
      String program, filter, bool useInterval, SecurityLabel expectedLabel) {
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source, intervalMode: useInterval);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var returnStm =
        AstQuery.toList(unit).where((n) => n is ReturnStatement).first;

    var intLiteral = AstQuery.toList(returnStm).where((n) => filter(n)).first;

    var securityType = intLiteral.getProperty(SEC_TYPE_PROPERTY);
    assert(securityType is InterfaceSecurityType);

    //the if is to get flow-sensitive type inference from dart.
    if (securityType is InterfaceSecurityType) {
      expect(securityType.label, expectedLabel);
    }
  }
}
