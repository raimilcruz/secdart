import "package:secdart/secdart.dart";

void main() {
  @high int a = 3;
  foo(a);
}

@latent("H", "L")
@low
int foo(int a) => a;
