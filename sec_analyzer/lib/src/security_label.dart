import 'dart:collection';

import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/src/configuration.dart';
import 'package:secdart_analyzer/src/options.dart';

abstract class ParametricSecurityLabel extends SecurityLabel {
  String get labelParameter;
}

abstract class JoinSecurityLabel extends SecurityLabel {
  SecurityLabel get left;

  SecurityLabel get right;
}

abstract class MeetSecurityLabel extends SecurityLabel {
  SecurityLabel get left;

  SecurityLabel get right;
}

/*class FourFlatLattice extends Lattice {
  FourFlatLattice._();

  factory FourFlatLattice() {
    return new FourFlatLattice._();
  }

  @override
  StaticLabel get bottom => new StaticLabelImpl("Bot");

  @override
  SecurityLabel get dynamic => new DynamicLabel();

  @override
  StaticLabel get top => new StaticLabelImpl("Top");
}

class IntervalLattice extends Lattice {
  Lattice underlineLattice;

  IntervalLattice(this.underlineLattice);

  @override
  StaticLabel get bottom =>
      new IntervalLabel(underlineLattice.bottom, underlineLattice.bottom);

  @override
  SecurityLabel get dynamic =>
      new IntervalLabel(underlineLattice.bottom, underlineLattice.top);

  @override
  StaticLabel get top =>
      new IntervalLabel(underlineLattice.top, underlineLattice.top);
}*/

/*
Labels for a flat lattice of 4 levels (BOT < LOW < HIGH < TOP)
 */

abstract class GradualLabel extends SecurityLabel {
  @override
  bool canRelabeledTo(SecurityLabel l) {
    return GradualFlatLatticeOperations.isLessOrEqualThan(this, l);
  }

  @override
  SecurityLabel join(SecurityLabel other) {
    return GradualFlatLatticeOperations.join(this, other);
  }

  @override
  SecurityLabel meet(SecurityLabel other) {
    return GradualFlatLatticeOperations.meet(this, other);
  }

  @override
  SecurityLabel substitute(
      List<String> labelParameter, List<String> securityLabels) {
    throw new UnimplementedError();
  }
}

class DynamicLabel extends GradualLabel {
  static DynamicLabel _instance = new DynamicLabel._internal();

  factory DynamicLabel() => _instance;

  DynamicLabel._internal();

  @override
  String toString() {
    return "?";
  }
}

class GradualStaticLabel extends GradualLabel {
  static Map<StaticLabel, GradualStaticLabel> _cache = {};
  StaticLabel staticLabel;

  factory GradualStaticLabel(StaticLabel label) {
    if (!_cache.containsKey(label)) {
      _cache[label] = new GradualStaticLabel._(label);
    }
    return _cache[label];
  }

  GradualStaticLabel._(this.staticLabel);

  @override
  String toString() => staticLabel.toString();
}

class IntervalLabel extends SecurityLabel {
  SecurityLabel lowerBound, upperBound;

  IntervalLabel(SecurityLabel lowerBound, SecurityLabel upperBound) {
    if (lowerBound is DynamicLabel || upperBound is DynamicLabel)
      throw new ArgumentError("Bounded unknow must have static label bounds");

    this.lowerBound = lowerBound;
    this.upperBound = upperBound;
  }

  @override
  String toString() {
    return "[" + lowerBound.toString() + "," + upperBound.toString() + "]";
  }

  @override
  bool operator ==(other) {
    return (other is IntervalLabel)
        ? lowerBound == other.lowerBound && upperBound == other.upperBound
        : false;
  }

  @override
  int get hashCode {
    return toString().hashCode;
  }

  @override
  bool canRelabeledTo(SecurityLabel l) {
    return IntervalLatticeOperations.lessThan(this, l);
  }

  @override
  SecurityLabel join(SecurityLabel other) {
    return IntervalLatticeOperations.join(this, other);
  }

  @override
  SecurityLabel meet(SecurityLabel other) {
    return IntervalLatticeOperations.meet(this, other);
  }

  @override
  SecurityLabel substitute(
      List<String> labelParameter, List<String> securityLabels) {
    throw new UnimplementedError();
  }

  String get representation => toString();
}

class FlatStaticLatticeOperations {
  //l1 < l2
  static bool isLessOrEqualThan(StaticLabel l1, StaticLabel l2) =>
      SecDartConfig.isLessOrEqualThan(l1.representation, l2.representation);

  static StaticLabel join(StaticLabel l1, StaticLabel l2) =>
      new StaticLabelImpl(
          SecDartConfig.join(l1.representation, l2.representation));

  static StaticLabel meet(StaticLabel l1, StaticLabel l2) =>
      new StaticLabelImpl(
          SecDartConfig.meet(l1.representation, l2.representation));
}

/**
 * Implementation of gradual label operations when the lattice contains
 * explicit [DynamicLabel]
 */
