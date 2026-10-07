# Lesson 6 — browser-based instructor regression exercise

This starter intentionally has **no active GitHub Actions workflow on `main`**. Each student uses one personal fork and creates `.github/workflows/flutter-ci.yml` in GitHub's web editor using the [practice slides](https://docs.google.com/presentation/d/1Q9bZsrnrUrXUuSUPFBH5ClFxoS0Vdgq0gOmMslc7J5g/edit) and [student guide](LESSON6_PRACTICE.md). Do not add a workflow to upstream or accept student workflow PRs into it.

**Students need only a browser and GitHub access.** Flutter, Java, dependencies, tests, and APK building run on GitHub's runner. Do not require local SDK installation, a terminal, an emulator, a Laravel server, or a local test run. APK download is optional. A local Laravel/Flutter demo is optional and instructor-led.

The instructions below are for a **future supervised exercise**. The prepared starter keeps the application and all existing tests working and unchanged. The deliberate regression has not been applied.

## Before class

1. Confirm `main` contains no files under `.github/workflows/`. Complete preparation before students fork. Help older forks receive the workflow-removal commit before they create their own workflow.
2. Inspect `StudentApi.save`: creation uses POST; updating an existing student uses PUT. Keep all 17 tests unchanged.
3. Have each student create a personal fork, enable Actions if prompted, and create the workflow in the web editor.
4. Wait until everyone has recorded their first green run. Setup errors must be resolved before the planned regression.
5. If giving the optional live demo, use your own prepared Flutter/Android and Laravel environment. Restore the Laravel starter after Lesson 5 and use fictional records. The root README provides optional local setup commands.

The reference workflow uses the already-verified classroom toolchain: Flutter 3.47.2, Java 17, checkout v6, setup-java v5, flutter-action v2, and upload-artifact v4. Its tests use mocks/fakes and require no live backend or emulator. The workflow builds a classroom debug APK; it does not deploy the application.

## Publish one real application regression in the browser

After every student has a green baseline:

1. Open **maohieng/flutter-student-management-ci → Code → main**. Confirm you are editing the instructor's upstream repository.
2. Open `lib/student_api.dart` and choose the pencil/edit action.
3. In `StudentApi.save`, change only the update branch from:

```dart
          : _client.put(
```

to:

```dart
          : _client.post(
```

4. Preview the diff. Leave the create branch, endpoint URL, JSON body, tests, and documentation unchanged.
5. Choose **Commit changes**, enter `Demo: send wrong method when updating a student`, and commit to upstream `main`.
6. Open the new commit and copy its SHA and link. Share these as the announced break commit. Do not add `[skip ci]` to the message.

The update call is line 108 in the original source; use the function and branch if line numbers move. The real bug sends POST to `/api/students/{id}` instead of PUT. The existing **update sends PUT to student endpoint** test calls `save(..., isNew: false)` and asserts `expect(r.method, 'PUT')`. Its intended failure is **expected PUT, actual POST**. Mocked HTTP makes this independent of a live Laravel connection.

There is no upstream CI run because upstream has no workflow. Students test the change with the workflows in their own forks. **Keep the break present until everyone has synced, captured the red result, and had time to repair their own fork.**

## Browser sync while preserving each student's workflow

Students open **their own fork → Code → main → Sync fork** and review the incoming commits, then choose the normal **Update branch** action. Their workflow was added after the upstream preparation, so a normal merge of the later application-only change preserves it.

After sync, have students check both the announced break SHA and `.github/workflows/flutter-ci.yml`. Then open **Actions → Flutter CI**. If no run appears, choose **Run workflow → main**. The manual run checks the current synced branch; do not rerun an earlier baseline commit.

Never choose an option that discards the fork's commits, force-syncs, or resets it to upstream. If GitHub reports conflicts, stop and help. GitHub may offer a pull request to resolve them: carefully select the **student's fork and `main` as the base/destination**, with the instructor's `main` as the source. Preview the diff, retain the student's workflow, and merge into the student's fork only after resolving the conflict. Do not create or merge a student-workflow PR into the instructor's starter. If the comparison cannot be made safely, pause that student's sync rather than overwrite their work.

## Diagnose the red run and repair

Inspect **the student's fork → Actions → Flutter CI → latest run → flutter-ci → Run unit and widget tests**. The method assertion should fail. Later build/upload steps should be skipped. A YAML, dependency, formatting, or analysis failure is a separate setup issue and does not count as the intended application regression.

Students use the browser editor to restore `_client.put(...)` in their own update branch, preview the one-line change, and commit to their own `main`. Their new run should pass. Keep every test unchanged; do not accept changed expectations, removed tests, a skipped test command, or `continue-on-error`.

Each student shows the first green, red-after-sync, and repaired green run links and explains the PUT/POST mismatch aloud. No long writing assignment, local execution, or APK installation is required. Downloading the artifact is optional.

## Restore upstream in the browser

After students have completed their own repairs:

1. Open the recorded break commit and review its one-line change.
2. Return to the **current upstream `main`** version of `lib/student_api.dart`. Do not replace the whole file with an older copy; preserve unrelated changes that may have arrived.
3. Edit only the update branch in `StudentApi.save` from `_client.post(...)` back to `_client.put(...)`. Leave creation using POST and keep every test unchanged.
4. Preview the diff and commit to upstream `main` with `Restore student update request to PUT after class`.
5. Verify the current source uses PUT for updates and announce the restore commit SHA/link. Upstream still has no active workflow.

This new commit reverses the deliberate one-line regression without rewriting history. Students repeat normal **Sync fork → Update branch**, verify their workflow remains, and run CI manually if needed. Identical student and instructor repairs normally merge cleanly; review any conflict rather than discarding student work.

If you instead use an existing local instructor clone, `git revert BREAK_COMMIT_SHA` is an optional way to reverse the exact recorded break. Review the diff and any conflicts before publishing. Students do not need local Git or Flutter for either path.

## Troubleshooting and optional demo

- **No workflow run:** enable Actions in the fork, confirm the workflow is committed to `main`, then use **Run workflow → main**.
- **Sync is green:** check the break SHA and `StudentApi.save`. The student may have synced outside the break window or already repaired their fork.
- **Wrong red result:** resolve toolchain/YAML/format problems first. The intended failure is the PUT/POST mismatch in the existing API test.
- **Optional APK:** the example build embeds `http://10.0.2.2:8000/api`, for an Android emulator on the API computer. A physical phone needs a rebuild with the API computer's reachable LAN address. Do not make this a student prerequisite.
- **Optional live demo cannot connect:** check Laravel, device-specific API address, port, firewall, and trusted network. CI's mocked tests do not prove a live backend connection.

References: [GitHub fork sync](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/syncing-a-fork), [GitHub Actions events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows).
