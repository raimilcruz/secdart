import 'sec_analysis/bin-expr-tests.dart' as bin_expr;
import 'sec_analysis/fun-call-tests.dart' as fun_call;
import 'sec_analysis/function-tests.dart' as function;
import 'sec_analysis/high-order-tests.dart' as high_order;
import 'sec_analysis/implicit-flow-tests.dart' as implicit;
import 'sec_analysis/identfier_tests.dart' as identifier;

import 'lattice/lh-lattice-test.dart' as lattice;
import 'parser/annotation-tests.dart' as parser;

import  'unsupported_features_tests.dart' as unsupported;

import 'package:test_reflective_loader/test_reflective_loader.dart';


void main(){
  defineReflectiveSuite(() {
    //lattice operation tests
    lattice.main();
    //security parsing tests
    parser.main();

    //unsupported features tests
    unsupported.main();

    //security analysis tests
    bin_expr.main();
    fun_call.main();
    function.main();
    high_order.main();
    implicit.main();
    identifier.main();


  });
}