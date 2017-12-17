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
  /*void test_functionAnnotatedType1(){
    var function = '''
        @latent("H","L")
        @low
        foo (@bot int a, @top int b) {            
        }
    ''';
    var ast = resolveDart(  function);
    ErrorCollector errorListener = new ErrorCollector();

    var visitor = new SecurityParserVisitor(errorListener,false,false);
    ast.accept(visitor);

    var type = ast.getProperty(SEC_TYPE_PROPERTY);

    //expect(type,new FunctionSecurityType());
  }*/

}