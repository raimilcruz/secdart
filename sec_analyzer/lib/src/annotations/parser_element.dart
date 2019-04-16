import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/annotations/external_library.dart';
import 'package:secdart_analyzer/src/annotations/parser.dart';
import 'package:secdart_analyzer/src/app_config.dart';
import 'package:secdart_analyzer/src/security_label.dart';
import 'package:secdart_analyzer/src/security_type.dart';

///Resolve security for program entities.
abstract class SecurityElementResolver {
  /**
   * A general representation of the lattice this parser parses
   */
  GradualLattice get lattice;

  /**
   * Returns the security type associated to this element. We assume that
   * the element has a metadata property.
   */
  SecurityType fromIdentifierDeclaration(Element element, DartType type);

  ///Returns the a [PreSecurityType] from a [DartType].
  PreSecurityType fromDartType(DartType type);

  SecurityFunctionElement getSecurityFunction(FunctionElement element);

  SecurityMethodElement getSecurityMethod(MethodElement element);

  SecurityPropertyAccessorElement getSecurityPropertyAccessor(
      PropertyAccessorElement element);

  SecurityClassElement getSecurityClass(ClassElement element);

  SecurityConstructorElement getSecurityConstructor(
      ConstructorElement constructor);

  /// Returns a boolean value if the element belongs to a library
  /// that imported "secdart"
  bool _elementIsDefinedInSecDartLibrary(Element element) {
    if (element.library == null) {
      return false;
    }
    return !(element is DynamicElementImpl) &&
        element.library.imports.any((import) =>
            import.uri != null ? import.uri.contains("secdart.dart") : false);
  }

  bool _isVoidType(DartType type) {
    return (type is VoidType);
  }

  /**
   * Lifting of label node to gradual labels
   */
  SecurityLabel labelNodeToLabelElement(LabelNode node) {
    if (node is NoAnnotatedLabel) {
      return lattice.dynamic;
    }
    if (node.literalRepresentation == lattice.dynamicLiteralRepresentation) {
      return lattice.dynamic;
    } else {
      //lift the label representation to the lattice
      return lattice.lift(new StaticLabelImpl(node.literalRepresentation));
    }
  }
}

class DispatcherSecurityElementResolver extends SecurityElementResolver {
  SecDartElementResolver secDartResolver;
  ExternalLibraryResolver nonSecDartResolver;
  SecurityCache _securityMap;

  DispatcherSecurityElementResolver(
      this.secDartResolver, this.nonSecDartResolver, this._securityMap) {
    nonSecDartResolver.dispatcherResolver = this;
    secDartResolver.dispatcherResolver = this;
  }

  @override
  PreSecurityType fromDartType(DartType type) {
    if (_securityMap.typeCache.containsKey(type)) {
      if (AppConfiguration.defaultConfig().isDebug)
        print("security type for $type obtained from cache");
      return _securityMap.typeCache[type];
    }
    if (_isVoidType(type)) {
      return nonSecDartResolver.fromDartType(type);
    }
    final secType = (_elementIsDefinedInSecDartLibrary(type.element))
        ? secDartResolver.fromDartType(type)
        : nonSecDartResolver.fromDartType(type);

    //function type are structural (ie. they are not nominal)
    if (!(type is FunctionType)) {
      _securityMap.typeCache.putIfAbsent(type, () => secType);
    }
    return secType;
  }

  @override
  SecurityType fromIdentifierDeclaration(Element element, DartType type) {
    return secDartResolver.fromIdentifierDeclaration(element, type);
  }

  @override
  SecurityClassElement getSecurityClass(ClassElement element) {
    if (!_securityMap.map.containsKey(element)) {
      final securityElement = _elementIsDefinedInSecDartLibrary(element)
          ? secDartResolver.getSecurityClass(element)
          : nonSecDartResolver.getSecurityClass(element);
      _securityMap.map.putIfAbsent(element, () => securityElement);
    }
    return _securityMap.map[element];
  }

