# Decisions — "you need X → do Y"

Quick answers; the file says the details. When in doubt, copy `example/` and rename only.

## State and UI

| You need to… | Do | Details |
|---|---|---|
| Live data on a screen | a Bloc: `on<XSubscribed>` + `emit.forEach(watchXUseCase(), onData: _toState)` | `state/blocs.md` |
| An action with progress / error | a Cubit method: skip while running, `emit(Running)`, `await` the use case, `isClosed`, `emit(Done / Failed)` | `state/blocs.md` |
| Show the state | `context.watch<XBloc>().state` + `switch` over the sealed state | `state/blocs.md` |
| Rebuild for one field | `context.select<XCubit, T>(_selector)` in the lowest widget | `state/blocs.md` |
| Snackbar, navigation, clear a field | `BlocListener(listenWhen: _isX, listener: _onX)` | `state/blocs.md` |
| Send an action | `context.read<XCubit>().doIt(…)` in a private method | `state/blocs.md` |
| Text being typed | `TextEditingController` in a `StatefulWidget` (`initState` / `dispose`) | `state/widget_rules.md` |
| Compare states | `==` / `hashCode` by hand on states with data (`listEquals`); no equatable | `state/blocs.md` |
| `setState` | banned | `state/widget_rules.md` |

## Domain, data, DI

| You need to… | Do | Details |
|---|---|---|
| Name a use case | `<Action>UseCase`; live data `Watch<Name>UseCase` returning `Stream<Result<T>>` | `use_cases/use_case_naming.md` |
| Expected failures | `Result<T>`; `on Exception catch` in the repository; stream errors → `Result.failure` | `errors_models/result.md` |
| DTO ↔ entity | model in `data/models/` with `toEntity()` / `fromEntity()` | `errors_models/models_mapping.md` |
| Ids of new records | UUID v4 in the data source | `errors_models/models_mapping.md` |
| Provide a dependency | `RepositoryProvider<T>(create: _createX)` in `<Feature>ProvidersWidget` | `di/providers.md` |
| Release resources | `dispose()` on the data source + `dispose: _disposeX` on its provider | `di/providers.md` |
| Create a bloc | `BlocProvider(create: _createXBloc)` on its page, from `context.read<UseCase>()` | `di/providers.md` |
| Swap a dependency in tests | a `create…` parameter of the providers widget | `di/providers.md`, `testing/testing.md` |

## Conventions

| You need to… | Do | Details |
|---|---|---|
| A constant of one class | private `static const` of that class | `style/constants.md` |
| A value shared by features | `AppTheme` in `lib/core/presentation/theme.dart` | `style/constants.md` |
| Strings anywhere (UI, JSON keys, logs) | private `static const`; interpolation joins constants and values | `style/constants.md` |
| Inject dependencies | private named parameters `({required this._watchNotesUseCase})` | `style/dart_style.md` |
| Dartdoc, logging, imports | every public declaration documented; logger injected | `style/*.md` |
| Tests | every layer; `blocTest` for blocs; pages under the real providers | `testing/testing.md` |
| Commits and branches | `[TYPE-NNN] …`, `--no-ff` merges, branches kept | `git/git_rules.md` |

## Migrating from GetIt / watch_it / Provider / Riverpod

1. Keep data sources and models; repositories return `Stream<Result<T>>` instead of a `ValueListenable` or a provider.
2. Registrations → `RepositoryProvider`s of `<Feature>ProvidersWidget`; `di<T>()` / `ref.read` → `context.read<T>()`.
3. Screen state (notifiers, `ResultState`, providers) → a Bloc or Cubit; widgets watch, select and listen.
4. UI controllers that called nothing stay Flutter controllers in a `StatefulWidget`; the rest becomes a Cubit.
5. Run the linter.
