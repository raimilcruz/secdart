import 'package:security_transformer/src/security_value.dart';
import "package:secdart/secdart.dart";

var foo = SecurityContext.declare('?', SecurityContext.functionLiteral(() {
  SecurityContext.checkParametersType([], []);
  {
    @low
    dynamic a = SecurityContext.declare('L', SecurityContext.integerLiteral(3));
  }
}));