  @override
  SecurityConstructorElement getSecurityConstructor(
      ConstructorElement element) {
    if (!_securityMap.map.containsKey(element)) {
      final securityElement = _elementIsDefinedInSecDartLibrary(element)
          ? secDartResolver.getSecurityConstructor(element)
          : nonSecDartResolver.getSecurityConstructor(element);

      _securityMap.map.putIfAbsent(element, () => securityElement);
    }
    return _securityMap.map[element];
  }

  @override
  SecurityFunctionElement getSecurityFunction(FunctionElement element) {
    if (!_securityMap.map.containsKey(element)) {
      final securityFunctionElement = _elementIsDefinedInSecDartLibrary(element)
          ? secDartResolver.getSecurityFunction(element)
          : nonSecDartResolver.getSecurityFunction(element);

      _securityMap.map.putIfAbsent(element, () => securityFunctionElement);
    }
    return _securityMap.map[element];
  }

  @override
  SecurityMethodElement getSecurityMethod(MethodElement element) {
    if (!_securityMap.map.containsKey(element)) {
      final securityMethod = _elementIsDefinedInSecDartLibrary(element)
          ? secDartResolver.getSecurityMethod(element)
          : nonSecDartResolver.getSecurityMethod(element);

      _securityMap.map.putIfAbsent(element, () => securityMethod);
    }
    return _securityMap.map[element];
  }

  @override
  SecurityPropertyAccessorElement getSecurityPropertyAccessor(
      PropertyAccessorElement property) {
    if (!_securityMap.map.containsKey(property)) {
      SecurityPropertyAccessorElement securityElement =
          _elementIsDefinedInSecDartLibrary(property)
              ? secDartResolver.getSecurityPropertyAccessor(property)
              : nonSecDartResolver.getSecurityPropertyAccessor(property);

      _securityMap.map.putIfAbsent(property, () => securityElement);
    }
    return _securityMap.map[property];
  }

  @override
  GradualLattice get lattice => secDartResolver.lattice;
}

class SecDartElementResolver extends SecurityElementResolver {
  DispatcherSecurityElementResolver dispatcherResolver;
  SecAnnotationParser _parser;
  SecurityCache _securityMap;
  LabelMap _labelMap;
  GradualLattice _lattice;

  SecDartElementResolver(
      CompilationUnit unit,
      SecAnnotationParser annotationParser,
      SecurityCache securityMap,
      LabelMap labelMap,
      GradualLattice lattice) {
    _securityMap = securityMap;
    _labelMap = labelMap;
    _parser = annotationParser;
    _lattice = lattice;
  }

  GradualLattice get lattice => _lattice;

  PreSecurityType fromDartType(DartType type) {
    PreSecurityType result = new PreDynamicTypeImpl();

    if (type is InterfaceType) {
      result = new PreInterfaceTypeImpl(
          dispatcherResolver.getSecurityClass(type.element));
    }
    //if it is a function type is should be defined as type alias
    else if (type is FunctionType) {
      if (_isDeclaredAsTypeAlias(type)) {
        return _fromFunctionTypeAlias(type.element.enclosingElement);
      }
      //in this case we do not have type annotations
      PreSecurityType returnType =
          dispatcherResolver.fromDartType(type.returnType);
      return new PreFunctionTypeImpl(
        lattice.dynamic,
        type.parameters
            .map((t) => dispatcherResolver.fromIdentifierDeclaration(t, t.type))
            .toList(),
        returnType.toSecurityType(lattice.dynamic),
      );
    }
    return result;
  }

  /**
   * Given an element (with annotations) (eg. parameter, variable declaration)
   * returns its security type.
   */
  SecurityType fromIdentifierDeclaration(Element element, DartType type) {
    //get the label ascribed via annotations
    var label = _getSecurityLabel(element, element.metadata);
    return dispatcherResolver
        .fromDartType(type)
        .toSecurityType(labelNodeToLabelElement(label));
  }

