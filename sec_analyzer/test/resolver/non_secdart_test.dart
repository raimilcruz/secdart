import 'package:secdart_analyzer/security_type.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:analyzer/dart/ast/ast.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoSecDartTest);
  });
}

@reflectiveTest
class NoSecDartTest extends AbstractSecDartTest {
  void test_nonSecDartMethodCall() {
    var program = '''
         import "package:secdart/secdart.dart";  
         @latent("L","L")       
         @high int foo (@high String s) {            
            return s.toString();
          }
      ''';
    var source = newSource("/test.dart", program);
    var result = resolveSecurity(source, intervalModeWithDefaultLatticeConfig);

    var unit = result.astNode;
    result.errors.forEach(print);
    assert(result.errors.isEmpty);

    var methodInv =
        AstQuery.toList(unit).where((n) => n is MethodInvocation).first;

    var securityType = methodInv.getProperty(SEC_TYPE_PROPERTY);
    expect(securityType is InterfaceSecurityType, isTrue);
    final InterfaceSecurityType interfaceSecurityType = securityType;
    expect(interfaceSecurityType.label, IHighLabel);
  }
}
