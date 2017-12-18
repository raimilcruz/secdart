import 'package:security_transformer/src/security_value.dart';
import "package:secdart/secdart.dart";

void main() {
  SecurityContext.checkParametersType([], []);
  {
    @low
    dynamic a = SecurityContext.declare('L', SecurityContext.integerLiteral(3));
    print(foo(a));
  }
}

@latent("H", "L")
@low
dynamic foo(dynamic a) {
  a ??= SecurityContext.nullLiteral();
  SecurityContext.checkParametersType([a], ['?']);
  return SecurityContext.checkReturnType(a, 'L');
}
