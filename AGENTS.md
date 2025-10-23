# Repository Guidelines

## Project Structure & Module Organization
GranoFlow ships as a Flutter application. Core sources live under `lib/`, split into `core` for configuration and shared utilities, `data` for models plus repositories, `presentation` for UI widgets/pages, and `generated` for build_runner output (never edit by hand). Automated specs and UX briefs stay in `documents/`; update them alongside functional changes.

## Build, Test, and Development Commands
- `flutter pub get`: install or update dependencies after touching `pubspec.yaml`.
- `flutter pub run build_runner watch --delete-conflicting-outputs`: continuously regenerate Isar adapters, Retrofit clients, and other codegen artifacts.
- `flutter analyze`: enforce `flutter_lints` and surface style or API violations.
- `flutter test`: execute unit and widget suites in `test/`.
- `flutter test integration_test`: run end-to-end flows targeting the Isar-backed data layer before release builds.

## Coding Style & Naming Conventions
Use two-space indentation, keep lines ≤100 characters, and prefer single quotes in Dart. Name files `snake_case.dart`, classes `PascalCase`, and variables or methods `camelCase`; constants stay in SCREAMING_SNAKE_CASE. Run `dart format . --line-length 100` before reviews, and fix lint warnings or analyzer hints before pushing.

## Testing Guidelines
All new logic requires unit coverage plus a widget test when UI is affected. Mock dependencies with `mockito` or fakes under `test/support`. Target ≥80% statement coverage via `flutter test --coverage` and inspect `coverage/lcov.info`. Place integration scenarios in `integration_test/` with descriptive folder names, and document data fixtures near the scenario under `test/fixtures`.

## Commit & Pull Request Guidelines
Write focused commits in present tense and favor Conventional Commit prefixes (`feat`, `fix`, `chore`, `docs`) to drive automated changelog generation. Reference issue IDs in the body when applicable, and include screenshots or screen recordings for UI changes. Pull requests should summarize intent, list test evidence (`flutter analyze`, `flutter test`), and call out schema or migration impacts.

## Security & Configuration Tips
Because the app stores all data offline in Isar, guard schema migrations carefully; bump collection versions and describe migrations in the PR. Never commit user data, API keys, or signing artifacts. Keep debug builds free of sensitive logging, and verify encrypted local storage when touching `core/security` utilities.
