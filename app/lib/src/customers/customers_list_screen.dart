import 'package:flutter/material.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

/// Liste des clients, accessible depuis le dashboard.
class CustomersListScreen extends StatelessWidget {
  const CustomersListScreen({super.key, required this.customers});

  final List<Customer> customers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List<Customer>.from(customers)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return AppScaffold(
      title: 'Clients',
      showBack: true,
      body: sorted.isEmpty
          ? const EmptyState(
              icon: Icons.people_outline,
              title: 'Aucun client',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final customer = sorted[index];
                return AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.14,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: theme.textTheme.titleSmall,
                            ),
                            if (customer.company != null &&
                                customer.company!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                customer.company!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            if (customer.phone != null &&
                                customer.phone!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                customer.phone!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (customer.taxId != null && customer.taxId!.isNotEmpty)
                        Text(
                          customer.taxId!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
