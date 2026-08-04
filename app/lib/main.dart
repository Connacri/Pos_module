import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/di/app_dependencies.dart';
import 'src/routes/app_routes.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_data/pos_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await AppDependencies.create();
  await _seedIfNeeded();

  AppRouter.registerRoutes(buildAppRoutes());

  runApp(PosApp(dependencies: dependencies));
}

Future<void> _seedIfNeeded() async {
  await SeedService.seedIfEmpty();
}
