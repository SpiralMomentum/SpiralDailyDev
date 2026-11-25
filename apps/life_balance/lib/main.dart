import 'package:flutter/widgets.dart';

import 'app/app_config.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  runApp(await bootstrap(const AppConfig()));
}
