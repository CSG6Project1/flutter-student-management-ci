import 'package:flutter/material.dart';
import 'student.dart';
import 'student_api.dart';

void main() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
  runApp(
    StudentApp(
      repository: StudentApi(baseUrl: baseUrl),
      server: baseUrl,
    ),
  );
}

class StudentApp extends StatelessWidget {
  const StudentApp({
    super.key,
    required this.repository,
    this.server = 'Test server',
  });
  final StudentRepository repository;
  final String server;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Student Management',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
    ),
    home: StudentList(repository: repository, server: server),
  );
}

class StudentList extends StatefulWidget {
  const StudentList({
    super.key,
    required this.repository,
    required this.server,
  });
  final StudentRepository repository;
  final String server;
  @override
  State<StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  late Future<StudentPage> _result;
  int _page = 1;
  @override
  void initState() {
    super.initState();
    _result = widget.repository.list();
  }

  void _load([int? page]) {
    setState(() {
      _page = page ?? _page;
      _result = widget.repository.list(page: _page);
    });
  }

  Future<void> _edit([Student? student]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            StudentForm(repository: widget.repository, student: student),
      ),
    );
    if (changed == true && mounted) _load(1);
  }

  Future<void> _view(Student student) async {
    try {
      final fresh = await widget.repository.get(student.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(fresh.name),
          content: Text('${fresh.number}\n${fresh.email}\n${fresh.course}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _error(e);
    }
  }

  void _error(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> _delete(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text('Remove ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.delete(student.id);
      if (mounted) _load(1);
    } catch (e) {
      if (mounted) _error(e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Student Management'),
      actions: [
        IconButton(
          onPressed: () => _load(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _edit(),
      tooltip: 'Add student',
      child: const Icon(Icons.add),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            widget.server,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: FutureBuilder<StudentPage>(
            future: _result,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(snapshot.error.toString()),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => _load(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final data = snapshot.requireData;
              return Column(
                children: [
                  Expanded(
                    child: data.students.isEmpty
                        ? const Center(
                            child: Text('No students yet. Tap + to add one.'),
                          )
                        : ListView.builder(
                            itemCount: data.students.length,
                            itemBuilder: (context, i) {
                              final s = data.students[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  title: Text(s.name),
                                  subtitle: Text(
                                    '${s.number} · ${s.course}\n${s.email}',
                                  ),
                                  isThreeLine: true,
                                  onTap: () => _view(s),
                                  trailing: PopupMenuButton<String>(
                                    tooltip: 'Student actions',
                                    onSelected: (action) {
                                      if (action == 'edit') {
                                        _edit(s);
                                      } else {
                                        _delete(s);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: data.current > 1
                              ? () => _load(data.current - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                          tooltip: 'Previous page',
                        ),
                        Text('Page ${data.current} of ${data.last}'),
                        IconButton(
                          onPressed: data.current < data.last
                              ? () => _load(data.current + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                          tooltip: 'Next page',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class StudentForm extends StatefulWidget {
  const StudentForm({super.key, required this.repository, this.student});
  final StudentRepository repository;
  final Student? student;
  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _number, _name, _email, _course;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _number = TextEditingController(text: s?.number);
    _name = TextEditingController(text: s?.name);
    _email = TextEditingController(text: s?.email);
    _course = TextEditingController(text: s?.course);
  }

  @override
  void dispose() {
    for (final c in [_number, _name, _email, _course]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.save(
        Student(
          id: widget.student?.id ?? 0,
          number: _number.text.trim(),
          name: _name.text.trim(),
          email: _email.text.trim(),
          course: _course.text.trim(),
        ),
        isNew: widget.student == null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.student == null ? 'Add student' : 'Edit student'),
    ),
    body: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _number,
            decoration: const InputDecoration(labelText: 'Student number'),
            maxLength: 30,
            validator: validateRequired,
          ),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            maxLength: 100,
            validator: validateRequired,
          ),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            maxLength: 255,
            validator: validateEmail,
          ),
          TextFormField(
            controller: _course,
            decoration: const InputDecoration(labelText: 'Course'),
            maxLength: 100,
            validator: validateRequired,
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
    ),
  );
}
