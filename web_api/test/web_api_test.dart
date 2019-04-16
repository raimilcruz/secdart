/**
 * To run test in this file you need to run a server at
 * [serverUrl]
 */

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'harness/app.dart';

final String serverUrl = "http://localhost:8888";
final String program = '''
         import "package:secdart/secdart.dart";
         @latent("H","L")
         @high int foo (@high int a1, @low int a2) {
            @low var a = a1 + a2;
            return 1;
          }
      ''';

//class WebApiTest {
//  void test_analyze() {
//    final String url = '${serverUrl}/secdartapi/analyze';
//    Map headers = {'Content-Type': 'application/json', 'charset': 'UTF-8'};
//
//    Map body = {"source": program, "useInterval": false};
//    String bodyText = json.encode(body);
//
//    expect(
//        http.post(url, headers: headers, body: bodyText).then((response) {
//          expect(response.statusCode, 200);
//          expect(true, response.body.length > 100);
//          final result = json.decode(response.body);
//          expect(result["issues"], isNotNull);
//          return true;
//        }),
//        completion(equals(true)));
//  }
//
//  void test_compile() {
//    final String url = '${serverUrl}/secdartapi//compile';
//    Map headers = {'Content-Type': 'application/json', 'charset': 'UTF-8'};
//
//    Map body = {"source": program, "useInterval": false};
//    String bodyText = json.encode(body);
//
//    expect(
//        http.post(url, headers: headers, body: bodyText).then((response) {
//          expect(response.statusCode, 200);
//          expect(true, response.body.length > 100);
//          final result = json.decode(response.body);
//          expect(result["compiled"], isNotNull);
//          return true;
//        }),
//        completion(equals(true)));
//  }
//}

void main() {
  final harness = Harness()..install();

  test("POST /analyze returns 200 OK", () async {
    var response = await harness.agent.post("/secdartapi/analyze",
        body: {"source": program, "useInterval": false});
    expectResponse(response, 200);
  });

  test("POST /compile returns 200 OK", () async {
    var response = await harness.agent.post("/secdartapi/compile",
        body: {"source": program, "useInterval": false});
    expectResponse(response, 200);
  });
}
