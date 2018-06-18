import 'package:security_transformer/src/security_value.dart';
import "package:secdart/secdart.dart";

void main() {
  SecurityContext.checkParametersType([], []);
  {
    print(
        SecurityContext.integerLiteral(0) & SecurityContext.integerLiteral(1));
    print(SecurityContext.ampersandAmpersandBinaryExpression(
        SecurityContext.booleanLiteral(true),
        SecurityContext.booleanLiteral(false)));
    print(
        SecurityContext.integerLiteral(0) | SecurityContext.integerLiteral(1));
    print(SecurityContext.barBarBinaryExpression(
        SecurityContext.booleanLiteral(false),
        SecurityContext.booleanLiteral(true)));
    print(
        SecurityContext.integerLiteral(0) ^ SecurityContext.integerLiteral(1));
    print(SecurityContext.equalEqualBinaryExpression(
        SecurityContext.integerLiteral(0), SecurityContext.integerLiteral(1)));
    print(
        SecurityContext.integerLiteral(0) > SecurityContext.integerLiteral(1));
    print(
        SecurityContext.integerLiteral(0) >= SecurityContext.integerLiteral(1));
    print(
        SecurityContext.integerLiteral(0) >> SecurityContext.integerLiteral(1));
    print(
        SecurityContext.integerLiteral(0) < SecurityContext.integerLiteral(1));
    print(
        SecurityContext.integerLiteral(0) <= SecurityContext.integerLiteral(1));
    print(
        SecurityContext.integerLiteral(0) << SecurityContext.integerLiteral(1));
    print(
        SecurityContext.integerLiteral(0) - SecurityContext.integerLiteral(1));
    print(
        SecurityContext.integerLiteral(0) & SecurityContext.integerLiteral(1));
    print(
        SecurityContext.integerLiteral(0) + SecurityContext.integerLiteral(1));
    print(
        SecurityContext.integerLiteral(0) * SecurityContext.integerLiteral(1));
    print(
        SecurityContext.integerLiteral(0) / SecurityContext.integerLiteral(1));
    print(
        SecurityContext.integerLiteral(0) ~/ SecurityContext.integerLiteral(1));
    print(SecurityContext.questionQuestionBinaryExpression(
        SecurityContext.integerLiteral(0), SecurityContext.integerLiteral(1)));
  }
}
