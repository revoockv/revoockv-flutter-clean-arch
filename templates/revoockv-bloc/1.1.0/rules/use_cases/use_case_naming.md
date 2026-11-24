# Use case naming conventions (required)

All use cases must follow strict naming rules:

- Class name: `<Action>UseCase` (e.g., `SignInUseCase`, `SignUpUseCase`, `WatchCurrentSessionUseCase`).
- File name: `<snake_case_action>_use_case.dart` (e.g., `sign_in_use_case.dart`, `sign_up_use_case.dart`, `watch_current_session_use_case.dart`).
- The file must be located at `lib/features/<feature>/domain/use_cases/<snake_case_action>_use_case.dart`.
- Use cases are `RepositoryProvider`s of `<Feature>ProvidersWidget` (`<feature>_di.dart`); blocs get them from the page (`context.read<AddNoteUseCase>()`).
- An action returns `Future<Result<T>>`; a `Watch<Name>UseCase` returns `Stream<Result<T>>`.
- Every use case `call()` method must be documented with Dartdoc.
