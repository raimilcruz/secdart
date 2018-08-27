import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/security_label.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:analyzer/dart/ast/ast.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableDeclarationTest);
  });
}

@reflectiveTest
class VariableDeclarationTest extends AbstractSecDartTest {
  void test_singleVariableDeclaration() {
    var program = '''
         import "package:secdart/secdart.dart";         
         foo () {            
            @low int a = 1;
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var variableDeclaration =
        AstQuery.toList(unit).where((n) => n is VariableDeclaration).first;

    var securityType = variableDeclaration.getProperty(SEC_TYPE_PROPERTY);
    assert(securityType is InterfaceSecurityType);
    expect(securityType.label, GLowLabel);
  }

  void test_multipleVariableDeclaration() {
    var program = '''
         import "package:secdart/secdart.dart";         
         foo () {            
            @low int a = 1,b = 2;
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var variableDeclaration1 =
        AstQuery.toList(unit).where((n) => n is VariableDeclaration).first;

    var variableDeclaration2 = AstQuery.toList(unit)
        .where((n) => n is VariableDeclaration)
        .skip(1)
        .first;

    var securityType1 = variableDeclaration1.getProperty(SEC_TYPE_PROPERTY);
    assert(securityType1 is InterfaceSecurityType);
    expect(securityType1.label, GLowLabel);

    var securityType2 = variableDeclaration2.getProperty(SEC_TYPE_PROPERTY);
    assert(securityType2 is InterfaceSecurityType);
    expect(securityType2.label, GLowLabel);
  }

  void test_multipleVariableDeclarationNoLabels() {
    var program = '''
         import "package:secdart/secdart.dart";         
         foo () {            
            int a = 1,b = 2;
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var variableDeclaration1 =
        AstQuery.toList(unit).where((n) => n is VariableDeclaration).first;
    var variableDeclaration2 = AstQuery.toList(unit)
        .where((n) => n is VariableDeclaration)
        .skip(1)
        .first;

    var securityType1 = variableDeclaration1.getProperty(SEC_TYPE_PROPERTY);
    assert(securityType1 is InterfaceSecurityType);
    expect(securityType1.label, new DynamicLabel());

    var securityType2 = variableDeclaration2.getProperty(SEC_TYPE_PROPERTY);
    assert(securityType2 is InterfaceSecurityType);
    expect(securityType2.label, new DynamicLabel());
  }

  void test_multipleVariableDeclarationNoTypes() {
    var program = '''
         import "package:secdart/secdart.dart";         
         foo () {            
            var a = 1,b = "3";
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var variableDeclaration1 =
        AstQuery.toList(unit).where((n) => n is VariableDeclaration).first;
    var variableDeclaration2 = AstQuery.toList(unit)
        .where((n) => n is VariableDeclaration)
        .skip(1)
        .first;

    var securityType1 = variableDeclaration1.getProperty(SEC_TYPE_PROPERTY);
    assert(securityType1 is InterfaceSecurityType);
    expect(securityType1.label, new DynamicLabel());

    var securityType2 = variableDeclaration2.getProperty(SEC_TYPE_PROPERTY);
    assert(securityType2 is InterfaceSecurityType);
    expect(securityType2.label, new DynamicLabel());
  }
}