  PreFunctionType _fromFunctionTypeAlias(FunctionTypeAliasElement element) {
    if (!_elementIsDefinedInSecDartLibrary(element)) {
      throw new ArgumentError("We expect a SecDart type alias");
    }
    //take the security annotation from the typedef
    //TODO: Define an annotation from function in type alias.
    final functionSecType = _getFunctionSecType(
        element,
        element.metadata.map((m) => (m as ElementAnnotationImpl).annotationAst),
        element.parameters,
        element.returnType);
    return new PreFunctionTypeImpl(functionSecType.beginLabel,
        functionSecType.argumentTypes, functionSecType.returnType);
  }

  bool _isDeclaredAsTypeAlias(FunctionType type) {
    return type.element.enclosingElement is FunctionTypeAliasElement;
  }

  @override
  SecurityFunctionElement getSecurityFunction(FunctionElement element) {
    if (!_securityMap.map.containsKey(element)) {
      var metadataList = element.metadata
          .map((m) => (m as ElementAnnotationImpl).annotationAst);
      final functionType = _getFunctionSecType(
          element, metadataList, element.parameters, element.returnType);

      _securityMap.map.putIfAbsent(element,
          () => new SecurityFunctionElementImpl(element, functionType));
    }
    return _securityMap.map[element];
  }

  @override
  SecurityMethodElement getSecurityMethod(MethodElement element) {
    if (!_securityMap.map.containsKey(element)) {
      var metadataList = element.metadata
          .map((m) => (m as ElementAnnotationImpl).annotationAst);
      final functionType = _getFunctionSecType(
          element, metadataList, element.parameters, element.returnType);

      _securityMap.map.putIfAbsent(
          element, () => new SecurityMethodElementImpl(element, functionType));
    }
    return _securityMap.map[element];
  }

  @override
  getSecurityConstructor(ConstructorElement element) {
    if (!_securityMap.map.containsKey(element)) {
      var metadataList = element.metadata
          .map((m) => (m as ElementAnnotationImpl).annotationAst);
      final functionType = _getFunctionSecType(
          element, metadataList, element.parameters, element.returnType);

      _securityMap.map.putIfAbsent(element,
          () => new SecurityConstructorElementImpl(element, functionType));
    }
    return _securityMap.map[element];
  }

  @override
  SecurityPropertyAccessorElement getSecurityPropertyAccessor(
      PropertyAccessorElement property) {
    if (!_securityMap.map.containsKey(property)) {
      SecurityPropertyAccessorElement securityElement;

      final functionType = _getFunctionSecType(
          property,
          property.metadata
              .map((m) => (m as ElementAnnotationImpl).annotationAst),
          property.parameters,
          property.type.returnType);

      if (property.isSynthetic) {
        SecurityLabel label = labelNodeToLabelElement(
            _getSecurityLabel(property.variable, property.variable.metadata));
        if (property.isGetter) {
          functionType.returnType.label = label;
        }
        //property.isSetter
        else {
          functionType.argumentTypes.first.label = label;
        }
      }
      securityElement =
          new SecurityPropertyAccessorElementImpl(property, functionType);

      _securityMap.map.putIfAbsent(property, () => securityElement);
    }
    return _securityMap.map[property];
  }

  @override
  SecurityClassElement getSecurityClass(ClassElement element) {
    if (_securityMap.map.containsKey(element)) {
      return _securityMap.map[element];
    }

    final classType = element.type;
    final result = new SecurityClassElementImpl(this, classType);

    _securityMap.map.putIfAbsent(classType.element, () => result);

    classType.methods.forEach((mElement) {
      var metadataList = mElement.metadata
          .map((m) => (m as ElementAnnotationImpl).annotationAst);
      result.methods.putIfAbsent(
          mElement.name,
          () => _getFunctionSecType(mElement, metadataList, mElement.parameters,
              mElement.returnType));
    });

    classType.accessors.forEach((property) {
      //it means the getter or setter was generated from a field
      result.accessors.putIfAbsent(property.name,
          () => getSecurityPropertyAccessor(property).propertyType);
    });

    classType.constructors.forEach((cElement) {
      var metadataList = cElement.metadata
          .map((m) => (m as ElementAnnotationImpl).annotationAst);
      result.constructors.putIfAbsent(
          cElement.name,
          () => _getFunctionSecType(cElement, metadataList, cElement.parameters,
              cElement.returnType));
    });

    return result;
  }

