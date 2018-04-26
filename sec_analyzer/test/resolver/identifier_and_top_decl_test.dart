import 'package:analyzer/dart/ast/ast.dart';
import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/error_collector.dart';
import 'package:secdart_analyzer/src/security_label.dart';
import 'package:secdart_analyzer/src/security_resolver.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopDeclarationResolverTest);
    defineReflectiveTests(IdentifierResolverTest);
  });
}

@reflectiveTest
class TopDeclarationResolverTest extends AbstractSecDartTest {
  void test_functionAnnotatedType1() {
    var function = '''
        import "package:secdart/secdart.dart";
        @latent("H","L")
        @low
        foo (@bot int a, @top b) {            
        }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveDart(source);
    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;

    resolveTopLevelDeclarations(unit, errorListener, defaultConfig, false);

    var funDecl = AstQuery
        .toList(unit)
        .where((n) => n is FunctionDeclaration)
        .first as FunctionDeclaration;
    var funDeclType = funDecl.getProperty(SEC_TYPE_PROPERTY);
    var funDeclElement = funDecl.getProperty(SECURITY_ELEMENT);

    //FunctionDeclaration must be populated.
    assert(funDeclType is SecurityFunctionType);
    assert(funDeclElement is SecurityFunctionElement);

    if (funDeclType is SecurityFunctionType) {
      //begin label
      expect(funDeclType.beginLabel, GHighLabel);
      //end label
      expect(funDeclType.endLabel, GLowLabel);
      //return type;
      expect(funDeclType.returnType is DynamicSecurityType, isTrue);
      expect(funDeclType.returnType.label, GLowLabel);

      //parameter types
      expect(funDeclType.argumentTypes.length == 2, isTrue);
      expect(funDeclType.argumentTypes.first is InterfaceSecurityType, isTrue);
      expect(funDeclType.argumentTypes.first.label, GBotLabel);

      expect(funDeclType.argumentTypes.skip(1).first is DynamicSecurityType,
          isTrue);
      expect(funDeclType.argumentTypes.skip(1).first.label, GTopLabel);
    }
  }

  void test_globalVar() {
    var function = '''
        import "package:secdart/secdart.dart";
        @low int x;
        f(){
          return x;
        }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveSecurity(source);
    var unit = result.astNode;

    var varDecl = AstQuery
        .toList(unit)
        .where((n) => n is VariableDeclaration)
        .first as VariableDeclaration;
    var varDeclType = varDecl.getProperty(SEC_TYPE_PROPERTY);

    expect(varDeclType is InterfaceSecurityType, isTrue);
    expect(varDeclType.label, GLowLabel);

    var returnStatement = AstQuery
        .toList(unit)
        .where((n) => n is ReturnStatement)
        .first as ReturnStatement;
    var returnedExpressionSecType =
        returnStatement.expression.getProperty(SEC_TYPE_PROPERTY);

    expect(returnedExpressionSecType is InterfaceSecurityType, isTrue);
    expect(varDeclType.label, GLowLabel);
  }

  void test_nestedFunction() {
    var function = '''
        import "package:secdart/secdart.dart";
        void foo(){
          
          @latent("H","L")
          @low
          bar (@bot int a, @top int b) {
          }
        }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveSecurity(source);
    var unit = result.astNode;

    var funDecl = AstQuery
        .toList(unit)
        .where((n) => n is FunctionDeclaration)
        .skip(1)
        .first as FunctionDeclaration;
    var funDeclType = funDecl.getProperty(SEC_TYPE_PROPERTY);

    expect(funDeclType is SecurityFunctionType, isTrue);
    expect(funDeclType.label, new DynamicLabel());

    if (funDeclType is SecurityFunctionType) {
      //begin label
      expect(funDeclType.beginLabel, new DynamicLabel());
      //end label
      expect(funDeclType.endLabel, new DynamicLabel());
      //return type;
      expect(funDeclType.returnType, new isInstanceOf<InterfaceSecurityType>());
      expect(funDeclType.returnType.label, new DynamicLabel());

      //parameter types
      expect(funDeclType.argumentTypes.length == 2, isTrue);
      expect(funDeclType.argumentTypes.first is InterfaceSecurityType, isTrue);
      expect(funDeclType.argumentTypes.first.label, GBotLabel);

      expect(funDeclType.argumentTypes.skip(1).first is InterfaceSecurityType,
          isTrue);
      expect(funDeclType.argumentTypes.skip(1).first.label, GTopLabel);
    }
  }

  void test_nestedFunctionInMethod() {
    var function = '''
        import 'package:secdart/secdart.dart';
        class Quicksort {
            static void _qsort() {
              void _partition() {}
            }
         }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveSecurity(source);

    var unit = result.astNode;

    var funDecl = AstQuery
        .toList(unit)
        .where((n) => n is FunctionDeclaration)
        .first as FunctionDeclaration;
    var funDeclType = funDecl.getProperty(SEC_TYPE_PROPERTY);

    expect(funDeclType, new isInstanceOf<SecurityFunctionType>());
    expect(funDeclType.label, new DynamicLabel());

    if (funDeclType is SecurityFunctionType) {
      //begin label
      expect(funDeclType.beginLabel, new DynamicLabel());
      //end label
      expect(funDeclType.endLabel, new DynamicLabel());
      //return type;
      //expect(funDeclType.returnType, new isInstanceOf<InterfaceSecurityType>());
      expect(funDeclType.returnType.label, new DynamicLabel());
    }
  }
}

