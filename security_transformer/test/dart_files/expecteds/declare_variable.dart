import 'package:security_transformer/src/security_value.dart';
import "package:secdart/secdart.dart";

void foo() {
  SecurityContext.checkParametersType([], []);
  {
    @low
    dynamic a = SecurityContext.declare('L', SecurityContext.integerLiteral(3));
  }
}
