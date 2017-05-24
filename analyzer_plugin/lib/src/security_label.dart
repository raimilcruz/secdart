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

  bool lestThan(SecurityLabel other){
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
class DynamicLabel extends FlatLabel{
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

/**
 * Implements lattice operations: join and meet for the "flat" lattice 
 */
class FlatLatticeOperations{
  static List<String> labels = ["Bot","L","H","Top"];

  //l1 < l2
  static bool lessThan(FlatLabel l1, FlatLabel l2){
    if(l1 is! DynamicLabel && l2 is! DynamicLabel) {
      var il1 = labels.indexOf(l1.toString());
      var il2 = labels.indexOf(l2.toString());
      return il1 <= il2;
    }
    return true;
  }
  static FlatLabel join(FlatLabel l1, FlatLabel l2){
    if(l1 is! DynamicLabel && l2 is! DynamicLabel) {
      var il1 = labels.indexOf(l1.toString());
      var il2 = labels.indexOf(l2.toString());
      if (il1 < il2) {
        return l2;
      }
      else {
        return l1;
      }
    }
    return new DynamicLabel();
  }
  static FlatLabel meet(FlatLabel l1, FlatLabel l2){
    if(l1 is! DynamicLabel && l2 is! DynamicLabel) {
      var il1 = labels.indexOf(l1.toString());
      var il2 = labels.indexOf(l2.toString());
      if (il1 < il2) {
        return l1;
      }
      else {
        return l2;
      }
    }
    return new DynamicLabel();
  }
}
