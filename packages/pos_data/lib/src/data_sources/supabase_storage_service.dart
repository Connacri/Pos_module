import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos_core/pos_core.dart';

import 'supabase_config.dart';

class SupabaseStorageService {
  SupabaseStorageService._();

  static const String defaultBucket = 'uploads';

  static bool get isReady => SupabaseConfig.isConfigured;

  static Future<void> ensureBucket([String bucket = defaultBucket]) async {
    if (!isReady) return;
    try {
      final storage = Supabase.instance.client.storage;
      final buckets = await storage.listBuckets();
      final exists = buckets.any((b) => b.name == bucket);
      if (!exists) {
        await storage.createBucket(bucket, const BucketOptions(public: true));
      }
    } catch (error, stack) {
      AppLogger.error('ensureBucket', error, stack);
    }
  }

  static Future<String?> upload(
    Uint8List bytes,
    String fileName, {
    String bucket = defaultBucket,
    String folder = 'files',
  }) async {
    if (!isReady) return null;
    await ensureBucket(bucket);
    final safeName = Uri.encodeComponent(fileName);
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    try {
      final storage = Supabase.instance.client.storage;
      await storage.from(bucket).uploadBinary(path, bytes);
      return storage.from(bucket).getPublicUrl(path);
    } catch (error, stack) {
      AppLogger.error('upload', error, stack);
      return null;
    }
  }

  static Future<String?> uploadCsv(
    String content,
    String fileName, {
    String bucket = defaultBucket,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    return upload(bytes, fileName, bucket: bucket, folder: 'csv');
  }

  static Future<String?> uploadImage(
    Uint8List bytes,
    String fileName, {
    String bucket = defaultBucket,
  }) async {
    return upload(bytes, fileName, bucket: bucket, folder: 'images');
  }
}
