import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_student_management_ci/student.dart';
import 'package:flutter_student_management_ci/student_api.dart';

const student = Student(
  id: 1,
  number: 'STU-001',
  name: 'Sokha Demo',
  email: 'sokha@example.com',
  course: 'DevOps',
);
Map<String, dynamic> record() => {'id': 1, ...student.toJson()};
StudentApi api(Future<http.Response> Function(http.Request) handler) =>
    StudentApi(
      baseUrl: 'http://example.test/api/',
      client: MockClient(handler),
    );
void main() {
  test('list uses Laravel pagination and Accept header', () async {
    final service = api((request) async {
      expect(request.url.path, '/api/students');
      expect(request.url.queryParameters['page'], '2');
      expect(request.headers['Accept'], 'application/json');
      return http.Response(
        jsonEncode({
          'data': [record()],
          'meta': {'current_page': 2, 'last_page': 3},
        }),
        200,
      );
    });
    final page = await service.list(page: 2);
    expect(page.students.single.name, 'Sokha Demo');
    expect(page.last, 3);
  });
  test('get unwraps Laravel data', () async {
    final service = api((r) async {
      expect(r.url.path, '/api/students/1');
      return http.Response(jsonEncode({'data': record()}), 200);
    });
    expect((await service.get(1)).id, 1);
  });
  test('create sends POST with student_number and handles 201', () async {
    final service = api((r) async {
      expect(r.method, 'POST');
      expect(jsonDecode(r.body)['student_number'], 'STU-001');
      return http.Response(jsonEncode({'data': record()}), 201);
    });
    expect((await service.save(student, isNew: true)).id, 1);
  });
  test('update sends PUT to student endpoint', () async {
    final service = api((r) async {
      expect(r.method, 'PUT');
      expect(r.url.path, '/api/students/1');
      return http.Response(jsonEncode({'data': record()}), 200);
    });
    await service.save(student, isNew: false);
  });
  test('delete handles empty 204 without decoding JSON', () async {
    final service = api((r) async {
      expect(r.method, 'DELETE');
      return http.Response('', 204);
    });
    await service.delete(1);
  });
  test('422 exposes Laravel validation errors', () async {
    final service = api(
      (r) async => http.Response(
        jsonEncode({
          'errors': {
            'email': ['The email has already been taken.'],
          },
        }),
        422,
      ),
    );
    await expectLater(
      service.save(student, isNew: true),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('already been taken'),
        ),
      ),
    );
  });
  test('404 exposes server message', () async {
    final service = api(
      (r) async => http.Response('{"message":"Student not found"}', 404),
    );
    await expectLater(service.get(999), throwsA(isA<ApiException>()));
  });
  test('invalid server response is understandable', () async {
    final service = api((r) async => http.Response('<html>Error</html>', 500));
    await expectLater(service.list(), throwsA(isA<ApiException>()));
  });
  test('network failure is understandable', () async {
    final service = api((r) async => throw http.ClientException('offline'));
    await expectLater(
      service.list(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Cannot connect'),
        ),
      ),
    );
  });
}
