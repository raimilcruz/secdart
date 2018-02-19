import 'package:analyzer/dart/ast/ast.dart';
import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/error_collector.dart';
import 'package:secdart_analyzer/src/parser_visitor.dart';
import 'package:secdart_analyzer/src/security_label.dart';
import 'package:secdart_analyzer/src/security_type.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParserTest);
  });
}

@reflectiveTest
class ParserTest extends AbstractSecDartTest {
  void test_repeatedLatentAnnotation() {
    var program = '''
         import "package:secdart/secdart.dart";
         @latent("H","L")
         @latent("H","L")
         int foo () {
         }
      ''';
    var source = newSource("/test.dart", program);
    assert(containsParseErrors(source));
  }

  void test_repeatedArgumentAnnotation() {
    var program = '''
         import "package:secdart/secdart.dart";         
         int foo (@high @high int a) {
         }
      ''';
    var source = newSource("/test.dart", program);
    assert(containsParseErrors(source));
  }

  void test_repeatedVariableAnnotation() {
    var program = '''
         import "package:secdart/secdart.dart";         
         int foo () {
            @high @low int a = 1;
         }
      ''';
    var source = newSource("/test.dart", program);
    assert(containsParseErrors(source));
  }

  void test_functionAnnotatedType1() {
    var function = '''
        @latent("H","L")
        @low
        foo (@bot int a, @top int b) {            
        }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveDart(source);
    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;
    var visitor = new SecurityParserVisitor(errorListener, false, true);
    unit.accept(visitor);

    var funDecl =
        AstQuery.toList(unit).where((n) => n is FunctionDeclaration).first;
    var funDecltype = funDecl.getProperty(SEC_TYPE_PROPERTY);

    var parameter1 =
        AstQuery.toList(unit).where((n) => n is FormalParameter).first;
    var parameter2 =
        AstQuery.toList(unit).where((n) => n is FormalParameter).skip(1).first;

    //formal parameters need to be populated
    final parameter1Type = parameter1.getProperty(SEC_TYPE_PROPERTY);
    assert(parameter1Type is InterfaceSecurityType);
    expect(parameter1Type.label, new BotLabel());

    final parameter2Type = parameter2.getProperty(SEC_TYPE_PROPERTY);
    assert(parameter2Type is InterfaceSecurityType);
    expect(parameter2Type.label, new TopLabel());

    //FunctionDeclaration must be populated.
    assert(funDecltype is SecurityFunctionType);

    if (funDecltype is SecurityFunctionType) {
      //arguments
      expect(funDecltype.beginLabel, new HighLabel());
      expect(funDecltype.argumentTypes.length, 2);
      //return type
      assert(funDecltype.returnType is DynamicSecurityType);
      expect(funDecltype.returnType.label, new LowLabel());
      //end label
      expect(funDecltype.endLabel, new LowLabel());
    }
  }

  void test_functionAnnotatedType2() {
    var function = '''
        foo () {
          @high var a = 1;            
        }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveDart(source);
    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;
    var visitor = new SecurityParserVisitor(errorListener, false, true);
    unit.accept(visitor);

    var numLit = AstQuery.toList(unit).where((n) => n is IntegerLiteral).first;
    var varDecl =
        AstQuery.toList(unit).where((n) => n is VariableDeclaration).first;

    var numLitDeclType = numLit.getProperty(SEC_TYPE_PROPERTY);
    var varDeclType = varDecl.getProperty(SEC_TYPE_PROPERTY);

    //we do not fill literals during parsing,
    //Labels for literals are computed for the security resolver.
    assert(numLitDeclType == null);
    //here we based on the standard Dart inference to infer type Int for the
    //variable
    assert(varDeclType is InterfaceSecurityType);
    expect(varDeclType.label, new HighLabel());
  }

  void test_classDeclaration() {
    var function = '''
         class A{
           @latent("H","L")
           @low
           foo (@bot int a, @top int b) {            
           }
         }         
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveDart(source);
    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;
    var visitor = new SecurityParserVisitor(errorListener, false, true);
    unit.accept(visitor);

    var methDecl =
        AstQuery.toList(unit).where((n) => n is MethodDeclaration).first;
    var funDecltype = methDecl.getProperty(SEC_TYPE_PROPERTY);

    var parameter1 =
        AstQuery.toList(unit).where((n) => n is FormalParameter).first;
    var parameter2 =
        AstQuery.toList(unit).where((n) => n is FormalParameter).skip(1).first;

    //formal parameters need to be populated
    final parameter1Type = parameter1.getProperty(SEC_TYPE_PROPERTY);
    assert(parameter1Type is InterfaceSecurityType);
    expect(parameter1Type.label, new BotLabel());

    final parameter2Type = parameter2.getProperty(SEC_TYPE_PROPERTY);
    assert(parameter2Type is InterfaceSecurityType);
    expect(parameter2Type.label, new TopLabel());

    //MethodDeclaration must be populated.
    assert(funDecltype is SecurityFunctionType);

    if (funDecltype is SecurityFunctionType) {
      //arguments
      expect(funDecltype.beginLabel, new HighLabel());
      expect(funDecltype.argumentTypes.length, 2);
      //return type
      assert(funDecltype.returnType is DynamicSecurityType);
      expect(funDecltype.returnType.label, new LowLabel());
      //end label
      expect(funDecltype.endLabel, new LowLabel());
    }
  }
}
