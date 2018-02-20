import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

bool isDeclassifyOperator(SimpleIdentifier functionNode) {
  if (functionNode.staticElement is FunctionElement) {
    return (functionNode.staticElement.name == "declassify"
        //&& functionNode.staticElement.library.name.contains("secdart")
        );
  }
  return false;
}
