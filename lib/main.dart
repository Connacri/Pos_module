import 'package:flutter/material.dart';
import 'package:app/src/app.dart';
import 'package:app/src/di/app_dependencies.dart';
import 'package:app/src/routes/app_routes.dart';
import 'package:pos_core/pos_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await AppDependencies.create();

  AppRouter.registerRoutes(buildAppRoutes());

  runApp(PosApp(dependencies: dependencies));
}
