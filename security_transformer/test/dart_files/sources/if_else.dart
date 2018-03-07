import 'package:secdart/secdart.dart';

void main() {
  @low
  int a;
  @high
  bool b = true;
  if (b) {
    a = 1;
  } else {
    print('hi');
  }
}
