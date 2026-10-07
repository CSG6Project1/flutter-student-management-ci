# Lesson 6 — browser-based Flutter CI practice

Follow the [Lesson 6 Practice Session slides](https://docs.google.com/presentation/d/1Q9bZsrnrUrXUuSUPFBH5ClFxoS0Vdgq0gOmMslc7J5g/edit). Suggested time: 90 minutes. Each student uses **one personal fork** and completes the exercise in **GitHub's web interface**.

Suggested timing: fork and inspect 10 minutes; write the workflow 30; first green run 10; sync and diagnose 15; repair 15; show runs and explain 10. The optional instructor app demo is outside this core exercise.

**No local Flutter, Java, Android SDK, emulator, Git, or terminal installation is required.** GitHub Actions installs the toolchain on its runner, runs the existing tests, and builds an APK. The local Laravel connection is an optional instructor demo. Downloading the APK is optional.

The starter has working application code and 17 existing tests, with **no active CI workflow on `main`**. You will create that workflow yourself.

## 1. Fork and inspect the app

1. Sign in to GitHub and open [the starter repository](https://github.com/maohieng/flutter-student-management-ci).
2. Choose **Fork**, select your personal account, and create your fork. Keep the repository name and the `main` branch.
3. Confirm the page address starts with `github.com/YOUR_USERNAME/flutter-student-management-ci`.
4. Open your fork's **Actions** tab and enable workflows if prompted.
5. In **Code**, inspect `lib/student.dart`, `lib/student_api.dart`, and the three files under `test/`.

Your fork is where you create the workflow, run CI, and repair code. The instructor's repository is the upstream source. Do not open a pull request to put your workflow into the instructor's repository.

**Already have an older fork?** Before writing a new workflow, preserve your own changes and use **Sync fork → Update branch** to receive the latest upstream preparation. The old inherited workflow should be removed. If GitHub reports a conflict, asks to discard your commits, or cannot update normally, stop and ask the instructor. Once your fork has received the removal, create your own workflow below. Do not use a discard/force-sync option.

## 2. Create your workflow in the browser

In your fork, select the `main` branch and choose **Add file → Create new file**. Enter this exact path as the filename:

`.github/workflows/flutter-ci.yml`

Type the workflow from the slides into the editor. The full reference is below. Use spaces for YAML indentation.

```yaml
name: Flutter CI
on: [push, pull_request, workflow_dispatch]
permissions:
  contents: read
jobs:
  flutter-ci:
    runs-on: ubuntu-latest
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-java@v5
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: '3.47.2'
          cache: true
      - name: Install dependencies
        run: flutter pub get --enforce-lockfile
      - name: Check Dart formatting
        run: dart format --output=none --set-exit-if-changed lib test
      - name: Analyze Dart code
        run: flutter analyze
      - name: Run unit and widget tests
        run: flutter test --coverage
      - name: Build classroom debug APK
        run: flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: student-management-debug-apk
          path: build/app/outputs/flutter-apk/app-debug.apk
```

Choose **Commit changes**, enter `Add Flutter CI with tests and debug APK`, and commit directly to **your fork's `main`**. Keep the supplied application and test files unchanged.

Read the workflow from top to bottom:

- Checkout retrieves your code.
- Java and Flutter setup run on GitHub's Ubuntu runner.
- Dependency installation uses the committed lockfile.
- Formatting, analysis, and tests check the code.
- A successful test step allows the APK build and upload.

The tests use mocked HTTP and an in-memory repository. They need no live Laravel server or Android emulator. The build embeds `API_BASE_URL`; it does not connect the runner to your computer. A failed check stops later build/upload steps.

## 3. Find your first green run

Open **your fork → Actions → Flutter CI → latest run → flutter-ci**. Expand the steps and read the test summary. The supplied baseline has **17 tests**. Fix workflow/setup errors in your fork until the run is green, save the run link, and tell the instructor you are ready.

If no run appears, check that Actions is enabled and the YAML file was committed to `main`. Then choose **Actions → Flutter CI → Run workflow**, select `main`, and run it manually. Do not change tests to fix a workflow/setup problem.

Optional: on a successful run's summary page, download **student-management-debug-apk** from **Artifacts**. Unzip it to find `app-debug.apk`. You do not need to install or run this APK for the CI exercise.

## 4. Sync the instructor's application regression

Wait until the instructor announces the deliberate break and shares its commit SHA. On **your fork's Code page**, with `main` selected:

1. Choose **Sync fork** and review the upstream changes.
2. Choose the normal **Update branch** action. Do not choose an option that discards your own commits.
3. Confirm `.github/workflows/flutter-ci.yml` is still present in your fork.
4. Open the commit history and verify that it includes the instructor's announced break commit.
5. Open your fork's **Actions** and inspect the new run. If no run starts, choose **Flutter CI → Run workflow → main** to test the synced code.

A normal merge/update keeps the workflow that you added after the upstream preparation. If GitHub reports conflicts or offers only a destructive option, stop and ask the instructor. Do not overwrite your fork with the upstream branch.

## 5. Read the failed test

In the new run, open **flutter-ci → Run unit and widget tests**. Find **update sends PUT to student endpoint**. The existing test expects **PUT** but the changed application sends **POST** for an existing student. The later APK build and upload should be skipped.

Read `test/student_api_test.dart` and follow the failure to `StudentApi.save` in `lib/student_api.dart`. Creating a student uses `POST /students`; updating an existing student uses `PUT /students/{id}`. CI has detected a change to application behavior.

If the run stays green, check the break SHA and the application code. You may have synced before the break, after the instructor restored it, or already repaired your fork. Do not change a test to manufacture a failure. YAML, dependency, formatting, or analysis failures are separate setup issues, not the intended red result.

## 6. Repair the application in GitHub

1. In your fork, open `lib/student_api.dart` on `main` and choose the pencil/edit action.
2. Find `StudentApi.save`. In the update branch, restore `_client.put(...)`. Keep the create branch's `_client.post(...)`, the URL, JSON body, and all tests unchanged.
3. Preview the diff. It should change only the update method from POST back to PUT.
4. Choose **Commit changes**, enter `Fix student update request to use PUT`, and commit directly to your fork's `main`.
5. Inspect the **new** Actions run for that repair commit. Confirm the tests, build, and upload pass.

Rerunning the old broken commit does not include your repair. Do not change the expected method to POST, remove tests, skip the test command, or add `continue-on-error`.

After the instructor announces the upstream restore, repeat **Sync fork → Update branch**, check that your workflow remains present, and run CI manually if needed. Ask for help with conflicts instead of discarding your work.

## Completion

Show your personal fork, your workflow file, the first green run, the red run after sync, and the green run after your repair. Submit the three run links and explain the PUT/POST mismatch aloud in about 30 seconds. No long written assignment, local app run, APK installation, or teammate review is required.

The optional instructor demo connects the app to Laravel and shows CRUD behavior. It illustrates runtime behavior that the mocked CI tests do not verify. Use fictional student data. See the [instructor guide](INSTRUCTOR_GUIDE.md) for the future publish-and-restore sequence; the deliberate break is not present in the prepared starter.
