import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import "package:secdart_analyzer/src/errors.dart";

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LoopsTest);
  });
}

@reflectiveTest
class LoopsTest extends AbstractSecDartTest {
  void test_foreachStatementWithLeak() {
    var program = '''
         import "package:secdart/secdart.dart";        
             
          void f(){
             @top var l = [];
             for(@low var i in l){
                print(i);
             }
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: true);

    assert(result.any((x) => x.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }

  void test_forStatementWithImplicitFlow() {
    var program = '''
         import "package:secdart/secdart.dart";        
             
          void f(@top bool condition){ 
             @low var result = 0;
             @low var flag = 1;            
             for(@low var i = 0;condition;i++){
                result = flag;
             }
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: true);

    assert(result.any((x) => x.errorCode == SecurityErrorCode.IMPLICIT_FLOW));
  }
}
