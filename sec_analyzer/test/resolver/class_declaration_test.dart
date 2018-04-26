import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:secdart_analyzer/security_type.dart';
import 'package:test/src/frontend/expect.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationTest);
  });
}

@reflectiveTest
class ClassDeclarationTest extends AbstractSecDartTest {
  void test_classInheritance() {
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
    var result = resolveSecurity(source);

    final securityMap = result.elementCache;

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var methodDeclaration1 = AstQuery
        .toList(unit)
        .where((n) => n is MethodDeclaration)
        .first as MethodDeclaration;

    var methodDeclaration2 = AstQuery
        .toList(unit)
        .where((n) => n is MethodDeclaration)
        .skip(1)
        .first as MethodDeclaration;

    var securityType1 = methodDeclaration1.getProperty(SEC_TYPE_PROPERTY);
    var securityType2 = methodDeclaration2.getProperty(SEC_TYPE_PROPERTY);

    expect(securityType1 is SecurityFunctionType, isTrue);
    final funSecurityType1 = securityType1 as SecurityFunctionType;
    expect(funSecurityType1.returnType.label, GLowLabel);
    expect(securityMap.map.containsKey(methodDeclaration1.element), isTrue);

    expect(securityType2 is SecurityFunctionType, isTrue);
    final funSecurityType2 = securityType2 as SecurityFunctionType;
    expect(funSecurityType2.returnType.label, GTopLabel);
    expect(securityMap.map.containsKey(methodDeclaration2.element), isTrue);
  }

  void test_accessToExplicitGetter() {
    var program = '''
         import "package:secdart/secdart.dart";         
        class Person{
            @top
            int get age => 1;           
          }
         int get(@high Person p){
            return p.age;
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var methodInvocation = AstQuery
        .toList(unit)
        .where((n) => n is PrefixedIdentifier)
        .first as PrefixedIdentifier;

    var securityType1 = methodInvocation.getProperty(SEC_TYPE_PROPERTY);

    expect(securityType1 is InterfaceSecurityType, isTrue);
    final interfaceSecurityType = securityType1 as InterfaceSecurityType;
    expect(interfaceSecurityType.label, GTopLabel);
  }

  test_instanceFieldAcccess() {
    var program = '''
         import "package:secdart/secdart.dart";         
         class A{
            @high int _age;
            int leakAge(){
              return _age;
            }
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    final securityMap = result.elementCache;

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var classDeclaration = AstQuery
        .toList(unit)
        .where((n) => n is ClassDeclaration)
        .first as ClassDeclaration;

    var returnStatement = AstQuery
        .toList(classDeclaration)
        .where((n) => n is ReturnStatement)
        .first as ReturnStatement;
    final returnedExpression = returnStatement.expression;

    var securityType = returnedExpression.getProperty(SEC_TYPE_PROPERTY);

    expect(securityType is InterfaceSecurityType, isTrue);
    expect(securityType.label, GHighLabel);

    //check the class element
    final classElement = classDeclaration.element;
    expect(securityMap.map.containsKey(classElement), isTrue);

    final ageAccessor =
        classElement.accessors.where((a) => a.name == "_age").first;
    expect(securityMap.map.containsKey(ageAccessor), isTrue);

    final ageSecurityAccessor =
        securityMap.map[(ageAccessor)] as SecurityPropertyAccessorElement;
    expect(ageSecurityAccessor.propertyType is SecurityFunctionType, isTrue);
    expect(
        (ageSecurityAccessor.propertyType as SecurityFunctionType)
            .returnType
            .label,
        GHighLabel);
  }
}
