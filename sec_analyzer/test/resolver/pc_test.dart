import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/security_label.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:analyzer/dart/ast/ast.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PcTest);
  });
}

@reflectiveTest
class PcTest extends AbstractSecDartTest {
  void test_ifStatementWithInterval() {
    var program = '''
         import "package:secdart/secdart.dart";         
         int foo (@high bool a) {            
            if(a){
              return 1;
            } else{
              return 2;
            }            
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source, intervalModeWithDefaultLatticeConfig);

    var unit = result.astNode;
    result.errors.forEach(print);
    expect(result.errors, isEmpty);

    var ifStatement = AstQuery.toList(unit).where((n) => n is IfStatement).first
        as IfStatement;

    var pcThen = ifStatement.thenStatement.getProperty(SEC_PC_PROPERTY);
    expect(pcThen, new IntervalLabel(HighLabel, TopLabel));

    var pcElse = ifStatement.thenStatement.getProperty(SEC_PC_PROPERTY);
    expect(pcElse, new IntervalLabel(HighLabel, TopLabel));
  }
}
