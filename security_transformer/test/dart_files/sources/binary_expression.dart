import "package:secdart/secdart.dart";

void foo() {
  @low
  int a = 3 + 4 * 2 - 5;
  @low
  bool b = true && false;
}
