import 'package:security_transformer/src/security_value.dart';

class A {
  dynamic _x = SecurityContext.declare('?', SecurityContext.nullLiteral());
  dynamic y = SecurityContext.declare('?', SecurityContext.nullLiteral());
  A(this._x, this.y);
  void _foo() {
    SecurityContext.checkParametersType([], []);
    {
      print(_x);
    }
  }

  void bar() {
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
    print(a.getField('y'));
    a.invoke('_foo', [], type: A);
    a.invoke('bar', []);
  }
}
