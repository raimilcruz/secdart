import 'package:security_transformer/src/security_value.dart';
import "package:secdart/secdart.dart";

void main() {
  SecurityContext.checkParametersType([], []);
  {
    @low
    dynamic a = SecurityContext.declare('L', SecurityContext.integerLiteral(3)),
        b = SecurityContext.declare('L', SecurityContext.integerLiteral(2));
    SecurityContext.assign(a, b);
  }
}
