import 'package:security_transformer/src/security_value.dart';
import "package:secdart/secdart.dart";

void main() {
  SecurityContext.checkParametersType([], []);
  {
    @high
    dynamic a = SecurityContext.declare('H', SecurityContext.integerLiteral(3));
    foo(a);
  }
}

@latent("H", "L")
@low
dynamic foo(dynamic a) {
  a ??= SecurityContext.nullLiteral();
  SecurityContext.checkParametersType([a], ['?']);
  {
    return SecurityContext.checkReturnType(a, 'L');
  }
}
