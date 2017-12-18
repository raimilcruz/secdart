import 'package:secdart/secdart.dart';

import 'security_value.dart';

dynamic a = SecurityContext.declare(SecurityContext.integerLiteral(0), '?');
dynamic bar(dynamic b) {
  return SecurityContext.assign(a, b);
}

void foo(dynamic b) {
  SecurityContext.assign(a, b);
}
