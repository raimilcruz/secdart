/**
 * To run test in this file you need to run a server at
 * [serverUrl]
 */

import 'dart:convert';

import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

final String serverUrl = "http://localhost:8282";
final String program = '''
         import "package:secdart/secdart.dart";
         @latent("H","L")
         @high int foo (@high int a1, @low int a2) {
            @low var a = a1 + a2;
            return 1;
          }
      ''';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WebApiTest);
  });
}

@reflectiveTest
class WebApiTest {
  void test_analyze() {
    final String url = '${serverUrl}/api/secdartapi/v1/analyze';
    Map headers = {'Content-Type': 'application/json', 'charset': 'UTF-8'};

    Map body = {"source": program, "useInterval": false};
    String bodyText = JSON.encode(body);

    expect(
        http.post(url, headers: headers, body: bodyText).then((response) {
          expect(response.statusCode, 200);
          expect(true, response.body.length > 100);
          final result = JSON.decode(response.body);
          expect(result["issues"], isNotNull);
          return true;
        }),
        completion(equals(true)));
  }

  void test_compile() {
    final String url = '${serverUrl}/api/secdartapi/v1/compile';
    Map headers = {'Content-Type': 'application/json', 'charset': 'UTF-8'};

    Map body = {"source": program, "useInterval": false};
    String bodyText = JSON.encode(body);

    expect(
        http.post(url, headers: headers, body: bodyText).then((response) {
          expect(response.statusCode, 200);
          expect(true, response.body.length > 100);
          final result = JSON.decode(response.body);
          expect(result["compiled"], isNotNull);
          return true;
        }),
        completion(equals(true)));
  }
}
