import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/security_label.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:analyzer/dart/ast/ast.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HighOrderResolverTest);
  });
}

@reflectiveTest
class HighOrderResolverTest extends AbstractSecDartTest {
  void test_callingHighOrderFunction() {
    var program = '''
        import "package:secdart/secdart.dart";
         Iterable<int> mapWrapper(@high List<int> a){
          return a.map((x)=>1);
        }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var returnStatement = AstQuery.toList(unit)
        .where((n) => n is ReturnStatement)
        .first as ReturnStatement;

    var securityType =
        returnStatement.expression.getProperty(SEC_TYPE_PROPERTY);
    expect(securityType is InterfaceSecurityType, isTrue);
    expect(securityType.label, GHighLabel);
  }

  void test_TypeAlias() {
    var program = '''
        import "package:secdart/secdart.dart";
        
         @latent("H","L")
         @bot
         typedef int BinOp(@top int a,@bot int b);
         
         foo(){
          BinOp f = (x,y)=> x+y;
          return f;
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var returnStatement = AstQuery.toList(unit)
        .where((n) => n is ReturnStatement)
        .first as ReturnStatement;

    var securityType =
        returnStatement.expression.getProperty(SEC_TYPE_PROPERTY);
    expect(securityType is SecurityFunctionType, isTrue);
    //TODO: we need a way a different way to specify label latent label for
    //type alias. Type alias does not need endlabel. EndLabel is the security
    //label of the function, so we take it when we use the type alias in
    // a variable declaration/parameter.
    expect(
        labelShape(securityType),
        new FunctionSecurityTypeLabelShape(
            GHighLabel, new DynamicLabel(), GBotLabel, [GTopLabel, GBotLabel]));
  }

  void test_TypeAlias2() {
    var program = '''
        import "package:secdart/secdart.dart";        
        
         @low
         typedef int BinOp(@top int a,@bot int b);
         
         foo(){
          BinOp f = (x,y)=> x+y;
          return f;
         }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var returnStatement = AstQuery.toList(unit)
        .where((n) => n is ReturnStatement)
        .first as ReturnStatement;

    var securityType =
        returnStatement.expression.getProperty(SEC_TYPE_PROPERTY);
    expect(securityType is SecurityFunctionType, isTrue);
    //TODO: we need a way a different way to specify label latent label for
    //type alias. Type alias does not need endlabel. EndLabel is the security
    //label of the function, so we take it when we use the type alias in
    // a variable declaration/parameter.
    expect(
        labelShape(securityType),
        new FunctionSecurityTypeLabelShape(new DynamicLabel(),
            new DynamicLabel(), GLowLabel, [GTopLabel, GBotLabel]));
  }
}
