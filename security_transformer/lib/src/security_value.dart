import 'dart:mirrors';

class ErrorReporter {
  static void reportBadArgument(SecurityLabel parameterSecurityLabel,
      SecurityLabel argumentSecurityLabel) {
    throw new StateError(
        'Trying to give $argumentSecurityLabel argument to $parameterSecurityLabel parameter.');
  }

  static void reportBadAssignment(
      SecurityLabel variableSecurityLabel, SecurityLabel valueSecurityLabel) {
    throw new StateError(
        'Trying to assign $valueSecurityLabel value to $variableSecurityLabel variable.');
  }

  static void reportBadContextAssignment(
      SecurityLabel variableSecurityLabel, SecurityLabel pc) {
    throw new StateError(
        'Trying to assign $variableSecurityLabel variable in $pc context.');
  }

  static void reportBadReturnType(
      SecurityLabel staticSecurityLabel, SecurityLabel dynamicSecurityLabel) {
    throw new StateError(
        'Trying to return $dynamicSecurityLabel value with $staticSecurityLabel static return security label.');
  }
}

class SecurityContext {
  static SecurityLabel pc = new SecurityLabel('?');
  static final oldPcs = <int, SecurityLabel>{};

  static SecurityValue adjacentStrings(List<SecurityValue> securityValues) {
    final labels = securityValues.map((e) => e._dynamicSecurityLabel);
    final values = securityValues.map((e) => e._value);
    return new SecurityValue(values.join(''), dynamicJoinMultiple(labels));
  }

  static void assign(SecurityValue target, SecurityValue initializer) {
    if (target._staticSecurityLabel < pc) {
      ErrorReporter.reportBadContextAssignment(target._staticSecurityLabel, pc);
    }
    if (target._staticSecurityLabel < initializer._dynamicSecurityLabel) {
      ErrorReporter.reportBadAssignment(
          target._staticSecurityLabel, initializer._dynamicSecurityLabel);
    }
    target._dynamicSecurityLabel = dynamicJoin(
        target._staticSecurityLabel, initializer._dynamicSecurityLabel);
    target._value = initializer._value;
  }

  static SecurityValue ampersandAmpersandBinaryExpression(
          SecurityValue leftValue, SecurityValue rightValue) =>
      new SecurityValue(
          leftValue._value && rightValue._value,
          dynamicJoin(leftValue._dynamicSecurityLabel,
              rightValue._dynamicSecurityLabel));

  static SecurityValue bangEqualBinaryExpression(
          SecurityValue leftValue, SecurityValue rightValue) =>
      new SecurityValue(
          leftValue._value != rightValue._value,
          dynamicJoin(leftValue._dynamicSecurityLabel,
              rightValue._dynamicSecurityLabel));

  static SecurityValue barBarBinaryExpression(
          SecurityValue leftValue, SecurityValue rightValue) =>
      new SecurityValue(
          leftValue._value || rightValue._value,
          dynamicJoin(leftValue._dynamicSecurityLabel,
              rightValue._dynamicSecurityLabel));

  static SecurityValue equalEqualBinaryExpression(
          SecurityValue leftValue, SecurityValue rightValue) =>
      new SecurityValue(
          leftValue._value == rightValue._value,
          dynamicJoin(leftValue._dynamicSecurityLabel,
              rightValue._dynamicSecurityLabel));

  static SecurityValue questionQuestionBinaryExpression(
          SecurityValue leftValue, SecurityValue rightValue) =>
      new SecurityValue(
          leftValue._value ?? rightValue._value,
          dynamicJoin(leftValue._dynamicSecurityLabel,
              rightValue._dynamicSecurityLabel));

  static SecurityValue booleanLiteral(bool literal) {
    return new SecurityValue(
        literal,
        new SecurityLabel(pc.lowerBoundType,
            upperBoundType: pc.upperBoundType));
  }

  static void checkParametersType(
      List<SecurityValue> securityValues, List<String> labels) {
    final securityLabels = labels.map((e) => new SecurityLabel(e)).toList();
    for (var i = 0; i < securityValues.length; i++) {
      final securityValue = securityValues[i];
      final securityLabel = securityLabels[i];
      if (securityLabel < securityValue._dynamicSecurityLabel) {
        ErrorReporter.reportBadArgument(
            securityLabel, securityValue._dynamicSecurityLabel);
      }
    }
  }

  static SecurityValue checkReturnType(
      SecurityValue securityValue, String label) {
    final securityLabel = new SecurityLabel(label);
    if (securityLabel < securityValue._dynamicSecurityLabel) {
      ErrorReporter.reportBadReturnType(
          securityLabel, securityValue._dynamicSecurityLabel);
    }
    return securityValue;
  }

  static SecurityValue conditionalExpression(SecurityValue condition,
      SecurityValue thenFunction(), SecurityValue elseFunction()) {
    final result = condition._value ? thenFunction() : elseFunction();
    return new SecurityValue(
        result._value,
        dynamicJoin(
            condition._dynamicSecurityLabel, result._dynamicSecurityLabel));
  }

  static SecurityValue declare(String label, SecurityValue initializer) {
    final securityLabel = new SecurityLabel(label);
    final securityValue = new SecurityValue(null, securityLabel);
    assign(securityValue, initializer);
    return securityValue;
  }

  static SecurityValue doubleLiteral(double literal) {
    return new SecurityValue(
        literal,
        new SecurityLabel(pc.lowerBoundType,
            upperBoundType: pc.upperBoundType));
  }

