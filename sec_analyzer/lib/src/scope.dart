import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';

//TODO: Reuse Scope hierarchy at package:analyzer/lib/src/dart/resolver/scope.dart
abstract class SecurityScope<T> {
  bool isDefined(String name);
  T lookup(String name);
  void define(String name, T elem);
  SecurityScope<T> get enclosingScope;
  AnalysisError getErrorForDuplicate(String existing, Element duplicate) {
    Source source = duplicate.source;
    return new AnalysisError(source, duplicate.nameOffset, duplicate.nameLength,
        CompileTimeErrorCode.DUPLICATE_DEFINITION, [existing]);
  }
}

class EmptySecurityScope<T> extends SecurityScope<T> {
  @override
  bool isDefined(String name) {
    return false;
  }

  @override
  void define(String name, T elem) {
    throw new UnsupportedError("EmptySecurityScope.define");
  }

  @override
  T lookup(String name) {
    throw new UnsupportedError("EmptySecurityScope.lookup");
  }

  @override
  SecurityScope<T> get enclosingScope => null;
}

class NestedSecurityScope<T> extends SecurityScope<T> {
  SecurityScope<T> _enclosingScope;
  Map<String, T> names;

  NestedSecurityScope(this._enclosingScope) {
    names = new Map();
  }

  @override
  bool isDefined(String name) {
    return names.containsKey(name);
  }

  @override
  void define(String name, T elem) {
    if (!names.containsKey(name)) {
      names[name] = elem;
    }
  }

  @override
  T lookup(String name) {
    if (names.containsKey(name)) return names[name];
    return enclosingScope.lookup(name);
  }

  // TODO: implement enclosingScope
  @override
  SecurityScope<T> get enclosingScope => _enclosingScope;
}

class SecurityFunctionScope<T> extends NestedSecurityScope<T> {
  FunctionElement element;
  SecurityFunctionScope(SecurityScope enclosingScope, this.element)
      : super(enclosingScope);
}
