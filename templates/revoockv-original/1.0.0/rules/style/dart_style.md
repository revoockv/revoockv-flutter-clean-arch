# Dart style — Result, parameters, constructors

## Result — `Result.ok`, `const`, `when`

Full contract: `rules/errors_models/result.md` (`lib/core/domain/entities/result.dart`).

- Commands return the shared `Result.ok`; queries return `Result.success(value)` with a required value.
- `Result.success` / `Result.failure` are `const factory` constructors — use `const` whenever all arguments are constants (`const Result.failure(_signInFailedMessage)`). Enable `prefer_const_constructors` in `analysis_options.yaml`.
- `isSuccess` / `isFailure` answer "did it work?"; read the value or error with `result.when(success: _onX, failure: _onError)`.
- Failure text is human-readable; raw exceptions go to the logger. Repositories use `on Exception catch`, never a bare `catch (e)`.

## Private Named Parameters

Inject dependencies with private named parameters: `AuthRepositoryImpl({required this._dataSource, required this._logger});` — callers still write `dataSource:` / `logger:`, and `flutter analyze` (`prefer_initializing_formals`) asks for this form. It needs `sdk: ^3.12.0` in `pubspec.yaml`; on an older SDK use an initializer list: `({required AuthDataSource dataSource}) : _dataSource = dataSource`.

## Const Constructors + Asserts

A `const` constructor may validate its parameters with `assert` in the initializer list. For a `const` call the asserts are checked at compile time (an invalid constant does not compile), for a non-`const` call at runtime in debug builds. One constructor is enough — no separate `_internal` constructor for const defaults:

```dart
final class ChatSettingsEntity {
  /// Model used when the user has not chosen one.
  static const String _defaultModel = 'Qwen3.6-35B-A3B-4bit';

  /// Default sampling temperature.
  static const double _defaultTemperature = 0.7;

  /// Settings of a new chat.
  static const ChatSettingsEntity defaultSettings = ChatSettingsEntity(selectedModel: _defaultModel);

  static const String _emptyModelMessage = 'selectedModel must not be empty';
  static const String _temperatureRangeMessage = 'temperature must be between 0.0 and 1.0';

  /// Name of the selected model.
  final String selectedModel;

  /// Sampling temperature, 0.0–1.0.
  final double temperature;

  /// How the chat sends requests.
  final ChatMode chatMode;

  /// Creates settings; asserts run at compile time for `const` calls.
  const ChatSettingsEntity({
    required this.selectedModel,
    this.temperature = _defaultTemperature,
    this.chatMode = ChatMode.oneCommand,
  })  : assert(selectedModel != '', _emptyModelMessage),
        assert(temperature >= 0.0 && temperature <= 1.0, _temperatureRangeMessage);
}
```

`selectedModel != ''` instead of `selectedModel.isNotEmpty`: a getter call is not a constant expression, so `isNotEmpty` would break the `const` call.
