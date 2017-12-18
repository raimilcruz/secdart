import "package:secdart/secdart.dart";

import 'security_value.dart';

void main() {
  SecurityContext.checkParameters([], []);
  {
    @high
    dynamic a = SecurityContext.declare('H', SecurityContext.integerLiteral(3));
    dynamic b = SecurityContext.declare('?', a);
    foo(b);
  }
}

@latent("H", "L")
@low
dynamic foo(@low dynamic a) {
  a ??= SecurityContext.nullLiteral();
  SecurityContext.checkParameters([a], ['L']);
  return a;
}
