import 'package:security_transformer/src/security_value.dart';
import "package:secdart/secdart.dart";

var foo = SecurityContext.declare('?', SecurityContext.functionLiteral(() {
  SecurityContext.checkParametersType([], []);
  {
    @low
    dynamic a = SecurityContext.declare(
        'L',
        SecurityContext.binaryExpression(
            () => SecurityContext.binaryExpression(
                () => SecurityContext.integerLiteral(3),
                () => SecurityContext.binaryExpression(
                    () => SecurityContext.integerLiteral(4),
                    () => SecurityContext.integerLiteral(2),
                    'STAR'),
                'PLUS'),
            () => SecurityContext.integerLiteral(5),
            'MINUS'));
    @low
    dynamic b = SecurityContext.declare(
        'L',
        SecurityContext.binaryExpression(
            () => SecurityContext.booleanLiteral(true),
            () => SecurityContext.booleanLiteral(false),
            'AMPERSAND_AMPERSAND'));
  }
}));
