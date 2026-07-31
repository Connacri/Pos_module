enum PaymentMethod {
  cash('cash', 'Espèces'),
  card('card', 'Carte bancaire'),
  mobileMoney('mobile_money', 'Mobile Money'),
  bankTransfer('bank_transfer', 'Virement'),
  credit('credit', 'Crédit');

  const PaymentMethod(this.code, this.label);

  final String code;
  final String label;

  static PaymentMethod fromCode(String code) {
    return PaymentMethod.values.firstWhere(
      (m) => m.code == code,
      orElse: () => PaymentMethod.cash,
    );
  }
}

enum SaleStatus {
  pending('pending', 'En attente'),
  completed('completed', 'Terminée'),
  cancelled('cancelled', 'Annulée'),
  returned('returned', 'Retournée');

  const SaleStatus(this.code, this.label);

  final String code;
  final String label;

  static SaleStatus fromCode(String code) {
    return SaleStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => SaleStatus.pending,
    );
  }
}

enum InvoiceStatus {
  draft('draft', 'Brouillon'),
  issued('issued', 'Émise'),
  paid('paid', 'Payée'),
  overdue('overdue', 'En retard'),
  cancelled('cancelled', 'Annulée');

  const InvoiceStatus(this.code, this.label);

  final String code;
  final String label;

  static InvoiceStatus fromCode(String code) {
    return InvoiceStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => InvoiceStatus.draft,
    );
  }
}

enum SyncStatus {
  synced('synced'),
  pending('pending'),
  failed('failed');

  const SyncStatus(this.code);

  final String code;

  static SyncStatus fromCode(String code) {
    return SyncStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => SyncStatus.synced,
    );
  }
}
