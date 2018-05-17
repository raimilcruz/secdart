import 'package:security_transformer/src/security_value.dart';

class Point {
  dynamic _x = SecurityContext.declare('?', SecurityContext.nullLiteral());
  dynamic y = SecurityContext.declare('?', SecurityContext.nullLiteral());
  Point(this._x, this.y);
  void _foo() {
    SecurityContext.checkParametersType([], []);
    {
      print(_x);
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
    a.invoke('_foo', [], type: Point);
  }
}
