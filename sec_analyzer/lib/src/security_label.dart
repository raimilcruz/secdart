/**
 * 
 */



/**
 * Abstract class to represent a security label
 */
abstract class SecurityLabel
{
  /**
   * When is implemented in a derived class returns a boolean value indicating if the current label can flow to the specific label
   */
  bool canRelabeledTo(SecurityLabel l);
  /**
   * When is implemented in a derived class returns the meet 
   */
  SecurityLabel meet(SecurityLabel other);
  /**
   * When is implemented in a derived class returns the join
   */
  SecurityLabel join(SecurityLabel other);

  bool lessOrEqThan(SecurityLabel other){
    return this.canRelabeledTo(other);
  }
}

/*
Labels for a flat lattice of 4 levels (BOT < LOW < HIGH < TOP)
 */

/**
 * Implements common operations for the label of the lattice
 */
class FlatLabel extends SecurityLabel{

  @override
  bool canRelabeledTo(SecurityLabel l) {
    return FlatLatticeOperations.lessThan(this,l);
  }

  @override
  SecurityLabel join(SecurityLabel other) {
    return FlatLatticeOperations.join(this,other);
  }

  @override
  SecurityLabel meet(SecurityLabel other) {
    return FlatLatticeOperations.meet(this, other);
  }
}
class HighLabel extends FlatLabel{

  @override
  String toString() {
    return "H";
  }
}
class LowLabel extends FlatLabel{
  @override
  String toString() {
    return "L";
  }
}
class TopLabel extends FlatLabel{
  static TopLabel _instance;
  factory TopLabel(){
    if(_instance==null)
      _instance = new TopLabel._internal();
    return _instance;
  }

  TopLabel._internal();

  @override
  String toString() {
    return "Top";
  }
}
class BotLabel extends FlatLabel{
  static BotLabel _instance;
  factory BotLabel(){
    if(_instance==null)
      _instance = new BotLabel._internal();
    return _instance;
  }

  BotLabel._internal();

  @override
  String toString() {
    return "Bot";
  }
}
abstract class UnknownLabel extends FlatLabel{

}
class DynamicLabel extends UnknownLabel{
  static DynamicLabel _instance;
  factory DynamicLabel(){
    if(_instance == null){
      _instance = new DynamicLabel._internal();
    }
    return _instance;
  }
  @override
  String toString() {
    return "?";
  }
  DynamicLabel._internal();
}
class IntervalLabel extends UnknownLabel{
  FlatLabel lowerBound,upperBound;
  IntervalLabel(FlatLabel lowerBound, FlatLabel upperBound){
    if(lowerBound is DynamicLabel || upperBound is DynamicLabel)
      throw new ArgumentError("Bounded unknow must have static label bounds");

    this.lowerBound = lowerBound;
    this.upperBound= upperBound;
  }

  @override
  String toString() {
    return "[" + lowerBound.toString() + "," + upperBound.toString() +  "]";
  }
}

class FlatStaticLatticeOperations{
  static List<String> labels = ["Bot","L","H","Top"];

  //l1 < l2
  static bool lessThan(FlatLabel l1, FlatLabel l2){
    if(l1 is! UnknownLabel && l2 is! UnknownLabel) {
      var il1 = labels.indexOf(l1.toString());
      var il2 = labels.indexOf(l2.toString());
      return il1 <= il2;
    }
    throw new ArgumentError("invalid arguments");
  }
  static FlatLabel join(FlatLabel l1, FlatLabel l2){
    if(l1 is! UnknownLabel && l2 is! UnknownLabel) {
      var il1 = labels.indexOf(l1.toString());
      var il2 = labels.indexOf(l2.toString());
      if (il1 < il2) {
        return l2;
      }
      else {
        return l1;
      }
    }
    throw new ArgumentError("invalid arguments");
  }
  static FlatLabel meet(FlatLabel l1, FlatLabel l2){
    if(l1 is! UnknownLabel && l2 is! UnknownLabel) {
      var il1 = labels.indexOf(l1.toString());
      var il2 = labels.indexOf(l2.toString());
      if (il1 < il2) {
        return l1;
      }
      else {
        return l2;
      }
    }
    throw new ArgumentError("invalid arguments");
  }
}
class FlatLatticeOperations{
  static bool lessThan(FlatLabel l1, FlatLabel l2){
    if(l1 is! UnknownLabel && l2 is! UnknownLabel) {
      return FlatStaticLatticeOperations.lessThan(l1,l2);
    }
    checkConflict(l1,l2);
    if(l1 is DynamicLabel || l2 is DynamicLabel)
      return true;
    //here we know that we have intervals
    var il1 = intervalizeLabel(l1);
    var il2 = intervalizeLabel(l2);

    //if the lower bound of the second interval is strictly higher that
    //the upper bound.
    /*return !(il2.upperBound.lessOrEqThan(il1.lowerBound)
              && il2.upperBound == il1.lowerBound);*/
    return il1.lowerBound.lessOrEqThan(il2.upperBound);
  }
  static FlatLabel join(FlatLabel l1, FlatLabel l2){
    if(l1 is! UnknownLabel && l2 is! UnknownLabel) {
      return FlatStaticLatticeOperations.join(l1,l2);
    }
    checkConflict(l1,l2);
    if(l1 is DynamicLabel || l2 is DynamicLabel)
      return new DynamicLabel();

    //here we know that we have intervals
    var il1 = intervalizeLabel(l1);
    var il2 = intervalizeLabel(l2);

    return new IntervalLabel(il1.lowerBound.join(il2.lowerBound),il1.upperBound.join(il2.upperBound));
  }
  static FlatLabel meet(FlatLabel l1, FlatLabel l2){
    if(l1 is! UnknownLabel && l2 is! UnknownLabel) {
      return FlatStaticLatticeOperations.meet(l1,l2);
    }
    checkConflict(l1,l2);
    if(l1 is DynamicLabel || l2 is DynamicLabel)
      return new DynamicLabel();

    //here we know that we have intervals
    var il1 = intervalizeLabel(l1);
    var il2 = intervalizeLabel(l2);

    return new IntervalLabel(il1.lowerBound.join(il2.lowerBound),il1.upperBound.join(il2.upperBound));
  }

  static checkConflict(FlatLabel l1, FlatLabel l2){
    if( (l1 is DynamicLabel && l2 is IntervalLabel) ||
        (l2 is DynamicLabel && l1 is IntervalLabel)){
      throw new ArgumentError("Cannot operate over different kinds of unknown labels");
    }
  }
  static IntervalLabel intervalizeLabel(FlatLabel label){
    if(label is! UnknownLabel){
      return new IntervalLabel(label,label);
    }
    if(label is DynamicLabel){//I just fix this. Is not correct to merge both semantics of the unknown label
      return new IntervalLabel(new BotLabel(),new TopLabel());
    }
    return label;
  }
}