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
    return GradualFlatLatticeOperations.lessThan(this, l);
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
  static bool lessThan(StaticLabel l1, StaticLabel l2) {
    var il1 = topologicalOrderlabels().indexOf(l1.representation);
    var il2 = topologicalOrderlabels().indexOf(l2.representation);
    _assertIndexes(il1, il2);

    return il1 <= il2;
  }

  static StaticLabel join(StaticLabel l1, StaticLabel l2) {
    var il1 = topologicalOrderlabels().indexOf(l1.representation);
    var il2 = topologicalOrderlabels().indexOf(l2.representation);
    _assertIndexes(il1, il2);

    final joinIndex = _join(il1, il2);
    if (joinIndex <= -1) {
      throw new UnsupportedError(
          "Elements $l1 and $l2 do not represent a lattice");
    }
    return new StaticLabelImpl(topologicalOrderlabels()[joinIndex]);
  }

  static StaticLabel meet(StaticLabel l1, StaticLabel l2) {
    var il1 = topologicalOrderlabels().indexOf(l1.representation);
    var il2 = topologicalOrderlabels().indexOf(l2.representation);
    _assertIndexes(il1, il2);
    final meetIndex = _meet(il1, il2);
    if (meetIndex <= -1) {
      throw new UnsupportedError("Elements do not represent a lattice");
    }
    return new StaticLabelImpl(topologicalOrderlabels()[meetIndex]);
  }

  static int _join(int i1, int i2) {
    var candidateIndex = topologicalOrderlabels().length - 1;
    for (var i = candidateIndex; i >= 0; i--) {
      if (i1 <= i && i2 <= i) {
        candidateIndex = i;
      } else {
        return candidateIndex;
      }
    }
    return candidateIndex != topologicalOrderlabels().length
        ? candidateIndex
        : -1;
  }

  static int _meet(int i1, int i2) {
    var candidateIndex = 0;
    for (var i = candidateIndex; i < topologicalOrderlabels().length; i++) {
      if (i <= i1 && i <= i2) {
        candidateIndex = i;
      } else {
        return candidateIndex;
      }
    }
    return candidateIndex != 0 ? candidateIndex : -1;
  }

  static List<String> topologicalOrderlabels() {
    return SecDartConfig.latticeTopologicalSort();
  }

  static void _assertIndexes(il1, il2) {
    assert(il1 >= 0);
    assert(il2 >= 0);
  }
}

/**
 * Implementation of gradual label operations when the lattice contains
 * explicit [DynamicLabel]
 */
class GradualFlatLatticeOperations {
  static bool lessThan(GradualLabel l1, GradualLabel l2) {
    if (l1 is GradualStaticLabel && l2 is GradualStaticLabel) {
      return FlatStaticLatticeOperations.lessThan(
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
    return FlatStaticLatticeOperations.lessThan(this, l);
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
  //adjacent list. If x <= y, then y is in the list of x.
  Map<String, List<String>> _connections;
  List<String> _topologicalSort;

  GraphLattice(List<String> elements, List<LabelOrder> relation) {
    _connections = {};
    for (String s in elements) {
      _connections.putIfAbsent(s, () => []);
    }
    for (var order in relation) {
      _addConnection(order.s1, order.s2);
    }
  }

  void _addConnection(String s1, String s2) {
    if (!_connections.containsKey(s1)) {
      throw new UnsupportedError("This element is not part of the lattice");
    }
    if (!_connections[s1].contains(s2)) {
      _connections[s1].add(s2);
    }
  }

  Iterable<String> get vertices => _connections.keys;

  Iterable<String> adjacentTo(String vertex) => _connections[vertex];

  List<String> topSort() {
    if (_topologicalSort == null) {
      _DFSState result = new _DFSState();
      for (var vertex in vertices) {
        if (!result.parent.containsKey(vertex)) {
          result.parent[vertex] = null;
          _dfs(vertex, result);
        }
      }
      List<String> sort = new List<String>(vertices.length);
      result.time.forEach((s, t) => sort[t] = s);
      _topologicalSort = sort.reversed.toList();
    }
    return _topologicalSort;
  }

  void _dfs(String startVertex, _DFSState state) {
    for (var vertex in adjacentTo(startVertex)) {
      if (!state.parent.containsKey(vertex)) {
        state.parent.putIfAbsent(vertex, () => startVertex);
        _dfs(vertex, state);
      }
    }
    state.time.putIfAbsent(startVertex, () => state.dfsCallCounter);
    state.dfsCallCounter++;
  }
}

class _DFSState {
  Map<String, String> parent = {};
  Map<String, int> time = {};
  int dfsCallCounter = 0;
}
