import 'package:secdart_analyzer/analyzer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisClientTest);
  });
}
@reflectiveTest
class AnalysisClientTest{
  SecAnalyzer secAnalyzer;
  void setUp(){
    secAnalyzer = new SecAnalyzer();
  }
  void test_flowSensitiveSum(){
    //Sum bad. Sum produces a high confidential result that will be assigned to a low confidential variable
    var program =
    '''
         import "package:secdart/secdart.dart";
         @latent("H","L")
         @high int foo (@high int a1, @low int a2) {
            @low var a = a1 + a2;
            return 1;
          }
      ''';
    var result = secAnalyzer.analyze(program,false);
    assert(result.errors.isEmpty,isTrue);
    assert(result.astNode!=null,isTrue);
  }
 }
