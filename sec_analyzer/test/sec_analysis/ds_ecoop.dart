import '../test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import "package:secdart_analyzer/src/errors.dart";

/**
 * This file contains the five programs that were presented in the proposal
 * at the Doctoral Symposium @ ECOOP 2016.
 *
 * Each program is tested in both modes: strict and flexible.
 */
void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrictModeTest);
    defineReflectiveTests(FlexibleModeTest);
  });
}

@reflectiveTest
class StrictModeTest extends AbstractSecDartTest {
  void test_ecoopds_1() {
    var program = EcoopDsPaperExamples.first();
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: true);

    assert(result.any((e) => e.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }

  void test_ecoopds_2() {
    var program = EcoopDsPaperExamples.second();
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: true);
    assert(result.any((e) => e.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }

  void test_ecoopds_3() {
    var program = EcoopDsPaperExamples.third();
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: true);
    assert(result.any((e) => e.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }

  void test_ecoopds_4() {
    var program = EcoopDsPaperExamples.fourth();
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: true);
    assert(result.any((e) => e.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }

  void test_ecoopds_5() {
    var program = EcoopDsPaperExamples.fifth();
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: true);

    assert(result.any((e) => e.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }
}

@reflectiveTest
class FlexibleModeTest extends AbstractSecDartTest {
  void test_ecoopds_1() {
    var program = EcoopDsPaperExamples.first();
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: false);

    assert(result.any((e) => e.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }

  void test_ecoopds_2() {
    var program = EcoopDsPaperExamples.second();
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: false);

    assert(!containsInvalidFlow(result));
  }

  void test_ecoopds_3() {
    var program = EcoopDsPaperExamples.third();
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: false);

    assert(!containsInvalidFlow(result));
  }

  void test_ecoopds_4() {
    var program = EcoopDsPaperExamples.fourth();
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: false);

    assert(result.any((e) => e.errorCode == SecurityErrorCode.EXPLICIT_FLOW));
  }

  void test_ecoopds_5() {
    var program = EcoopDsPaperExamples.fifth();
    var source = newSource("/test.dart", program);
    var result = typeCheckSecurityForSource(source, intervalMode: false);

    assert(!containsInvalidFlow(result));
  }
}

class EcoopDsPaperExamples {
  static String first() => '''
    import "package:secdart/secdart.dart";
    printSalary(@low bool isTheBoss) {
      @high var salary = 18000;
      @low var baseSalary = 12000;
      print(isTheBoss ? salary : baseSalary);
    }
  ''';
  static String second() => '''
    import "package:secdart/secdart.dart";
    main(){
      bool isBoss = true;
      @high int BobSalary = 18000;
      int baseSalary = 12000;
      print(isBoss ? BobSalary : baseSalary);
    }
  ''';
  static String third() => '''
    import "package:secdart/secdart.dart";

    printSalary(bool isTheBoss) {
      @high var salary = 18000;
      @high var baseSalary = 12000;
      print(isTheBoss ? salary : baseSalary);
    }
  ''';
  static String fourth() => '''
    import "package:secdart/secdart.dart";

    @low discount(@low int s){
      return (s * 80)/100;
    }
    
    printSalary(bool isTheBoss) {
      @high var bobSalary = 18000;
      var baseSalary = 12000;
      print(isTheBoss ? discount(bobSalary) : baseSalary);
    }
  ''';
  static String fifth() => '''
    import "package:secdart/secdart.dart";

    printSalary(bool isTheBoss) {
      @high var salary = 18000;
      @high var baseSalary = 12000;
      print(isTheBoss ? salary : baseSalary);
    }
  ''';
}
