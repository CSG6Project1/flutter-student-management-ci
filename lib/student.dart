class Student {
  const Student({required this.id, required this.number, required this.name,
    required this.email, required this.course});
  final int id;
  final String number, name, email, course;
  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'] as int, number: json['student_number'] as String,
    name: json['name'] as String, email: json['email'] as String,
    course: json['course'] as String,
  );
  Map<String, String> toJson() => {'student_number': number, 'name': name,
    'email': email, 'course': course};
}

String? validateRequired(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;
String? validateEmail(String? value) {
  if (validateRequired(value) != null) return 'This field is required';
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())
      ? null : 'Enter a valid email';
}
