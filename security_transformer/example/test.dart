import "package:secdart/secdart.dart";

void main() {
  @low int a = 3;
  print(foo(a));
}

@latent("H", "L")
@low
int foo(int a) => a;
