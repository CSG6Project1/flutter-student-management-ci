# Flutter Student Management — CI showcase

[![Flutter CI](https://github.com/maohieng/flutter-student-management-ci/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/maohieng/flutter-student-management-ci/actions/workflows/flutter-ci.yml)

Lesson 6 sample: an Android Flutter app that **creates, lists, views, updates and deletes students** through the [Laravel Student Management API](https://github.com/maohieng/laravel-student-management-ci).

Features: paginated list, add/edit form, server-backed detail dialog, delete confirmation, input validation, readable Laravel 422 errors, connection errors and retry. Use fictional data: the classroom backend has no authentication. Do not deploy this demo with real student data.

## 1. Tools

Use **Flutter 3.47.2**, Java 17 and an Android SDK/device or emulator. CI pins the same Flutter version. Run `flutter doctor` and complete Android setup, including accepting SDK licenses on your development computer. This repository targets Android; iOS and web scaffolds are not included.

## 2. Start Laravel

In a separate terminal:

```bash
git clone https://github.com/maohieng/laravel-student-management-ci.git
cd laravel-student-management-ci
composer install
cp .env.example .env
php artisan key:generate
php -r "file_exists('database/database.sqlite') || touch('database/database.sqlite');"
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

PHP 8.3+, Composer and SQLite extensions are required. Verify `http://127.0.0.1:8000/api/students` returns JSON. Use a trusted local network and fictional records. Binding to `0.0.0.0` permits other devices on that network to reach the development server if your firewall allows it.

## 3. Run Flutter

```bash
git clone https://github.com/maohieng/flutter-student-management-ci.git
cd flutter-student-management-ci
flutter pub get --enforce-lockfile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

| Device | API_BASE_URL |
|---|---|
| Android emulator on the API computer | `http://10.0.2.2:8000/api` |
| Physical phone | `http://YOUR_COMPUTER_LAN_IP:8000/api` |
| Hosted backend | Its reachable HTTPS base URL ending in `/api` |

`localhost` on a phone refers to the phone, not your computer. A physical phone must be able to reach the API computer. Changing `API_BASE_URL` requires a fresh run/build: it is compile-time configuration. It is not secret storage. The default is the Android emulator URL.

The main Android manifest grants Internet access. **Only the debug manifest permits local cleartext HTTP.** Release builds should use HTTPS. The supplied debug APK is a classroom artifact, not a production-signed release.

## 4. Concrete group demo

1. Add `STU-100 / Vanna Demo / vanna@example.com / DevOps`.
2. Tap the row to load and display that student from Laravel.
3. Open the row menu → Edit; change the course to `Flutter`.
4. Refresh and confirm the change remains.
5. Try creating another student with the same email and read the server validation error.
6. Delete the demo student and confirm the row disappears.
7. Add enough fictional students to explore Next/Previous pagination.

## API contract

| Action | HTTP request | Laravel response |
|---|---|---|
| List | `GET /api/students?page=1` | 200; `data`, `meta.current_page`, `meta.last_page` |
| View | `GET /api/students/{id}` | 200; record inside `data` |
| Create | `POST /api/students` | 201; record inside `data` |
| Update | `PUT /api/students/{id}` | 200; record inside `data` |
| Delete | `DELETE /api/students/{id}` | 204; empty body |
| Invalid fields | POST or PUT | 422; messages inside `errors` |

Payload fields: `student_number`, `name`, `email`, `course`. The app sends JSON and an `Accept: application/json` header. The backend remains the authority for uniqueness and validation. `StudentApi` accepts an injected HTTP client so response handling can be tested deterministically.

## Tests and CI

```bash
dart format lib test
flutter analyze
flutter test --coverage
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

- `test/student_test.dart`: JSON mapping and field validation.
- `test/student_api_test.dart`: HTTP methods, Laravel JSON envelopes, pagination, 201/204/422/404 and network failures, using `MockClient`.
- `test/student_widget_test.dart`: empty state, form validation, creating a student, retry and confirmed deletion, using an in-memory fake repository.

These automated tests do **not** run a real Laravel server or Android emulator. The real connection is checked separately in the group demo. A successful build proves packaging; it does not prove every runtime behavior or network connection.

On push, pull request or manual execution, GitHub Actions installs Java and Flutter, restores locked dependencies, checks formatting, analyzes Dart code, runs tests and builds an APK. A failed check stops later steps. Download **student-management-debug-apk** from a successful run’s Artifacts section; it contains `app-debug.apk`.

To build for a physical phone:

```bash
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.50:8000/api
```

Replace the example IP with your API computer’s actual LAN address. Output: `build/app/outputs/flutter-apk/app-debug.apk`. Release signing and store publishing are outside this lesson.

## Red → green practice

Use one shared fork per group, with each student on a separate branch. Rotate driver, API operator, tester and reviewer.

```bash
git switch -c demo/sokha-ci
```

Add a uniquely named test file, e.g. `test/sokha_ci_test.dart`, with this correct final test:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_student_management_ci/student.dart';

void main() {
  test('Sokha checks a valid email', () {
    expect(validateEmail('sokha@example.com'), isNull);
  });
}
```

Temporarily change `isNull` to `isNotNull`, run the test, commit and push the branch, and open a PR. Read the failed assertion in Actions. Restore `isNull`, format, test and push again. Ask a teammate to review the latest green run before merging. Keep deliberate failures out of `main`. Submit repository and PR links and demonstrate the app; no long written assignment is required.

## Troubleshooting

- **Connection refused/timeout:** start Laravel; check the URL, port, firewall and shared network.
- **404:** confirm the `/api` prefix and that the student still exists.
- **422:** correct the field shown in Laravel’s message, including duplicate email/student number.
- **Build failure:** open the first failed CI step; check Java, Android SDK and Gradle messages.
- **Format check failure:** run `dart format lib test`, commit the changes and push.

Source: `lib/student.dart` (model and validators), `lib/student_api.dart` (HTTP adapter), `lib/main.dart` (screens), `.github/workflows/flutter-ci.yml` (CI).
