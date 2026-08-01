import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedFileData {
  final String name;
  final Uint8List bytes;
  final String mimeType;

  const PickedFileData({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });
}

class FilePickerService {
  FilePickerService._();

  static Future<PickedFileData?> pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    return _fromResult(result);
  }

  static Future<PickedFileData?> pickCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    return _fromResult(result, mimeType: 'text/csv');
  }

  static Future<PickedFileData?> pickAny() async {
    final result = await FilePicker.pickFiles(withData: true);
    return _fromResult(result);
  }

  static Future<String?> saveTextFile({
    required String fileName,
    required String content,
  }) async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Enregistrer $fileName',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: Uint8List.fromList(content.codeUnits),
    );
    if (path == null) return null;
    return path;
  }

  static Future<String?> savePdfFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Enregistrer $fileName',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
    );
    if (path == null) return null;
    return path;
  }

  static PickedFileData? _fromResult(
    FilePickerResult? result, {
    String? mimeType,
  }) {
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return null;
    return PickedFileData(
      name: file.name,
      bytes: bytes,
      mimeType: mimeType ?? (file.extension == 'csv' ? 'text/csv' : ''),
    );
  }
}
