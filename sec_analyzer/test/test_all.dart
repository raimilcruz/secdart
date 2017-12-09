import 'bin-expr-tests.dart' as bin_expr;
import 'fun-call-tests.dart' as fun_call;
import 'function-tests.dart' as function;
import 'high-order-tests.dart' as high_order;
import 'implicit-flow-tests.dart' as implicit;

import 'lattice/lh-lattice-test.dart' as lattice;

import 'package:test_reflective_loader/test_reflective_loader.dart';


void main(){
  defineReflectiveSuite(() {
    bin_expr.main();
    fun_call.main();
    function.main();
    high_order.main();
    implicit.main();

    lattice.main();
  });
}