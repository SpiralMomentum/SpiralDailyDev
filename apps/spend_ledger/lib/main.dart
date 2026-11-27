import 'package:flutter/widgets.dart';

import 'app/bootstrap.dart';
import 'app/spend_ledger_app.dart';
import 'app/startup_error_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final (deps, initialEditId) = await bootstrap();
    runApp(SpendLedgerApp(deps: deps, initialEditId: initialEditId));
  } catch (e) {
    debugPrint('bootstrap failed: ${e.runtimeType}');
    runApp(StartupErrorApp(error: e));
  }
}
