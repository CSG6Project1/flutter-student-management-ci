import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_student_management_ci/main.dart';
import 'package:flutter_student_management_ci/student.dart';
import 'package:flutter_student_management_ci/student_api.dart';
class FakeRepository implements StudentRepository {
  final students = <Student>[];
  bool offline = false;
  @override
  Future<StudentPage> list({int page = 1}) async { if (offline) throw ApiException('Offline demo'); return StudentPage(List.of(students), 1, 1); }
  @override
  Future<Student> get(int id) async => students.firstWhere((s) => s.id == id);
  @override
  Future<Student> save(Student student, {required bool isNew}) async {
    final result = Student(id: isNew ? 1 : student.id, number: student.number, name: student.name, email: student.email, course: student.course);
    students.removeWhere((s) => s.id == result.id); students.add(result); return result;
  }
  @override
  Future<void> delete(int id) async { students.removeWhere((s) => s.id == id); }
}
void main() {
  testWidgets('empty state and required form validation', (tester) async {
    await tester.pumpWidget(StudentApp(repository: FakeRepository())); await tester.pumpAndSettle();
    expect(find.text('No students yet. Tap + to add one.'), findsOneWidget);
    await tester.tap(find.byTooltip('Add student')); await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save')); await tester.tap(find.text('Save')); await tester.pumpAndSettle();
    expect(find.text('This field is required'), findsNWidgets(4));
  });
  testWidgets('create student through form and show result', (tester) async {
    final repo = FakeRepository(); await tester.pumpWidget(StudentApp(repository: repo)); await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add student')); await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'STU-001'); await tester.enterText(fields.at(1), 'Sokha Demo');
    await tester.enterText(fields.at(2), 'sokha@example.com'); await tester.enterText(fields.at(3), 'DevOps');
    await tester.ensureVisible(find.text('Save')); await tester.tap(find.text('Save')); await tester.pumpAndSettle();
    expect(find.text('Sokha Demo'), findsOneWidget); expect(repo.students.length, 1);
  });
  testWidgets('error state offers retry', (tester) async {
    final repo = FakeRepository()..offline = true;
    await tester.pumpWidget(StudentApp(repository: repo)); await tester.pumpAndSettle();
    expect(find.text('Offline demo'), findsOneWidget); repo.offline = false;
    await tester.tap(find.text('Retry')); await tester.pumpAndSettle(); expect(find.text('No students yet. Tap + to add one.'), findsOneWidget);
  });
  testWidgets('delete requires confirmation', (tester) async {
    final repo = FakeRepository()..students.add(const Student(id: 1, number: 'STU-001', name: 'Sokha Demo', email: 'sokha@example.com', course: 'DevOps'));
    await tester.pumpWidget(StudentApp(repository: repo)); await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Student actions')); await tester.pumpAndSettle();
    await tester.tap(find.text('Delete')); await tester.pumpAndSettle(); expect(find.text('Delete student?'), findsOneWidget);
    await tester.tap(find.text('Cancel')); await tester.pumpAndSettle(); expect(repo.students.length, 1);
    await tester.tap(find.byTooltip('Student actions')); await tester.pumpAndSettle(); await tester.tap(find.text('Delete')); await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete')); await tester.pumpAndSettle(); expect(repo.students, isEmpty);
  });
}
