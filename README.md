# Flutter Student Management — CI practice starter

**The starter intentionally contains no active CI workflow on `main`.** Each student forks it and writes their own workflow in GitHub’s web editor using the [Lesson 6 Practice Session](https://docs.google.com/presentation/d/1Q9bZsrnrUrXUuSUPFBH5ClFxoS0Vdgq0gOmMslc7J5g/edit).

- [Individual student instructions](docs/LESSON6_PRACTICE.md)
- [Instructor: publish and restore a classroom regression](docs/INSTRUCTOR_GUIDE.md)

Lesson 6 sample: an Android Flutter app that **creates, lists, views, updates and deletes students** through the [Laravel Student Management API](https://github.com/maohieng/laravel-student-management-ci).

Features: paginated list, add/edit form, server-backed detail dialog, delete confirmation, input validation, readable Laravel 422 errors, connection errors and retry. Use fictional data: the classroom backend has no authentication. Do not deploy this demo with real student data.

## Browser-based CI practice

Students need a browser and GitHub access. No local Flutter, Java, Android SDK, emulator, Git, or Laravel installation is required. GitHub Actions installs the toolchain, runs the tests, and builds an APK in the student's fork. Follow the [student guide](docs/LESSON6_PRACTICE.md) for the complete workflow and browser-only steps.

The lesson is green → sync an instructor application regression → red → repair in GitHub → green. Existing tests stay unchanged. APK download is optional; a live Laravel connection is an optional instructor demo.

## Optional instructor local demo

The following setup and app-running commands are for an instructor or anyone who chooses to run the app locally. They are not prerequisites for the student CI exercise.

### 1. Tools

Use **Flutter 3.47.2**, Java 17 and an Android SDK/device or emulator. The practice workflow pins the same Flutter version. Only prepare this local toolchain if you will give the optional live demo. Run `flutter doctor` and complete Android setup, including accepting SDK licenses on your development computer. This repository targets Android; iOS and web scaffolds are not included.

### 2. Start Laravel

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

### 3. Run Flutter

For this optional local run, fork the repository first and replace `YOUR_USERNAME` below. Browser-only students can skip this entire local setup section.

```bash
git clone https://github.com/YOUR_USERNAME/flutter-student-management-ci.git
cd flutter-student-management-ci
git remote add upstream https://github.com/maohieng/flutter-student-management-ci.git
flutter pub get --enforce-lockfile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

| Device | API_BASE_URL |
|---|---|
| Android emulator on the API computer | `http://10.0.2.2:8000/api` |
| Physical phone | `http://YOUR_COMPUTER_LAN_IP:8000/api` |
| Hosted backend | Its reachable HTTPS base URL ending in `/api` |

`localhost` on a phone refers to the phone, not your computer. A physical phone must be able to reach the API computer. Changing `API_BASE_URL` requires a fresh run/build: it is compile-time configuration. It is not secret storage. The default is the Android emulator URL.

The main Android manifest grants Internet access. **Only the debug manifest permits local cleartext HTTP.** Release builds should use HTTPS. The debug APK built by your workflow is a classroom artifact, not a production-signed release.

### 4. Manual API demo

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

In the browser-based lesson, these checks run in GitHub Actions. If you choose to use a local Flutter setup, the equivalent commands are:

```bash
dart format lib test
flutter analyze
flutter test --coverage
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

- `test/student_test.dart`: JSON mapping and field validation.
- `test/student_api_test.dart`: HTTP methods, Laravel JSON envelopes, pagination, 201/204/422/404 and network failures, using `MockClient`.
- `test/student_widget_test.dart`: empty state, form validation, creating a student, retry and confirmed deletion, using an in-memory fake repository.

These automated tests do **not** run a real Laravel server or Android emulator. The real connection can be checked separately in the optional instructor demo. A successful build proves packaging; it does not prove every runtime behavior or network connection.

After you create the workflow in your own fork, a push, pull request or manual execution starts GitHub Actions. It installs Java and Flutter, restores locked dependencies, checks formatting, analyzes Dart code, runs tests and builds an APK. A failed check stops later steps. Download **student-management-debug-apk** from a successful run’s Artifacts section; it contains `app-debug.apk`.

To build for a physical phone:

```bash
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.50:8000/api
```

Replace the example IP with your API computer’s actual LAN address. Output: `build/app/outputs/flutter-apk/app-debug.apk`. Release signing and store publishing are outside this lesson.

## Individual practice: green → sync → red → repair → green

1. Fork this starter into your personal account and enable Actions if prompted.
2. Use **Add file → Create new file** to create `.github/workflows/flutter-ci.yml` in your fork, following the practice slides and [student guide](docs/LESSON6_PRACTICE.md).
3. Commit in GitHub to your fork’s `main` and review the first green run. APK download is optional.
4. Wait for the instructor to publish a deliberate application regression.
5. Use **Sync fork → Update branch** in your fork. Confirm your workflow remains; use **Actions → Flutter CI → Run workflow → main** if no run starts.
6. Read the existing failed test: an update should use PUT, but the application sends POST. Repair `StudentApi.save` in GitHub’s web editor, keep all tests unchanged, and commit again.
7. Show your initial green, failed, and repaired green run links and explain the method mismatch aloud. No local app run or long written assignment is required.

Use a normal sync/update so your own workflow remains in your fork. Do not discard your commits or force-sync to upstream; ask the instructor if conflicts appear. The student guide includes browser steps and older-fork handling. The [instructor guide](docs/INSTRUCTOR_GUIDE.md) explains the future break and restore. The deliberate regression has not been applied to the prepared starter.

## Troubleshooting

- **Connection refused/timeout:** start Laravel; check the URL, port, firewall and shared network.
- **404:** confirm the `/api` prefix and that the student still exists.
- **422:** correct the field shown in Laravel’s message, including duplicate email/student number.
- **Build failure:** open the first failed CI step; check Java, Android SDK and Gradle messages.
- **Format check failure:** inspect the formatting step and correct the source layout in the browser; ask the instructor for help if needed. With an optional local Flutter setup, run `dart format lib test` and commit the result.

Source: `lib/student.dart` (model and validators), `lib/student_api.dart` (HTTP adapter), `lib/main.dart` (screens), `.github/workflows/flutter-ci.yml` (the CI workflow you create in your own fork; intentionally absent upstream).