  static SecurityLabel dynamicJoin(SecurityLabel label1, SecurityLabel label2) {
    final lowerBoundType = label1.lowerBoundValue >= label2.lowerBoundValue
        ? label1.lowerBoundType
        : label2.lowerBoundType;
    final upperBoundType = label1.upperBoundValue >= label2.upperBoundValue
        ? label1.upperBoundType
        : label2.upperBoundType;
    return new SecurityLabel(lowerBoundType, upperBoundType: upperBoundType);
  }

  static SecurityLabel dynamicJoinMultiple(Iterable<SecurityLabel> labels) {
    return labels.fold(new SecurityLabel('B'), dynamicJoin);
  }

  static bool evaluateConditionAndUpdatePc(SecurityValue condition, int pcKey) {
    oldPcs[pcKey] = pc;
    pc = dynamicJoin(pc, condition._dynamicSecurityLabel);
    return condition._value;
  }

  static SecurityValue functionLiteral(Function function) {
    return new SecurityValue(
        function,
        new SecurityLabel(pc.lowerBoundType,
            upperBoundType: pc.upperBoundType));
  }

  static SecurityValue integerLiteral(int literal) {
    return new SecurityValue(
        literal,
        new SecurityLabel(pc.lowerBoundType,
            upperBoundType: pc.upperBoundType));
  }

  static SecurityValue nullLiteral() {
    return new SecurityValue(
        null,
        new SecurityLabel(pc.lowerBoundType,
            upperBoundType: pc.upperBoundType));
  }

  static void recoverPc(int pcKey) {
    pc = oldPcs[pcKey];
  }

  static SecurityValue stringLiteral(String literal) {
    return new SecurityValue(
        literal,
        new SecurityLabel(pc.lowerBoundType,
            upperBoundType: pc.upperBoundType));
  }

  static SecurityValue instanceCreation(value) {
    return new SecurityValue(
        value,
        new SecurityLabel(pc.lowerBoundType,
            upperBoundType: pc.upperBoundType));
  }
}

class SecurityLabel {
  static final lattice = {
    'B': 0,
    'L': 1,
    'H': 2,
    'T': 3,
    '?': -1,
  };
  String lowerBoundType, upperBoundType;
  int lowerBoundValue, upperBoundValue;

  SecurityLabel(this.lowerBoundType, {this.upperBoundType}) {
    if (lowerBoundType == '?') {
      lowerBoundType = 'B';
      upperBoundType = 'T';
    } else {
      upperBoundType ??= lowerBoundType;
    }
    lowerBoundValue = SecurityLabel.lattice[lowerBoundType];
    upperBoundValue = SecurityLabel.lattice[upperBoundType];
  }

  bool operator <(SecurityLabel other) {
    return upperBoundValue < other.lowerBoundValue;
  }

  @override
  String toString() => '($lowerBoundType, $upperBoundType)';
}

class SecurityValue {
  dynamic _value;
  SecurityLabel _staticSecurityLabel;
  SecurityLabel _dynamicSecurityLabel;

  SecurityValue(this._value, this._staticSecurityLabel)
      : _dynamicSecurityLabel = _staticSecurityLabel;

  @override
  String toString() => '$_value';

  @override
  bool operator ==(other) => _value == other.value;

  int get hashcode => _value?.hashCode;

  Type get runtimeType => _value.runtimeType;

  @override
  noSuchMethod(Invocation invocation) {
    final propertyMirror = reflect(_value).getField(invocation.memberName);
    if (invocation.isGetter) {
      return propertyMirror.reflectee;
    }
    if (propertyMirror is ClosureMirror) {
      if (propertyMirror.function.isOperator) {
        if (invocation.positionalArguments.isEmpty) {
          return new SecurityValue(
              propertyMirror.apply([]).reflectee, this._dynamicSecurityLabel);
        } else {
          final argument = invocation.positionalArguments.first;
          return new SecurityValue(
              propertyMirror.apply([argument._value]).reflectee,
              SecurityContext.dynamicJoin(
                  _dynamicSecurityLabel, argument._dynamicSecurityLabel));
        }
      }
      List modifiedArguments = [this];
      modifiedArguments.addAll(invocation.positionalArguments);
      return propertyMirror
          .apply(modifiedArguments, invocation.namedArguments)
          .reflectee;
    }
    return null;
  }

  getField(String fieldName, {Type type}) {
    final symbol = fieldName.startsWith('_')
        ? type == null
            ? _lookUp(fieldName, _value.runtimeType)
            : _lookUp(fieldName, reflectClass(type))
        : new Symbol(fieldName);
    return reflect(_value).getField(symbol).reflectee;
  }

  invoke(String fieldName, List arguments, {Type type}) {
    List modifiedArguments = [this];
    modifiedArguments.addAll(arguments);
    final symbol = fieldName.startsWith('_')
        ? type == null
            ? _lookUp(fieldName, _value.runtimeType)
            : _lookUp(fieldName, reflectClass(type))
        : new Symbol(fieldName);
    return reflect(_value).invoke(symbol, modifiedArguments).reflectee;
  }
}

Symbol _lookUp(String memberName, ClassMirror classMirror) {
  final keyName = 'Symbol("$memberName")';
  for (final key in classMirror.declarations.keys) {
    if (keyName == key.toString()) {
      return key;
    }
  }
  return null;
}
