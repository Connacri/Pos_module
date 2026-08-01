import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/routes.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget body;
  final bool centerTitle;
  final bool? showBack;

  const AppScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    required this.body,
    this.centerTitle = false,
    this.showBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: titleWidget ?? (title != null ? Text(title!) : null),
        actions: actions,
        centerTitle: centerTitle,
        automaticallyImplyLeading: false,
        leading: _buildLeading(context),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(bottom: false, child: body),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final show = showBack ?? canPop;
    if (!show) return null;
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go(Routes.home);
        }
      },
    );
  }
}
