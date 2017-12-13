import 'sec_analysis/bin_expr_test.dart' as bin_expr;
import 'sec_analysis/fun_call_test.dart' as fun_call;
import 'sec_analysis/fun_decl_test.dart' as function;
import 'sec_analysis/high_order_tests.dart' as high_order;
import 'sec_analysis/implicit_flow_tests.dart' as implicit;
import 'sec_analysis/identfier_tests.dart' as identifier;
import 'sec_analysis/ds_ecoop.dart' as ds_ecoop;

import 'lattice/lh_lattice_test.dart' as lattice;
import 'parser/annotation_test.dart' as parser;

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
    ds_ecoop.main();

  });
}