  SecurityFunctionType _getFunctionSecType(
      Element element,
      Iterable<Annotation> metadataList,
      List<ParameterElement> parameters,
      DartType returnType) {
    var functionLevelLabels = _functionLevelLabels(element);
    if (!_elementIsDefinedInSecDartLibrary(element)) {
      throw new UnimplementedError("This method should not call on non-secdart"
          "elements");
    }
    var returnLabel = labelNodeToLabelElement(functionLevelLabels.returnLabel);
    var beginLabel =
        labelNodeToLabelElement(functionLevelLabels.functionLabels.beginLabel);
    var endLabel =
        labelNodeToLabelElement(functionLevelLabels.functionLabels.endLabel);

    var parameterSecTypes = new List<SecurityType>();
    for (ParameterElement p in parameters) {
      parameterSecTypes.add(fromIdentifierDeclaration(p, p.type));
    }
    var returnSecurityType =
        fromDartType(returnType).toSecurityType(returnLabel);
    return new SecurityFunctionTypeImpl(
        beginLabel, parameterSecTypes, returnSecurityType, endLabel);
  }

  /**
   * Returns the function level labels. First, we try to get those label
   * from the label cache.
   */
  FunctionLevelLabels _functionLevelLabels(FunctionTypedElement element) {
    if (!(element is FunctionElement ||
        element is MethodElement ||
        element is FunctionTypeAliasElement ||
        element is ConstructorElement ||
        element is PropertyAccessorElement)) {
      throw new ArgumentError(
          "Element must be either a FunctionElement or a MethodElement");
    }
    //asking if this function was already visited by the parser in this
    //case we can get labels from the label cache
    if (!_labelMap.map.containsKey(element)) {
      final functionLevelLabels = _parser.getFunctionLevelLabels(element
          .metadata
          .map((m) => (m as ElementAnnotationImpl).annotationAst)
          .toList());
      _labelMap.map.putIfAbsent(element, () => functionLevelLabels);
    }
    return _labelMap.map[element] as FunctionLevelLabels;
  }

  LabelNode _getSecurityLabel(
      dynamic element, List<ElementAnnotation> metadata) {
    if (_labelMap.map.containsKey(element)) {
      if (AppConfiguration.defaultConfig().isDebug)
        print("label from label cache");
      //TODO: Process null label properly. We obtain a null label when there
      //is no label annotation.
      final annotatedLabel = _labelMap.map[element] as SimpleAnnotatedLabel;
      return annotatedLabel.label ?? new NoAnnotatedLabel();
    }

    var secLabelAnnotations = metadata
        .map((e) => (e as ElementAnnotationImpl).annotationAst)
        .where((x) => _parser.isLabel(x));
    LabelNode label = new NoAnnotatedLabel();
    if (secLabelAnnotations.length == 1) {
      label = _parser.parseLabel(secLabelAnnotations.first);
    }

    _labelMap.map.putIfAbsent(element, () => new SimpleAnnotatedLabel(label));
    return label;
  }
}

///This class is used to resolve security annotations
///for non-SecDart libraries. It reads the library annotation
///file to provide annotations.
class ExternalLibraryResolver extends SecurityElementResolver {
  DispatcherSecurityElementResolver _dispatcherResolver;
  GradualLattice lattice;
  SecurityCache _securityMap;

  ExternalLibraryResolver(this.lattice, this._securityMap);

  set dispatcherResolver(DispatcherSecurityElementResolver resolver) {
    _dispatcherResolver = resolver;
  }

  ///TODO: We should have a set of rule (DSL) to specific how
  ///we want to treat labels of external libraries:
  ///a) Inputs are high, returns are low.
  ///b) Are implicitly parametric. The result of invoking a method
  ///with parameter e1...en is: join label(ei).
  ///c) Inputs and output are dynamic
  ///d) Certain method has a concrete signature, such as print.
  /* FunctionLevelLabels _functionLevelLabels(Element element) {
    return new FunctionLevelLabels(
        new LabelNodeImpl(lattice.bottom.representation),
        new FunctionAnnotationLabel(
            new LabelNodeImpl(lattice.bottom.representation),
            new LabelNodeImpl(lattice.bottom.representation)));
  }*/

