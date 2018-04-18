import 'package:analyzer/dart/ast/ast.dart';
import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/src/annotations/parser.dart';
import 'package:secdart_analyzer/src/error_collector.dart';
import 'package:secdart_analyzer/src/parser_visitor.dart';
import 'package:secdart_analyzer/src/security_label.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package:secdart_analyzer/src/errors.dart';

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
    var result = parse(source);
    assert(result.errors.any((e) =>
        e.errorCode == ParserErrorCode.DUPLICATED_FUNCTION_LATENT_ERROR));
  }

  void test_repeatedArgumentAnnotation() {
    var program = '''
         import "package:secdart/secdart.dart";         
         int foo (@high @high int a) {
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = parse(source);
    assert(result.errors.any((e) =>
        e.errorCode == ParserErrorCode.DUPLICATED_LABEL_ON_PARAMETER_ERROR));
  }

  void test_repeatedVariableAnnotation() {
    var program = '''
         import "package:secdart/secdart.dart";         
         int foo () {
            @high @low int a = 1;
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = parse(source);
    assert(result.errors.any((e) =>
        e.errorCode == ParserErrorCode.DUPLICATED_LABEL_ON_PARAMETER_ERROR));
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

    var annotationParser =
        new FourLatticeParser(errorListener, unit as CompilationUnit, false);
    var visitor = new SecurityParserVisitor(
        errorListener, unit, annotationParser, false, true);
    unit.accept(visitor);

    final labelMap = visitor.labeMap;

    var funDecl = AstQuery
        .toList(unit)
        .where((n) => n is FunctionDeclaration)
        .first as FunctionDeclaration;
    var funDeclLabel = funDecl.getProperty(SEC_LABEL_PROPERTY);

    var parameter1 = AstQuery
        .toList(unit)
        .where((n) => n is FormalParameter)
        .first as FormalParameter;
    var parameter2 = AstQuery
        .toList(unit)
        .where((n) => n is FormalParameter)
        .skip(1)
        .first as FormalParameter;

    //formal parameters need to be populated
    final parameter1Label = parameter1.getProperty(SEC_LABEL_PROPERTY);
    assert(parameter1Label is SimpleAnnotatedLabel);
    assert(labelMap.map[parameter1.element] is SimpleAnnotatedLabel);
    expect(parameter1Label.label, new BotLabel());

    final parameter2Label = parameter2.getProperty(SEC_LABEL_PROPERTY);
    assert(parameter2Label is SimpleAnnotatedLabel);
    assert(labelMap.map[parameter2.element] is SimpleAnnotatedLabel);
    expect(parameter2Label.label, new TopLabel());

    //FunctionDeclaration must be populated.
    assert(funDeclLabel is FunctionLevelLabels);
    assert(labelMap.map[funDecl.element] is FunctionLevelLabels);

    if (funDeclLabel is FunctionLevelLabels) {
      //begin label
      expect(funDeclLabel.functionLabels.beginLabel, new HighLabel());
      //end label
      expect(funDeclLabel.functionLabels.endLabel, new LowLabel());
      //return type;
      expect(funDeclLabel.returnLabel, new LowLabel());
    }
  }

  void test_lambdaAreNotAnnotated() {
    var function = '''       
        foo () {
          var lambda = ((x) => 1);            
        }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveDart(source);
    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;

    var annotationParser =
        new FourLatticeParser(errorListener, unit as CompilationUnit, false);
    var visitor = new SecurityParserVisitor(
        errorListener, unit, annotationParser, false, true);
    unit.accept(visitor);

    final labelMap = visitor.labeMap;

    var variableDeclaration =
        AstQuery.toList(unit).where((n) => n is VariableDeclaration).first;

    var lambda = AstQuery
        .toList(variableDeclaration)
        .where((n) => n is FunctionExpression)
        .first as FunctionExpression;

    //formal parameters need to be populated
    final lambdaLabels = lambda.getProperty(SEC_LABEL_PROPERTY);

    assert(lambdaLabels is FunctionLevelLabels);
    assert(labelMap.map[lambda.element] is FunctionLevelLabels);

    if (lambdaLabels is FunctionLevelLabels) {
      //begin label
      assert(lambdaLabels.functionLabels.beginLabel is UnknownLabel);
      //end label
      assert(lambdaLabels.functionLabels.endLabel is UnknownLabel);
      //return type;
      assert(lambdaLabels.returnLabel is UnknownLabel);
    }
  }

  void test_localVariableAnnotation() {
    var function = '''
        foo () {
          @high var a = 1;            
        }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveDart(source);
    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;
    var annotationParser =
        new FourLatticeParser(errorListener, unit as CompilationUnit, false);
    var visitor = new SecurityParserVisitor(
        errorListener, unit, annotationParser, false, true);
    unit.accept(visitor);

    final labelMap = visitor.labeMap;

    var numLit = AstQuery.toList(unit).where((n) => n is IntegerLiteral).first;
    var varDeclList =
        AstQuery.toList(unit).where((n) => n is VariableDeclarationList).first;
    var varDecl = AstQuery
        .toList(varDeclList)
        .where((n) => n is VariableDeclaration)
        .first as VariableDeclaration;

    var numLitDeclLabel = numLit.getProperty(SEC_LABEL_PROPERTY);
    var varDeclLabel = varDeclList.getProperty(SEC_LABEL_PROPERTY);

    //we do not fill literals during parsing,
    //Labels for literals are computed for the security resolver.
    assert(numLitDeclLabel == null);

    //label of local variable
    expect(varDeclLabel is SimpleAnnotatedLabel, isTrue);
    expect(labelMap.map[varDecl.element] is SimpleAnnotatedLabel, isTrue);
    expect(varDeclLabel.label, new HighLabel());
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

    final result = parse(source);
    final unit = result.astNode;

    var methDecl =
        AstQuery.toList(unit).where((n) => n is MethodDeclaration).first;
    var methDeclLabels = methDecl.getProperty(SEC_LABEL_PROPERTY);

    var parameter1 =
        AstQuery.toList(unit).where((n) => n is FormalParameter).first;
    var parameter2 =
        AstQuery.toList(unit).where((n) => n is FormalParameter).skip(1).first;

    //formal parameters need to be populated
    final parameter1Label = parameter1.getProperty(SEC_LABEL_PROPERTY);
    expect(parameter1Label is SimpleAnnotatedLabel, isTrue);
    expect(parameter1Label.label, new BotLabel());

    final parameter2Label = parameter2.getProperty(SEC_LABEL_PROPERTY);
    expect(parameter2Label is SimpleAnnotatedLabel, isTrue);
    expect(parameter2Label.label, new TopLabel());

    //MethodDeclaration must be populated.
    expect(methDeclLabels is FunctionLevelLabels, isTrue);

    if (methDeclLabels is FunctionLevelLabels) {
      //begin label
      expect(methDeclLabels.functionLabels.beginLabel, new HighLabel());
      //end label
      expect(methDeclLabels.functionLabels.endLabel, new LowLabel());
      //return type
      expect(methDeclLabels.returnLabel, new LowLabel());
    }
  }

  void test_notAValidLabel() {
    var program = '''
         import "package:secdart/secdart.dart";
         @latent("H2","K")         
         int foo () {
         }
      ''';
    var source = newSource("/test.dart", program);

    final result = parse(source);

    expect(
        result.errors
            .any((e) => e.errorCode == SecurityErrorCode.INVAlID_LABEL),
        isTrue);
  }

  void test_declassifyOperatorIsRecognized() {
    var program = '''
         import "package:secdart/secdart.dart";
                 
         int foo () {
            return declassify(1,"L");
         }
      ''';
    var source = newSource("/test.dart", program);

    final result = parse(source);

    expect(result.errors.isEmpty, isTrue);
  }

  void test_notAValidLabel2() {
    var program = '''
         import "package:secdart/secdart.dart";
                 
         int foo () {
            return declassify(1,"H2");
         }
      ''';
    var source = newSource("/test.dart", program);

    final result = parse(source);

    expect(
        result.errors
            .any((e) => e.errorCode == SecurityErrorCode.INVAlID_LABEL),
        isTrue);
  }
}
