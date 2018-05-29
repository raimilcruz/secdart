import 'package:security_transformer/src/security_value.dart';

class A {
  dynamic _x = SecurityContext.declare('?', SecurityContext.nullLiteral());
  dynamic y = SecurityContext.declare('?', SecurityContext.nullLiteral());
  A(this._x, this.y);
  void _foo(SecurityValue thisSecurityValue) {
    SecurityContext.checkParametersType([], []);
    {
      print(_x);
    }
  }

  void bar(SecurityValue thisSecurityValue) {
    SecurityContext.checkParametersType([], []);
    {
      print(y);
    }
  }
}

void main() {
  SecurityContext.checkParametersType([], []);
  {
    final a = SecurityContext.declare(
        '?',
        SecurityContext.instanceCreation(new A(
            SecurityContext.integerLiteral(0),
            SecurityContext.integerLiteral(1))));
    print(a.getField('_x', type: A));
    print(a.y);
    a.invoke('_foo', [], type: A);
    a.bar();
  }
}
