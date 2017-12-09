void main(){
  foo(()=>print("a"));
}
void foo (void f()) {
  f();
}