# Folder structure

Folders come from `[structure]` of `template.toml`; the `folder_naming` linter rule checks them for every feature and for
`lib/core`: every listed subfolder exists (empty ones hold a `.gitkeep`, `scripts/init_feature.py` creates them), no
other subfolders, and no `.dart` file directly in `domain/`.

```
lib/
  main.dart                 runApp(ExampleAppWidget) → AppProvidersWidget → MaterialApp
  di.dart                   AppProvidersWidget: CoreProvidersWidget, then one <Feature>ProvidersWidget per feature
  core/                     the same layers as a feature
    domain/entities/        result.dart
    presentation/di/        core_di.dart — CoreProvidersWidget (logger)
    presentation/theme.dart AppTheme: values shared by features
  features/<feature>/
    data/
      data_sources/         interface + implementation (streams allowed), dispose()
      models/               DTOs with mapping to entities
      repositories/         repository implementations: models → entities, exceptions → Result.failure
    domain/
      entities/             plain classes; == by hand where compared
      repositories/         interfaces
      use_cases/            <Action>UseCase, Watch<Name>UseCase
    presentation/
      pages/                *_page.dart — creates the blocs (BlocProvider) from the use cases in the tree
      widgets/              *_widget.dart
      blocs/                <name>_bloc.dart + _event.dart + _state.dart; <name>_cubit.dart + _state.dart
      di/                   <feature>_di.dart — <Feature>ProvidersWidget
```

Where state lives: stored data in data sources (streamed out through the repository); what a screen shows in its
Bloc/Cubit; text being typed in a `TextEditingController` of a `StatefulWidget`.
