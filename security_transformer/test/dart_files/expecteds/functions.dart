import 'package:security_transformer/src/security_value.dart';
import "package:secdart/secdart.dart";

void main() {
  SecurityContext.checkParametersType([], []);
  {
    var foo = SecurityContext.declare('?', SecurityContext.functionLiteral((a) {
      a ??= SecurityContext.nullLiteral();
      SecurityContext.checkParametersType([a], ['null']);
      {
        print(a);
      }
    }));
    var bar = SecurityContext.declare('?', SecurityContext.functionLiteral((a) {
      a ??= SecurityContext.nullLiteral();
      SecurityContext.checkParametersType([a], ['null']);
      {
        print(a);
      }
    }));
  }
}

var foo = SecurityContext.declare('?', SecurityContext.functionLiteral((a) {
  a ??= SecurityContext.nullLiteral();
  SecurityContext.checkParametersType([a], ['null']);
  {
    print(a);
  }
}));
var bar = SecurityContext.declare('?', SecurityContext.functionLiteral((a) {
  a ??= SecurityContext.nullLiteral();
  SecurityContext.checkParametersType([a], ['null']);
  {
    print(a);
  }
}));
