import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'student.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class StudentPage {
  const StudentPage(this.students, this.current, this.last);
  final List<Student> students;
  final int current, last;
}

abstract class StudentRepository {
  Future<StudentPage> list({int page = 1});
  Future<Student> get(int id);
  Future<Student> save(Student student, {required bool isNew});
  Future<void> delete(int id);
}

class StudentApi implements StudentRepository {
  StudentApi({required String baseUrl, http.Client? client})
    : _base = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
      _client = client ?? http.Client();
  final String _base;
  final http.Client _client;
  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
  Uri _uri(String path) => Uri.parse('$_base/$path');
  Future<http.Response> _send(Future<http.Response> Function() send) async {
    try {
      return await send().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException(
        'The server timed out. Check the API address and try again.',
      );
    } on http.ClientException {
      throw ApiException(
        'Cannot connect to Laravel. Check the API address and server.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'The server returned an invalid response (${response.statusCode}).',
      );
    }
    if (response.statusCode >= 400) {
      final errors = body['errors'];
      final detail = errors is Map
          ? errors.values.expand((v) => v is List ? v : [v]).join('\n')
          : null;
      throw ApiException(
        detail ??
            body['message']?.toString() ??
            'Request failed (${response.statusCode}).',
      );
    }
    return body;
  }

  @override
  Future<StudentPage> list({int page = 1}) async {
    final body = _decode(
      await _send(
        () => _client.get(_uri('students?page=$page'), headers: _headers),
      ),
    );
    final meta = body['meta'] as Map<String, dynamic>;
    return StudentPage(
      (body['data'] as List)
          .map((e) => Student.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta['current_page'] as int,
      meta['last_page'] as int,
    );
  }

  @override
  Future<Student> get(int id) async {
    final body = _decode(
      await _send(() => _client.get(_uri('students/$id'), headers: _headers)),
    );
    return Student.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<Student> save(Student student, {required bool isNew}) async {
    final response = await _send(
      () => isNew
          ? _client.post(
              _uri('students'),
              headers: _headers,
              body: jsonEncode(student.toJson()),
            )
          : _client.put(
              _uri('students/${student.id}'),
              headers: _headers,
              body: jsonEncode(student.toJson()),
            ),
    );
    return Student.fromJson(_decode(response)['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> delete(int id) async {
    final response = await _send(
      () => _client.delete(_uri('students/$id'), headers: _headers),
    );
    if (response.statusCode != 204) {
      _decode(response);
      throw ApiException('Expected an empty 204 delete response.');
    }
  }
}
