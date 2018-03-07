import 'package:security_transformer/src/security_value.dart';
import "package:secdart/secdart.dart";

void main() {
  SecurityContext.checkParametersType([], []);
  {
    @low
    final a = SecurityContext.declare(
        'L',
        SecurityContext.conditionalExpression(
            SecurityContext.booleanLiteral(true),
            () => SecurityContext.integerLiteral(1),
            () => SecurityContext.integerLiteral(0)));
  }
}
