class Point {
  int _x;
  Point y;

  Point(this._x, this.y);

  void _foo(int n) {
    print(_x);
    if (n != 0) {
      _foo(n - 1);
    }
  }
}

void main() {
  final a = new Point(0, null);
  print(a._x);
  print(a.y);
  a._foo(3);
}
