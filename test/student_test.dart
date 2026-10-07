import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_student_management_ci/student.dart';

void main() {
  test('Laravel JSON maps to student fields', () {
    final student = Student.fromJson({
      'id': 1,
      'student_number': 'STU-001',
      'name': 'Sokha Demo',
      'email': 'sokha@example.com',
      'course': 'DevOps',
    });
    expect(student.name, 'Sokha Demo');
    expect(student.id, 1);
    expect(student.toJson()['student_number'], 'STU-001');
    expect(student.toJson().containsKey('id'), isFalse);
  });
  test('required validation rejects empty input', () {
    expect(validateRequired('  '), isNotNull);
    expect(validateRequired('Sokha'), isNull);
  });
  test('email validation accepts valid email', () {
    expect(validateEmail('sokha@example.com'), isNull);
  });
  test('email validation rejects malformed email', () {
    expect(validateEmail('invalid'), isNotNull);
    expect(validateEmail(''), isNotNull);
  });
}