class GradualFlatLatticeOperations {
  static bool isLessOrEqualThan(GradualLabel l1, GradualLabel l2) {
    if (l1 is GradualStaticLabel && l2 is GradualStaticLabel) {
      return FlatStaticLatticeOperations.isLessOrEqualThan(
          l1.staticLabel, l2.staticLabel);
    }
    if (l1 is DynamicLabel || l2 is DynamicLabel) return true;
    return false;
  }

  static GradualLabel join(GradualLabel l1, GradualLabel l2) {
    if (l1 is GradualStaticLabel && l2 is GradualStaticLabel) {
      return new GradualStaticLabel(
          FlatStaticLatticeOperations.join(l1.staticLabel, l2.staticLabel));
    }
    if (l1 is DynamicLabel || l2 is DynamicLabel) return new DynamicLabel();
    return null;
  }

  static GradualLabel meet(GradualLabel l1, GradualLabel l2) {
    if (l1 is GradualStaticLabel && l2 is GradualStaticLabel) {
      return new GradualStaticLabel(
          FlatStaticLatticeOperations.meet(l1.staticLabel, l2.staticLabel));
    }
    if (l1 is DynamicLabel || l2 is DynamicLabel) return new DynamicLabel();
    return null;
  }
}

class IntervalLatticeOperations {
  static bool lessThan(IntervalLabel l1, IntervalLabel l2) {
    //if the lower bound of the second interval is strictly higher that
    //the upper bound.
    return l1.lowerBound.lessOrEqThan(l2.upperBound);
  }

  static IntervalLabel join(IntervalLabel l1, IntervalLabel l2) {
    return new IntervalLabel(
        l1.lowerBound.join(l2.lowerBound), l1.upperBound.join(l2.upperBound));
  }

  static IntervalLabel meet(IntervalLabel l1, IntervalLabel l2) {
    return new IntervalLabel(
        l1.lowerBound.join(l2.lowerBound), l1.upperBound.join(l2.upperBound));
  }
}

class StaticLabelImpl extends StaticLabel {
  static Map<String, StaticLabelImpl> _cache = {};

  String _representation;

  factory StaticLabelImpl(String representation) {
    if (!_cache.containsKey(representation)) {
      _cache[representation] = new StaticLabelImpl._(representation);
    }
    return _cache[representation];
  }

  StaticLabelImpl._(this._representation);

  @override
  bool canRelabeledTo(SecurityLabel l) {
    return FlatStaticLatticeOperations.isLessOrEqualThan(this, l);
  }

  @override
  SecurityLabel join(SecurityLabel other) {
    return FlatStaticLatticeOperations.join(this, other);
  }

  @override
  SecurityLabel meet(SecurityLabel other) {
    return FlatStaticLatticeOperations.meet(this, other);
  }

  @override
  SecurityLabel substitute(
      List<String> labelParameter, List<String> securityLabels) {
    throw new UnimplementedError();
  }

  @override
  String toString() {
    return representation;
  }

  @override
  bool operator ==(other) {
    if (other is StaticLabel) {
      return representation == other.representation;
    }
    return false;
  }

  @override
  int get hashCode {
    return representation.hashCode;
  }

  @override
  String get representation => _representation;
}

class IntervalLattice extends GradualLattice {
  LatticeConfig latticeConfig;

  IntervalLattice(this.latticeConfig);

  @override
  SecurityLabel get bottom => new IntervalLabel(
      new StaticLabelImpl(latticeConfig.bottom),
      new StaticLabelImpl(latticeConfig.bottom));

  @override
  SecurityLabel get dynamic => new IntervalLabel(
      new StaticLabelImpl(latticeConfig.bottom),
      new StaticLabelImpl(latticeConfig.top));

  @override
  SecurityLabel get top => new IntervalLabel(
      new StaticLabelImpl(latticeConfig.top),
      new StaticLabelImpl(latticeConfig.top));

  @override
  String get dynamicLiteralRepresentation => latticeConfig.unknown;

  @override
  SecurityLabel lift(StaticLabel staticLabelImpl) {
    return new IntervalLabel(staticLabelImpl, staticLabelImpl);
  }
}

class GradualLatticeWithUnknown extends GradualLattice {
  LatticeConfig latticeConfig;

  GradualLatticeWithUnknown(this.latticeConfig);

  @override
  SecurityLabel get bottom =>
      new GradualStaticLabel(new StaticLabelImpl(latticeConfig.bottom));

  @override
  SecurityLabel get dynamic => new DynamicLabel();

  @override
  SecurityLabel get top =>
      new GradualStaticLabel(new StaticLabelImpl(latticeConfig.top));

  @override
  String get dynamicLiteralRepresentation => latticeConfig.unknown;

  @override
  SecurityLabel lift(StaticLabel staticLabelImpl) {
    return new GradualStaticLabel(staticLabelImpl);
  }
}

