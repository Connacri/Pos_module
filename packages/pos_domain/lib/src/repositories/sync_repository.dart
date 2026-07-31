abstract class SyncRepository {
  Future<void> syncAll();
  Future<DateTime?> lastSyncAt();
  Stream<bool> watchOnline();
}
