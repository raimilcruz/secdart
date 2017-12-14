import 'package:secdart/secdart.dart';

import 'security_value.dart';

void main() {
  @high
  dynamic a =
      SecurityContext.declare(SecurityContext.booleanLiteral(true), 'H');
  dynamic b = SecurityContext.declare(a, '?');
  @low
  dynamic x = SecurityContext.declare(SecurityContext.nullLiteral(), 'L');
  @high
  dynamic y = SecurityContext.declare(SecurityContext.nullLiteral(), 'H');
  {
    if (SecurityContext.evaluateConditionAndUpdatePc(a, 0))
      SecurityContext.assign(y, SecurityContext.integerLiteral(1));
    else
      SecurityContext.assign(y, SecurityContext.integerLiteral(0));
    SecurityContext.recoverPc(0);
  }
  {
    if (SecurityContext.evaluateConditionAndUpdatePc(a, 1))
      SecurityContext.assign(y, SecurityContext.integerLiteral(1));
    else
      SecurityContext.assign(y, SecurityContext.integerLiteral(0));
    SecurityContext.recoverPc(1);
  }
  SecurityContext.assign(x, SecurityContext.integerLiteral(0));
  print(x);
}