  @override
  PreSecurityType fromDartType(DartType type) {
    if (_securityMap.typeCache.containsKey(type)) {
      if (AppConfiguration.defaultConfig().isDebug)
        print("security type for $type obtained from cache");
      return _securityMap.typeCache[type];
    }

    PreSecurityType result = new PreDynamicTypeImpl();

    if (type is InterfaceType) {
      result = new PreInterfaceTypeImpl.forExternalClass(
          _dispatcherResolver.getSecurityClass(type.element));
    } else if (type is FunctionType) {
      //TODO: Improve this. the element of this type defines
      //how we get the type (from the DSL)
      final secType = _securityFunctionType(type);
      result = new PreFunctionTypeImpl(
          secType.beginLabel, secType.argumentTypes, secType.returnType);
    }
    _securityMap.typeCache.putIfAbsent(type, () => result);
    return result;
  }

  @override
  SecurityType fromIdentifierDeclaration(Element element, DartType type) {
    throw new UnsupportedError("Method fromIdentifierDeclaration should not be"
        "called on a ExternalLibraryResolver instance");
  }

  @override
  SecurityClassElement getSecurityClass(ClassElement element) {
    if (_securityMap.map.containsKey(element)) {
      return _securityMap.map[element];
    }

    final classType = element.type;
    //we are lazy regarding the resolution of security for non-SecDart
    // libraries
    final result = new SecurityClassElementImpl(this, classType);

    _securityMap.map.putIfAbsent(classType.element, () => result);
    return result;
  }

  @override
  SecurityConstructorElement getSecurityConstructor(
      ConstructorElement constructor) {
    return new SecurityConstructorElementImpl(
        constructor, _securityFunctionType(constructor.type));
  }

  @override
  SecurityFunctionElement getSecurityFunction(FunctionElement element) {
    SecurityFunctionType securityFunctionType;
    //TODO: remove this. At the moment, it is a rapid way to give
    //a function from dart.core.
    if (element is FunctionElement &&
        element.library.name.contains("dart.core")) {
      //read annotation from dsl file
      securityFunctionType =
          ExternalLibraryAnnotations.getSecTypeForFunction(element, this);
    } else {
      securityFunctionType = _securityFunctionType(element.type);
    }
    return new SecurityFunctionElementImpl(element, securityFunctionType);
  }

  @override
  SecurityMethodElement getSecurityMethod(MethodElement element) {
    return new SecurityMethodElementImpl(
        element, _securityFunctionType(element.type));
  }

  @override
  SecurityPropertyAccessorElement getSecurityPropertyAccessor(
      PropertyAccessorElement element) {
    //TODO: check this implementation
    SecurityFunctionType securityAccessorType;
    if (element.isGetter) {
      securityAccessorType = new SecurityFunctionTypeImpl.forExternalFunction(
          lattice.bottom,
          [],
          fromDartType(element.type.returnType).toSecurityType(lattice.bottom),
          lattice.bottom);
    } else {
      securityAccessorType = new SecurityFunctionTypeImpl.forExternalFunction(
          lattice.bottom,
          [
            fromDartType(element.type.parameters.first.type)
                .toSecurityType(lattice.top)
          ],
          fromDartType(element.type.returnType).toSecurityType(lattice.bottom),
          lattice.bottom);
    }
    return new SecurityPropertyAccessorElementImpl(
        element, securityAccessorType);
  }

  SecurityFunctionType _securityFunctionType(FunctionType type) {
    //TODO: use DSL this is unsound.
    return new SecurityFunctionTypeImpl.forExternalFunction(
        lattice.top,
        type.parameters
            .map((p) => _dispatcherResolver
                .fromDartType(p.type)
                .toSecurityType(lattice.top))
            .toList(),
        _dispatcherResolver
            .fromDartType(type.returnType)
            .toSecurityType(lattice.bottom),
        lattice.bottom);
  }
}
