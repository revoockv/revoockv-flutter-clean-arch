# Dependencies in the widget tree

Example: `example/lib/features/notes/presentation/di/notes_di.dart`, `example/lib/di.dart`,
`example/lib/core/presentation/di/core_di.dart`.

- No service locator. Every dependency is a `RepositoryProvider` in the tree and is found with `context.read<T>()`.
- Each feature has one `<Feature>ProvidersWidget` in `presentation/di/<feature>_di.dart`: a `MultiRepositoryProvider`
  with its data sources → repositories → use cases, bottom-up; each `create` reads what it needs from above.
- `lib/di.dart` holds `AppProvidersWidget`: `CoreProvidersWidget` (logger, database) outermost, then every feature's
  providers; a feature's data source reads the shared database (`context.read<AppDatabase>()`).
  `main.dart` puts it above `MaterialApp`, so every page finds the use cases.
- Providers are lazy: an instance is made on its first `read`. What owns resources is closed by its provider's
  `dispose:` (`dispose: _closeDatabase` in `CoreProvidersWidget`).
- Blocs and cubits are not in the app tree: the page that shows them creates them with `BlocProvider(create: …)` from
  the use cases (`context.read<AddNoteUseCase>()`), so they are closed with the page.
- `create` / `dispose` are private methods, not closures.
- Tests swap a dependency through a constructor parameter of the providers widget: `createDataSource` of a feature's
  providers, `createLogger` / `createDatabase` of `CoreProvidersWidget` (`example/test/app_test_app.dart`).
