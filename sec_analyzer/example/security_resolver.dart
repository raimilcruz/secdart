import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:secdart_analyzer/analyzer.dart';

void main() {
  SecAnalyzer a = new SecAnalyzer();
  var program = '''
         import "package:secdart/secdart.dart";
         @latent("H","L")
         @high int foo (@high int a1, @low int a2) {
            @low var a = a1 + a2;
            return 1;
          }
      ''';
  var result = a.analyze(program);
  if (result.errors.isNotEmpty) {
    print("The security analysis computes the following errors:");
    result.errors.forEach(print);
  }

  print("Here is the resulting AST:");

  var printer = new _PrintSecurityTypeVisitor();
  result.astNode.accept(printer);
}

class _PrintSecurityTypeVisitor extends GeneralizingAstVisitor<Object> {
  int spaces = 0;
  _PrintSecurityTypeVisitor() : super();

  @override
  Object visitNode(AstNode node) {
    var prefix = getStringSpaces();
    print("$prefix ${node.runtimeType}");
    if(node.getProperty("sec-type")!=null) {
      print("$prefix Sec type: ${node.getProperty("sec-type")}");
    }
    spaces += 2;
    var x = super.visitNode(node);
    spaces -= 2;
    return x;
  }

  String getStringSpaces() {
    String res = "";
    for (int i = 0; i < spaces; i++) {
      res += "-";
    }
    return res;
  }
}
