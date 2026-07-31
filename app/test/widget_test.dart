import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_core/pos_core.dart';

import 'package:app/src/pages/splash_page.dart';

void main() {
  test('AppLocalizations provides translations for supported locales', () {
    final fr = AppLocalizations(const Locale('fr'));
    final en = AppLocalizations(const Locale('en'));

    expect(fr.appTitle, 'Module POS');
    expect(en.appTitle, 'POS Module');
    expect(fr.pos, 'Caisse');
    expect(en.pos, 'POS');
  });

  testWidgets('SplashPage renders app title and navigates home', (tester) async {
    final router = GoRouter(
      initialLocation: Routes.splash,
      routes: [
        GoRoute(
          path: Routes.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const Scaffold(body: Text('HOME')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

    expect(find.byType(SplashPage), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });
}
