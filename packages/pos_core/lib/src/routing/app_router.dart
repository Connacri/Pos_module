import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static GoRouter? _router;

  static GoRouter get router {
    final existing = _router;
    if (existing != null) return existing;
    final created = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: Routes.home,
      routes: _routes,
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Page not found: ${state.uri}')),
      ),
    );
    _router = created;
    return created;
  }

  static List<GoRoute> _routes = [];

  static void registerRoutes(List<GoRoute> routes) {
    _routes = routes;
    _router = null;
  }
}