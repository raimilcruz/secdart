import 'package:security_transformer/src/security_value.dart';
import 'package:secdart/secdart.dart';

void main() {
  SecurityContext.checkParametersType([], []);
  {
    @low
    dynamic a = SecurityContext.declare('L', SecurityContext.nullLiteral());
    @high
    dynamic b =
        SecurityContext.declare('H', SecurityContext.booleanLiteral(true));
    {
      if (SecurityContext.evaluateConditionAndUpdatePc(b, 0)) {
        SecurityContext.assign(a, SecurityContext.integerLiteral(1));
      } else {
        print(SecurityContext.stringLiteral("hi"));
      }
      SecurityContext.recoverPc(0);
    }
  }
}
