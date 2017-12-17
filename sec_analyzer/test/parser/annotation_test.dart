import 'package:analyzer/dart/ast/ast.dart';
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
class ParserTest extends AbstractSecDartTest{

  void test_repeatedLatentAnnotation(){
    var program =
    '''
         import "package:secdart/secdart.dart";
         @latent("H","L")
         @latent("H","L")
         int foo () {
         }
      ''';
    var source = newSource("/test.dart",program);
    assert(containsParseErrors(source));
  }
  void test_repeatedArgumentAnnotation(){
    var program =
    '''
         import "package:secdart/secdart.dart";         
         int foo (@high @high int a) {
         }
      ''';
    var source = newSource("/test.dart",program);
    assert(containsParseErrors(source));
  }
  void test_repeatedVariableAnnotation(){
    var program =
    '''
         import "package:secdart/secdart.dart";         
         int foo () {
            @high @low int a = 1;
         }
      ''';
    var source = newSource("/test.dart",program);
    assert(containsParseErrors(source));
  }
  void test_functionAnnotatedType1(){
    var function = '''
        @latent("H","L")
        @low
        foo (@bot int a, @top int b) {            
        }
    ''';
    var source = newSource("/test.dart",function);
    var result = resolveDart(source);
    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;
    var visitor = new SecurityParserVisitor(errorListener,false,true);
    unit.accept(visitor);

    var funDecl = AstQuery.toList(unit).
                where((n)=> n is FunctionDeclaration).first;
    var funDecltype = funDecl.getProperty(SEC_TYPE_PROPERTY);


    var parameter1 = AstQuery.toList(unit).
                  where((n)=> n is FormalParameter).first;
    var parameter2 = AstQuery.toList(unit).
                  where((n)=> n is FormalParameter).skip(1).first;

    //formal parameters need to be populated
    expect(parameter1.getProperty(SEC_TYPE_PROPERTY).toString(),
          new GroundSecurityType(new BotLabel()).toString());

    expect(parameter2.getProperty(SEC_TYPE_PROPERTY).toString(),
        new GroundSecurityType(new TopLabel()).toString());

    //FunctionDeclaration must be populated.
    expect(funDecltype.toString(),new SecurityFunctionType(
                  new HighLabel(),
                  <SecurityType>[
                    new GroundSecurityType(new BotLabel()),
                    new GroundSecurityType(new TopLabel()),
                  ],
                  new GroundSecurityType(new LowLabel()),
                  new LowLabel()
    ).toString());
  }
  void test_functionAnnotatedType2(){
    var function = '''
        foo () {
          @high var a = 1;            
        }
    ''';
    var source = newSource("/test.dart",function);
    var result = resolveDart(source);
    ErrorCollector errorListener = new ErrorCollector();

    var unit = result.astNode;
    var visitor = new SecurityParserVisitor(errorListener,false,true);
    unit.accept(visitor);

    var numLit = AstQuery.toList(unit).
                where((n)=> n is IntegerLiteral).first;
    var varDecl = AstQuery.toList(unit).
                where((n)=> n is VariableDeclaration).first;

    var numLitDeclType = numLit.getProperty(SEC_TYPE_PROPERTY);
    var varDeclType = varDecl.getProperty(SEC_TYPE_PROPERTY);

    //we do not fill literals during parsing,
    //Labels for literals are is computed during the security analysis.
    assert(numLitDeclType==null);
    expect(varDeclType.toString(),
          new GroundSecurityType(new HighLabel()).toString());
  }

}