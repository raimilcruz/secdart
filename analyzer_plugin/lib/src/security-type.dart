import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'security_label.dart';


abstract class SecurityType extends DartType{
  SecurityType();



  // The name given to the type. Some types do not have names, such as function types or generic types
  @override
  String get displayName => null;

  // TODO: implement element
  @override
  Element get element => null;

  @override
  DartType flattenFutures(TypeSystem typeSystem) {
    throw new UnimplementedError("SecurityType.flattenFutures");
  }

  @override
  bool get isDartAsyncFuture => false;


  @override
  bool get isDartCoreFunction => false;

  @override
  bool get isVoid => false;



  SecurityLabel get label;
  void set label(SecurityLabel s);

}

class GroundSecurityType extends SecurityType {
  SecurityLabel _label;
  DartType internalType;

  GroundSecurityType(this.internalType, SecurityLabel securityLabel) {
    _label =securityLabel;
  }

  @override
  bool isAssignableTo(DartType type) {
    // TODO: implement isAssignableTo
  }

  // TODO: implement isBottom
  @override
  bool get isBottom => null;

  // TODO: implement isDynamic
  @override
  bool get isDynamic => null;

  @override
  bool isMoreSpecificThan(DartType type) {
    // TODO: implement isMoreSpecificThan
  }

  // TODO: implement isObject
  @override
  bool get isObject => null;

  @override
  bool isSubtypeOf(DartType type) {
    // TODO: implement isSubtypeOf
  }

  @override
  bool isSupertypeOf(DartType type) {
    // TODO: implement isSupertypeOf
  }

  // TODO: implement isUndefined
  @override
  bool get isUndefined => null;


  // TODO: implement name
  @override
  String get name => null;

  @override
  DartType resolveToBound(DartType objectType) {
    // TODO: implement resolveToBound
  }

  @override
  DartType substitute2(List<DartType> argumentTypes,
      List<DartType> parameterTypes) {
    // TODO: implement substitute2
  }

  // TODO: implement label
  @override
  SecurityLabel get label => this._label;

  @override
  void set label(SecurityLabel s) {
    _label =s;
  }
  // TODO: implement isDartAsyncFutureOr
  @override
  bool get isDartAsyncFutureOr => null;

  // TODO: implement isDartCoreNull
  @override
  bool get isDartCoreNull => null;
}

//TODO: extends from SecurityType
class SecurityFunctionType extends SecurityType {
  SecurityType _returnType;
  List<SecurityType> _argumentTypes;
  SecurityLabel _beginLabel;
  SecurityLabel _endLabel;
  SecurityFunctionType(this._beginLabel,List<SecurityType> argumentTypes,SecurityType returnType,this._endLabel)
  {
    _returnType =returnType;
    _argumentTypes = argumentTypes;
    label = endLabel;
  }


  SecurityType get returnType => _returnType;
  SecurityLabel get beginLabel => _beginLabel;
  SecurityLabel get endLabel => _endLabel;
  List<SecurityType> get argumentTypes => _argumentTypes;



  @override
  bool isAssignableTo(DartType type) {
    // TODO: implement isAssignableTo
  }

  // TODO: implement isBottom
  @override
  bool get isBottom => null;

  // TODO: implement isDynamic
  @override
  bool get isDynamic => null;

  @override
  bool isMoreSpecificThan(DartType type) {
    // TODO: implement isMoreSpecificThan
  }

  // TODO: implement isObject
  @override
  bool get isObject => null;

  @override
  bool isSubtypeOf(DartType type) {
    // TODO: implement isSubtypeOf
  }

  @override
  bool isSupertypeOf(DartType type) {
    // TODO: implement isSupertypeOf
  }

  // TODO: implement isUndefined
  @override
  bool get isUndefined => null;

  // TODO: implement name
  @override
  String get name => null;

  @override
  DartType resolveToBound(DartType objectType) {
    // TODO: implement resolveToBound
  }

  @override
  DartType substitute2(List<DartType> argumentTypes, List<DartType> parameterTypes) {
    // TODO: implement substitute2
  }


  @override
  SecurityLabel label;
  // TODO: implement isDartAsyncFutureOr
  @override
  bool get isDartAsyncFutureOr => false;

  // TODO: implement isDartCoreNull
  @override
  bool get isDartCoreNull => false;
}

