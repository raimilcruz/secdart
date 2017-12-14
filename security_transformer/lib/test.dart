import 'package:secdart/secdart.dart';

void main() {
  @high
  bool a = true;
  bool b = a;
  @low
  int x;
  @high
  int y;
  if (a)
    y = 1;
  else
    y = 0;
  if (a)
    y = 1;
  else
    y = 0;
  x = 0;
  print(x);
}
