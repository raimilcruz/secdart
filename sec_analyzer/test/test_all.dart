import 'test_all_but_sec_checker.dart' as allButSecChecker;
import 'test_all_sec_checker.dart' as allSecChecker;

import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    //all but the security checker tests
    allButSecChecker.main();

    //security checker tests
    allSecChecker.main();
  });
}
