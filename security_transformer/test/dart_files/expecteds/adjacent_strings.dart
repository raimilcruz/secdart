import 'package:security_transformer/src/security_value.dart';
import 'package:secdart/secdart.dart';

var a = SecurityContext.declare(
    '?',
    SecurityContext.adjacentStrings([
      SecurityContext.stringLiteral("hello"),
      SecurityContext.stringLiteral("world")
    ]));
