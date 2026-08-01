import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeView extends StatelessWidget {
  final String data;
  final double size;
  final Color? backgroundColor;

  const QrCodeView({
    super.key,
    required this.data,
    this.size = 160,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.trim().isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            Icons.qr_code_2,
            size: size * 0.4,
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: QrImageView(
        data: data,
        size: size,
        backgroundColor: backgroundColor ?? Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }
}
