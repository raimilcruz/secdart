class Point {
  int _x;
  Point y;

  Point(this._x, this.y);

  void _foo() {
    print(_x);
  }
}

void main() {
  final a = new Point(0, null);
  print(a._x);
  print(a.y);
  a._foo();
}
