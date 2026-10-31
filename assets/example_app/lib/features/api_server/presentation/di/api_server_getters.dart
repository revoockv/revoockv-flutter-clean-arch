import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/check_api_token_use_case.dart';
import '../../domain/use_cases/start_api_server_use_case.dart';
import '../../domain/use_cases/stop_api_server_use_case.dart';
import '../../domain/use_cases/watch_api_server_state_use_case.dart';

/// Watch use case for the state of the API server.
WatchApiServerStateUseCase get watchApiServerStateUseCase => di<WatchApiServerStateUseCase>();

/// Action use case that starts the API server.
StartApiServerUseCase get startApiServerUseCase => di<StartApiServerUseCase>();

/// Action use case that stops the API server.
StopApiServerUseCase get stopApiServerUseCase => di<StopApiServerUseCase>();

/// Query use case that checks the token of a request.
CheckApiTokenUseCase get checkApiTokenUseCase => di<CheckApiTokenUseCase>();
