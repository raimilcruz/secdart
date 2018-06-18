class A {
  int _x;
  int y;

  A(this._x, this.y);

  void _foo() {
    print(_x);
  }

  void bar() {
    print(y);
  }
}

void main() {
  final a = new A(0, 1);
  print(a._x);
  print(a.y);
  a._foo();
  a.bar();
}
