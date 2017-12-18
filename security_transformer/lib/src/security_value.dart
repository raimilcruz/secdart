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
    final labels = securityValues.map((e) => e.dynamicSecurityLabel);
    final values = securityValues.map((e) => e.value);
    return new SecurityValue(values.join(''), dynamicJoinMultiple(labels));
  }

  static void assign(SecurityValue target, SecurityValue initializer) {
    if (target.staticSecurityLabel < pc) {
      ErrorReporter.reportBadContextAssignment(target.staticSecurityLabel, pc);
    }
    if (target.staticSecurityLabel < initializer.dynamicSecurityLabel) {
      ErrorReporter.reportBadAssignment(
          target.staticSecurityLabel, initializer.dynamicSecurityLabel);
    }
    target.dynamicSecurityLabel = dynamicJoin(
        target.staticSecurityLabel, initializer.dynamicSecurityLabel);
    target.value = initializer.value;
  }

  static SecurityValue binaryExpression(SecurityValue leftLambda(),
      SecurityValue rightLambda(), String operator) {
    SecurityValue result = new SecurityValue(null, new SecurityLabel('b'));
    result.value = _interpretBinaryExpression(() {
      final securityValue = leftLambda();
      result.dynamicSecurityLabel = dynamicJoin(
          result.dynamicSecurityLabel, securityValue.dynamicSecurityLabel);
      return securityValue.value;
    }, () {
      final securityValue = rightLambda();
      result.dynamicSecurityLabel = dynamicJoin(
          result.dynamicSecurityLabel, securityValue.dynamicSecurityLabel);
      return securityValue.value;
    }, operator);
    return result;
  }

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
      if (securityLabel < securityValue.dynamicSecurityLabel) {
        ErrorReporter.reportBadArgument(
            securityLabel, securityValue.dynamicSecurityLabel);
      }
    }
  }

  static checkReturnType(SecurityValue securityValue, String label) {
    final securityLabel = new SecurityLabel(label);
    if (securityLabel < securityValue.dynamicSecurityLabel) {
      ErrorReporter.reportBadReturnType(
          securityLabel, securityValue.dynamicSecurityLabel);
    }
  }

  static SecurityValue conditionalExpression(SecurityValue condition,
      SecurityValue thenFunction(), SecurityValue elseFunction()) {
    final result = condition.value ? thenFunction() : elseFunction();
    return new SecurityValue(
        result.value,
        dynamicJoin(
            condition.dynamicSecurityLabel, result.dynamicSecurityLabel));
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
    pc = dynamicJoin(pc, condition.dynamicSecurityLabel);
    return condition.value;
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

  static dynamic _interpretBinaryExpression(
      dynamic leftLambda(), dynamic rightLambda(), String operator) {
    if (operator == 'QUESTION_QUESTION') {
      return leftLambda() ?? rightLambda();
    } else if (operator == 'AMPERSAND') {
      return leftLambda() & rightLambda();
    } else if (operator == 'AMPERSAND_AMPERSAND') {
      return leftLambda() && rightLambda();
    } else if (operator == 'AMPERSAND') {
      return leftLambda() & rightLambda();
    } else if (operator == 'BANG_EQ') {
      return leftLambda() != rightLambda();
    } else if (operator == 'BAR') {
      return leftLambda() | rightLambda();
    } else if (operator == 'BAR_BAR') {
      return leftLambda() || rightLambda();
    } else if (operator == 'CARET') {
      return leftLambda() ^ rightLambda();
    } else if (operator == 'EQ_EQ') {
      return leftLambda() == rightLambda();
    } else if (operator == 'GT') {
      return leftLambda() > rightLambda();
    } else if (operator == 'GT_EQ') {
      return leftLambda() >= rightLambda();
    } else if (operator == 'GT_GT') {
      return leftLambda() >> rightLambda();
    } else if (operator == 'LT') {
      return leftLambda() < rightLambda();
    } else if (operator == 'LT_EQ') {
      return leftLambda() <= rightLambda();
    } else if (operator == 'LT_LT') {
      return leftLambda() << rightLambda();
    } else if (operator == 'MINUS') {
      return leftLambda() - rightLambda();
    } else if (operator == 'PERCENT') {
      return leftLambda() % rightLambda();
    } else if (operator == 'PLUS') {
      return leftLambda() + rightLambda();
    } else if (operator == 'STAR') {
      return leftLambda() * rightLambda();
    } else if (operator == 'SLASH') {
      return leftLambda() / rightLambda();
    } else if (operator == 'TILDE_SLASH') {
      return leftLambda() ~/ rightLambda();
    } else if (operator == 'QUESTION_QUESTION') {
      return leftLambda() ?? rightLambda();
    }
    return null;
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
  dynamic value;
  SecurityLabel staticSecurityLabel;
  SecurityLabel dynamicSecurityLabel;
  SecurityValue(this.value, this.staticSecurityLabel)
      : dynamicSecurityLabel = staticSecurityLabel;

  @override
  String toString() => '($value, $staticSecurityLabel, $dynamicSecurityLabel)';
}
