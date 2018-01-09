import 'package:security_transformer/src/security_value.dart';
import "package:secdart/secdart.dart";

void main() {
  SecurityContext.checkParametersType([], []);
  {
    @low
    dynamic a = SecurityContext.declare('L', SecurityContext.integerLiteral(0));
    @low
    dynamic b =
        SecurityContext.declare('L', SecurityContext.doubleLiteral(1.0));
    @low
    dynamic c =
        SecurityContext.declare('L', SecurityContext.booleanLiteral(true));
    @low
    dynamic d = SecurityContext.declare(
        'L', SecurityContext.stringLiteral("Hello world"));
  }
}
