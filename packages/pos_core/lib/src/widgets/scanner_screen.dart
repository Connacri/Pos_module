import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.title = 'Scanner'});

  final String title;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
    ],
  );

  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (value == null || value.trim().isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Caméra indisponible',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  _ScanFrame(color: theme.colorScheme.primary),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.flash_on,
                    onPressed: () => _controller.toggleTorch(),
                  ),
                  const SizedBox(width: 24),
                  _ActionButton(
                    icon: Icons.cameraswitch_outlined,
                    onPressed: () => _controller.switchCamera(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 240,
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.center_focus_strong, color: Colors.white70),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        foregroundColor: Colors.white,
      ),
    );
  }
}
