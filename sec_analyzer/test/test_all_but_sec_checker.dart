import 'lattice/lh_lattice_test.dart' as lattice;
import 'parser/annotation_test.dart' as parser;
import 'parser/custom_lattice_test.dart' as custom_parser;

import 'unsupported_features_tests.dart' as unsupported;

import 'resolver/bin_expr_test.dart' as resolver_binExpr;
import 'resolver/identifier_and_top_decl_test.dart' as resolver_identifiers;
import 'resolver/variable_declaration.dart' as resolver_variable;
import 'resolver/literals_and_instances_test.dart' as resolver_values;
import 'resolver/pc_test.dart' as resolver_pc;
import 'resolver/class_declaration_test.dart' as resolver_classDeclaration;
import 'resolver/high_order_test.dart' as resolver_highOrder;

import 'analysis_client_test.dart' as client;
import 'option_test.dart' as option;

import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    //lattice operation tests
    lattice.main();
    //security parsing tests
    parser.main();
    //parser a configurable lattice
    custom_parser.main();

    //unsupported features tests
    unsupported.main();

    //resolver security tests
    resolver_identifiers.main();
    resolver_binExpr.main();
    resolver_variable.main();
    resolver_values.main();
    resolver_pc.main();
    resolver_classDeclaration.main();
    resolver_highOrder.main();

    client.main();
    //tests configurable option properties for the plugin
    option.main();
  });
}