@reflectiveTest
class IdentifierResolverTest extends AbstractSecDartTest {
  void test_SimpleFormalParameter() {
    var function = '''
        import "package:secdart/secdart.dart";
        foo (@bot int a) {
          return a;            
        }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveDart(source);
    result.errors.forEach(print);
    assert(result.errors.isEmpty);
    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;

    var resolver = parseAndGetSecurityElementResolver(
        unit, errorListener, defaultConfig, false);

    var returnStm =
        AstQuery.toList(unit).where((n) => n is ReturnStatement).first;

    var variableUsage = AstQuery
        .toList(returnStm)
        .where((n) => n is SimpleIdentifier && n.name == "a")
        .first as SimpleIdentifier;

    var identifierResolver = new SecurityIdentifierResolver(resolver);
    identifierResolver.resolveIdentifier(variableUsage);

    var secType = variableUsage.getProperty(SEC_TYPE_PROPERTY);
    expect(secType is InterfaceSecurityType, isTrue);
    if (secType is InterfaceSecurityType) {
      expect(secType.label, GBotLabel);
    }
  }

  void test_functionElement() {
    var function = '''
        import "package:secdart/secdart.dart";
        foo (@bot int a) {
          bar(a);            
        }
        bar(@bot int a){
          
        }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveDart(source);
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;

    var resolver = parseAndGetSecurityElementResolver(
        unit, errorListener, defaultConfig, false);

    var methodInvocation =
        AstQuery.toList(unit).where((n) => n is MethodInvocation).first;

    var variableUsage = AstQuery
        .toList(methodInvocation)
        .where((n) => n is SimpleIdentifier && n.name == "bar")
        .first as SimpleIdentifier;

    var identifierResolver = new SecurityIdentifierResolver(resolver);
    identifierResolver.resolveIdentifier(variableUsage);

    var secType = variableUsage.getProperty(SEC_TYPE_PROPERTY);
    expect(secType is SecurityFunctionType, isTrue);
    if (secType is SecurityFunctionType) {
      assert(new FunctionSecurityTypeLabelShape(
          new DynamicLabel(),
          new DynamicLabel(),
          new DynamicLabel(),
          [GBotLabel]).sameShapeThat(secType));
    }
  }

  void test_localVariableElement() {
    var function = '''
        import "package:secdart/secdart.dart";
        foo () {
          @high int bar = 1;
          return bar;   
        }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveDart(source);
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;

    var resolver = parseAndGetSecurityElementResolver(
        unit, errorListener, defaultConfig, false);

    var returnStm =
        AstQuery.toList(unit).where((n) => n is ReturnStatement).first;

    var variableUsage = AstQuery
        .toList(returnStm)
        .where((n) => n is SimpleIdentifier && n.name == "bar")
        .first as SimpleIdentifier;

    var identifierResolver = new SecurityIdentifierResolver(resolver);
    identifierResolver.resolveIdentifier(variableUsage);

    var secType = variableUsage.getProperty(SEC_TYPE_PROPERTY);
    expect(secType is InterfaceSecurityType, isTrue);
    expect(secType.label, GHighLabel);
  }

  void test_methodElement() {
    var function = '''
        import "package:secdart/secdart.dart";
        foo () {
          return new A().bar(1);   
        }
        class A{
          @low bar(@high int a){
          }
        }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveDart(source);
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;

    var resolver = parseAndGetSecurityElementResolver(
        unit, errorListener, defaultConfig, false);

    var returnStm =
        AstQuery.toList(unit).where((n) => n is MethodInvocation).first;

    var variableUsage = AstQuery
        .toList(returnStm)
        .where((n) => n is SimpleIdentifier && n.name == "bar")
        .first as SimpleIdentifier;

    var identifierResolver = new SecurityIdentifierResolver(resolver);
    identifierResolver.resolveIdentifier(variableUsage);

    var secType = variableUsage.getProperty(SEC_TYPE_PROPERTY);
    expect(secType is SecurityFunctionType, isTrue);
    if (secType is SecurityFunctionType) {
      assert(new FunctionSecurityTypeLabelShape(
              new DynamicLabel(), new DynamicLabel(), GLowLabel, [GHighLabel])
          .sameShapeThat(secType));
    }
  }
}
