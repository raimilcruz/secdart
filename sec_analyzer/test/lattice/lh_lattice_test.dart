import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/src/configuration.dart';

import '../../lib/src/security_label.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  LatticeConfig latticeConfig = LatticeConfig.defaultLattice;

  group('Static Flat Lattice tests :', () {
    SecDartConfig.init(latticeConfig);

    List<StaticLabel> staticLabels = [BotLabel, LowLabel, HighLabel, TopLabel];
    setUp(() {});
    int i = 0;
    staticLabels.forEach((value) {
      int j = 0;
      staticLabels.forEach((value2) {
        if (j >= i) {
          test(value.toString() + " < " + value2.toString(), () {
            expect(value.lessOrEqThan(value2), isTrue);
            expect(value.canRelabeledTo(value2), isTrue);
          });
          test(value.toString() + " join " + value2.toString(), () {
            expect(value.join(value2), value2);
          });
          test(value.toString() + " meet " + value2.toString(), () {
            expect(value.meet(value2), value);
          });
        }
        j++;
      });
      i++;
    });
  });

  group('Gradual Flat Lattice tests :', () {
    List<GradualLabel> staticLabels = [
      //Analyzer bug! It does not recognizes that GradualStaticLabel <: GradualLabel
      new GradualStaticLabel(BotLabel),
      new GradualStaticLabel(LowLabel),
      new GradualStaticLabel(HighLabel),
      new GradualStaticLabel(TopLabel),
      new DynamicLabel()
    ];
    var unknownLabel = new DynamicLabel();

    setUp(() {});

    //unknown < all
    staticLabels.forEach((value) {
      test("?" + " < " + value.toString(), () {
        expect(unknownLabel.lessOrEqThan(value), isTrue);
        expect(unknownLabel.canRelabeledTo(value), isTrue);
      });
    });

    // all < unknown
    staticLabels.forEach((value) {
      test(value.toString() + " < " + "?", () {
        expect(value.lessOrEqThan(unknownLabel), isTrue);
        expect(value.canRelabeledTo(unknownLabel), isTrue);
      });
    });
  });
}
