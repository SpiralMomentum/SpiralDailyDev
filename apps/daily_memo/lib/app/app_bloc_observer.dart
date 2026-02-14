import 'package:app_logging/app_logging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final _logger = AppLogger(tag: 'Bloc');

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _logger.error(
      '${bloc.runtimeType} error',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
