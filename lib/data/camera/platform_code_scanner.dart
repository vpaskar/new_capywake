import 'package:capywake/data/camera/code_scanner.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// The back camera through `mobile_scanner`. The only file that imports it.
class PlatformCodeScanner implements CodeScanner {
  @override
  Widget build({
    required ValueChanged<String> onCode,
    required VoidCallback onFailed,
    Key? key,
  }) => _ScannerView(onCode: onCode, onFailed: onFailed, key: key);
}

class _ScannerView extends StatefulWidget {
  const _ScannerView({
    required this.onCode,
    required this.onFailed,
    super.key,
  });

  final ValueChanged<String> onCode;
  final VoidCallback onFailed;

  @override
  State<_ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<_ScannerView> {
  final _controller = MobileScannerController(autoTorch: true);
  bool _failureReported = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _detected(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) widget.onCode(value);
    }
  }

  Widget _failed(BuildContext context, MobileScannerException error) {
    if (!_failureReported) {
      _failureReported = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFailed();
      });
    }
    return const ColoredBox(color: Colors.black);
  }

  @override
  Widget build(BuildContext context) => MobileScanner(
    controller: _controller,
    onDetect: _detected,
    errorBuilder: _failed,
  );
}
