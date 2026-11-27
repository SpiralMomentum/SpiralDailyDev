import 'package:flutter/widgets.dart';

import 'app/bootstrap.dart';
import 'app/spend_ledger_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (deps, initialEditId) = await bootstrap();
  runApp(SpendLedgerApp(deps: deps, initialEditId: initialEditId));
}
