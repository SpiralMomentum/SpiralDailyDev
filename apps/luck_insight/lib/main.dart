import 'package:flutter/material.dart';

import 'package:luck_insight/app/di/service_locator.dart';
import 'package:luck_insight/app/luck_insight_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.setup();

  runApp(const LuckInsightApp());
}
