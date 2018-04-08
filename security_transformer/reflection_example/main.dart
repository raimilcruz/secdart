import 'Point.dart';
import 'dart:mirrors';

Symbol lookUp(Symbol memberName, ClassMirror classMirror) {
  for (final key in classMirror.declarations.keys) {
    if (memberName.toString() == key.toString()) {
      return key;
    }
  }
  return null;
}

class A {
  final point = new Point(0, 1);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final memberName = invocation.memberName;
    final classMirror = reflectClass(point.runtimeType);
    final trueSymbol = lookUp(memberName, classMirror);
    return reflect(point).getField(trueSymbol).reflectee;
  }
}

void main() {
  final a = new A();
  print(a._y); // I can access a private field!!
}
