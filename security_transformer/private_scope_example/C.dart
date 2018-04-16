import 'A.dart';
import 'B.dart';

void main() {
  final b = new B();
  print(foo(
      b)); // imprime 0, el _x definido en A, si usamos el runtime type imprimiriamos 1.
}