class GraphLattice {
  // Adjacent list. If x <= y, then y is in the list of x.
  Map<String, int> _index;
  List<String> _elements;
  List<List<int>> _adjacencyList;
  List<List<int>> _inverseAdjacencyList;
  List<List<bool>> _adjacencyMatrix;
  List<List<int>> _meetTable;
  List<List<int>> _joinTable;
  List<List<String>> _adjacencyListUsingStrings;

  GraphLattice(List<String> elements, List<LabelOrder> relation) {
    _index = {};
    _elements = elements;
    _adjacencyList = new List.filled(elements.length, null);
    _inverseAdjacencyList = new List.filled(elements.length, null);
    _adjacencyMatrix = new List.filled(elements.length, null);
    _meetTable = new List.filled(elements.length, null);
    _joinTable = new List.filled(elements.length, null);
    _adjacencyListUsingStrings = new List.filled(elements.length, null);
    for (var i = 0; i < elements.length; i++) {
      String s = elements[i];
      if (_index.containsKey(s)) {
        throw new UnsupportedError(
            "The element $s is more than once in the lattice elements.");
      }
      _index[s] = i;
      _adjacencyList[i] = [];
      _inverseAdjacencyList[i] = [];
      _adjacencyMatrix[i] = new List.filled(elements.length, false);
      _adjacencyMatrix[i][i] = true;
      _meetTable[i] = new List.filled(elements.length, -1);
      _joinTable[i] = new List.filled(elements.length, -1);
      _adjacencyListUsingStrings[i] = [];
    }
    for (var edge in relation) {
      _addConnection(edge.s1, edge.s2);
    }
    // This is the Floyd-Warshall algorithm.
    for (var k = 0; k < elements.length; k++) {
      for (var i = 0; i < elements.length; i++) {
        for (var j = 0; j < elements.length; j++) {
          if (_adjacencyMatrix[i][k] && _adjacencyMatrix[k][j]) {
            _addConnectionWithoutChecking(elements[i], elements[j]);
          }
        }
      }
    }
    _computeMeetTable();
    _computeJoinTable();
  }

  void _check(String s) {
    if (!_index.containsKey(s)) {
      throw new UnsupportedError("The element $s is not part of the lattice.");
    }
  }

  void _addConnection(String s1, String s2) {
    _check(s1);
    _check(s2);
    _addConnectionWithoutChecking(s1, s2);
  }

  void _addConnectionWithoutChecking(String s1, String s2) {
    int u = _index[s1];
    int v = _index[s2];
    if (!_adjacencyMatrix[u][v]) {
      _adjacencyList[u].add(v);
      _inverseAdjacencyList[v].add(u);
      _adjacencyMatrix[u][v] = true;
      _adjacencyListUsingStrings[u].add(s2);
    }
  }

  Iterable<String> get vertices => _elements;

  Iterable<String> adjacentTo(String s) {
    _check(s);
    return _adjacencyListUsingStrings[_index[s]];
  }

  bool isLessOrEqualThan(String s1, String s2) {
    _check(s1);
    _check(s2);
    int u = _index[s1];
    int v = _index[s2];
    return _adjacencyMatrix[u][v];
  }

  void _computeMeetTable() {
    _computeTable(_meetTable, _adjacencyList, _inverseAdjacencyList);
  }

  void _computeJoinTable() {
    _computeTable(_joinTable, _inverseAdjacencyList, _adjacencyList);
  }

  void _computeTable(List<List<int>> table, List<List<int>> graph,
      List<List<int>> inverseGraph) {
    final q = new ListQueue<int>();
    List<int> inDegree = new List.filled(_elements.length, 0);
    for (var i = 0; i < _elements.length; i++) {
      inDegree[i] = inverseGraph[i].length;
      if (inDegree[i] == 0) {
        q.add(i);
      }
    }
    while (!q.isEmpty) {
      final u = q.removeFirst();
      List<int> reachableVertices = [u];
      for (final v in graph[u]) {
        reachableVertices.add(v);
        inDegree[v]--;
        if (inDegree[v] == 0) {
          q.add(v);
        }
      }
      for (final i in reachableVertices) {
        for (final j in reachableVertices) {
          table[i][j] = u;
        }
      }
    }
    for (var i = 0; i < _elements.length; i++) {
      for (var j = 0; j < _elements.length; j++) {
        if (table[i][j] == -1) {
          throw new UnsupportedError("The given graph is not a lattice.");
        }
      }
    }
  }

  String meet(String s1, String s2) {
    _check(s1);
    _check(s2);
    int u = _index[s1];
    int v = _index[s2];
    return _elements[_meetTable[u][v]];
  }

  String join(String s1, String s2) {
    _check(s1);
    _check(s2);
    int u = _index[s1];
    int v = _index[s2];
    return _elements[_joinTable[u][v]];
  }
}
