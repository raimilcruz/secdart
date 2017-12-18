import "package:secdart/secdart.dart";

void main() {
  @high int a = 3;
  int b = a;
  foo(b);
}

@latent("H", "L")
@low
int foo(@low int a) => a;
