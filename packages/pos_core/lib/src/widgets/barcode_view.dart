import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

class BarcodeView extends StatelessWidget {
  final String data;
  final double height;
  final double? width;
  final Barcode? barcode;

  const BarcodeView({
    super.key,
    required this.data,
    this.barcode,
    this.height = 56,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.trim().isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '—',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: BarcodeWidget(
        barcode: barcode ?? Barcode.code128(),
        data: data,
        height: height,
        width: width,
        drawText: true,
        color: Colors.black,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}
