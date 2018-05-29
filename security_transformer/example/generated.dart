import 'package:security_transformer/src/security_value.dart';

class Point {
  dynamic _x = SecurityContext.declare('?', SecurityContext.nullLiteral());
  dynamic y = SecurityContext.declare('?', SecurityContext.nullLiteral());
  Point(this._x, this.y);
  void _foo(SecurityValue thisSecurityValue, dynamic n) {
    n ??= SecurityContext.nullLiteral();
    SecurityContext.checkParametersType([n], ['?']);
    {
      print(_x);
      {
        if (SecurityContext.evaluateConditionAndUpdatePc(
            SecurityContext.binaryExpression(
                () => n, () => SecurityContext.integerLiteral(0), 'BANG_EQ'),
            0)) {
          thisSecurityValue.invoke(
              '_foo',
              [
                SecurityContext.binaryExpression(
                    () => n, () => SecurityContext.integerLiteral(1), 'MINUS')
              ],
              type: Point);
        }
        SecurityContext.recoverPc(0);
      }
    }
  }
}

void main() {
  SecurityContext.checkParametersType([], []);
  {
    final a = SecurityContext.declare(
        '?',
        SecurityContext.instanceCreation(new Point(
            SecurityContext.integerLiteral(0), SecurityContext.nullLiteral())));
    print(a.getField('_x', type: Point));
    print(a.getField('y'));
    a.invoke('_foo', [SecurityContext.integerLiteral(3)], type: Point);
  }
}
