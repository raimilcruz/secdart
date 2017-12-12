import 'package:test/test.dart';
import '../test-helpers.dart';
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
    expect(containsParseErrors(source),isFalse);
  }
  void test_repeatedArgumentAnnotation(){
    var program =
    '''
         import "package:secdart/secdart.dart";         
         int foo (@high @high int a) {
         }
      ''';
    var source = newSource("/test.dart",program);
    expect(containsParseErrors(source),isFalse);
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
    expect(containsParseErrors(source),isFalse);
  }
}