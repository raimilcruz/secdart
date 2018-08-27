import 'package:analyzer/dart/ast/ast.dart';
import 'package:secdart_analyzer/analyzer.dart';
import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/src/annotations/parser.dart';
import 'package:secdart_analyzer/src/error_collector.dart';
import 'package:secdart_analyzer/src/options.dart';
import 'package:secdart_analyzer/src/parser_visitor.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package:secdart_analyzer/src/errors.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CustomLatticeParserTest);
  });
}

@reflectiveTest
class CustomLatticeParserTest extends AbstractSecDartTest {
  static final latticeConfig = new LatticeConfig([
    "Alice",
    "Bob",
    "T",
    "B"
  ], [
    new LabelOrder("Alice", "T"),
    new LabelOrder("Bob", "T"),
    new LabelOrder("B", "Alice"),
    new LabelOrder("B", "Bob")
  ], "T", "B");

  void test_recognizeCustomLabelInParameter() {
    var program = '''
         import "package:secdart/secdart.dart";         
         int foo (@lab("Alice") int a) {
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveDart(source);
    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;

    var annotationParser = new ConfigurableLatticeParser(
        latticeConfig, errorListener, unit as CompilationUnit);
    var visitor =
        new SecurityParserVisitor(errorListener, unit, annotationParser, true);
    unit.accept(visitor);

    expect(result.errors.where((e) => e.errorCode is ParserErrorCode), isEmpty);

    var parameter1 = AstQuery.toList(unit)
        .where((n) => n is FormalParameter)
        .first as FormalParameter;

    final parameter1Label = parameter1.getProperty(SEC_LABEL_PROPERTY);
    expect(parameter1Label is SimpleAnnotatedLabel, isTrue);
    expect(parameter1Label.label, new LabelNodeImpl("Alice"));
  }

  void test_recognizeCustomLabelInLocalVariable() {
    var function = '''
        foo () {
          @lab("Bob") var a = 1;            
        }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveDart(source);
    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;
    var annotationParser = new ConfigurableLatticeParser(
        latticeConfig, errorListener, unit as CompilationUnit);
    var visitor =
        new SecurityParserVisitor(errorListener, unit, annotationParser, true);
    unit.accept(visitor);

    final labelMap = visitor.labeMap;

    var numLit = AstQuery.toList(unit).where((n) => n is IntegerLiteral).first;
    var varDeclList =
        AstQuery.toList(unit).where((n) => n is VariableDeclarationList).first;
    var varDecl = AstQuery.toList(varDeclList)
        .where((n) => n is VariableDeclaration)
        .first as VariableDeclaration;

    var numLitDeclLabel = numLit.getProperty(SEC_LABEL_PROPERTY);
    var varDeclLabel = varDeclList.getProperty(SEC_LABEL_PROPERTY);

    //we do not fill literals during parsing,
    //Labels for literals are computed for the security resolver.
    expect(numLitDeclLabel, isNull);

    //label of local variable
    expect(varDeclLabel is SimpleAnnotatedLabel, isTrue);
    expect(labelMap.map[varDecl.element] is SimpleAnnotatedLabel, isTrue);
    expect(varDeclLabel.label, new LabelNodeImpl("Bob"));
  }

  void test_recognizeCustomLabelAtFunctionLevel() {
    var function = '''
        @latent("Bob","T")
        @lab("Alice")
        foo () {            
        }
    ''';
    var source = newSource("/test.dart", function);
    var result = resolveDart(source);
    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;

    var annotationParser = new ConfigurableLatticeParser(
        latticeConfig, errorListener, unit as CompilationUnit);
    var visitor =
        new SecurityParserVisitor(errorListener, unit, annotationParser, true);
    unit.accept(visitor);

    final labelMap = visitor.labeMap;

    var funDecl = AstQuery.toList(unit)
        .where((n) => n is FunctionDeclaration)
        .first as FunctionDeclaration;
    var funDeclLabel = funDecl.getProperty(SEC_LABEL_PROPERTY);

    //FunctionDeclaration must be populated.
    expect(funDeclLabel is FunctionLevelLabels, isTrue);
    expect(labelMap.map[funDecl.element] is FunctionLevelLabels, isTrue);

    if (funDeclLabel is FunctionLevelLabels) {
      //begin label
      expect(funDeclLabel.functionLabels.beginLabel, new LabelNodeImpl("Bob"));
      //end label
      expect(funDeclLabel.functionLabels.endLabel, new LabelNodeImpl("T"));
      //return type;
      expect(funDeclLabel.returnLabel, new LabelNodeImpl("Alice"));
    }
  }

  void test_unrecognizableCustomLabelAtFunctionLevel() {
    var program = '''
         import "package:secdart/secdart.dart";
         @latent("H","Bob")         
         int foo () {
         }
      ''';
    var source = newSource("/test.dart", program);

    final result = parse(source, new SecAnalysisConfig(false, latticeConfig));

    expect(
        result.errors
            .any((e) => e.errorCode == SecurityErrorCode.INVAlID_LABEL),
        isTrue);
  }
}
