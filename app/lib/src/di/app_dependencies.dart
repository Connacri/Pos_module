import 'package:pos_core/pos_core.dart';
import 'package:pos_data/pos_data.dart';
import 'package:pos_domain/pos_domain.dart';

class AppDependencies {
  AppDependencies({
    required this.productUseCases,
    required this.categoryUseCases,
    required this.customerUseCases,
    required this.saleUseCases,
    required this.invoiceUseCases,
    required this.syncUseCases,
    required this.connectivityService,
  });

  final ProductUseCases productUseCases;
  final CategoryUseCases categoryUseCases;
  final CustomerUseCases customerUseCases;
  final SaleUseCases saleUseCases;
  final InvoiceUseCases invoiceUseCases;
  final SyncUseCases syncUseCases;
  final ConnectivityService connectivityService;

  static Future<AppDependencies> create() async {
    await ObjectboxDatabase.open();
    await SupabaseConfig.initialize();

    final connectivity = ConnectivityService();
    final productRepository = ObjectboxProductRepository();
    final categoryRepository = ObjectboxCategoryRepository();
    final customerRepository = ObjectboxCustomerRepository();
    final saleRepository = ObjectboxSaleRepository();
    final invoiceRepository = ObjectboxInvoiceRepository();
    final syncRepository = SupabaseSyncRepository(
      connectivityService: connectivity,
    );
    final authRepository = SupabaseAuthRepository();

    return AppDependencies(
      productUseCases: ProductUseCases(productRepository),
      categoryUseCases: CategoryUseCases(categoryRepository),
      customerUseCases: CustomerUseCases(customerRepository),
      saleUseCases: SaleUseCases(saleRepository, productRepository),
      invoiceUseCases: InvoiceUseCases(invoiceRepository, saleRepository),
      syncUseCases: SyncUseCases(syncRepository, authRepository),
      connectivityService: connectivity,
    );
  }
}
