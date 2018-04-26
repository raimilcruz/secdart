class A {
  int _x;
  A() {
    _x = 0;
  }
}

int foo(A a) {
  return a._x;
}
