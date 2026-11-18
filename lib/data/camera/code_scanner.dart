import 'package:flutter/widgets.dart';

/// A live camera view that reports every code it reads. Built only after the
/// user asks to scan, and torn down when removed from the tree.
// ignore: one_member_abstracts
abstract class CodeScanner {
  Widget build({
    required ValueChanged<String> onCode,
    required VoidCallback onFailed,
    Key? key,
  });
}

/// Test double for [CodeScanner]: draws nothing, and lets a test show a code
/// or fail the camera through whichever view is live.
class FakeCodeScanner implements CodeScanner {
  final List<_FakeScannerViewState> _live = [];
  _FakeScannerView? _last;

  /// How many times a camera view was mounted.
  int starts = 0;

  bool get isLive => _live.isNotEmpty;

  void show(String code) {
    for (final view in [..._live]) {
      view.widget.onCode(code);
    }
  }

  void fail() {
    for (final view in [..._live]) {
      view.widget.onFailed();
    }
  }

  /// A code that arrives after the last view closed, as a platform event
  /// queued before the stop can.
  void showLate(String code) => _last?.onCode(code);

  @override
  Widget build({
    required ValueChanged<String> onCode,
    required VoidCallback onFailed,
    Key? key,
  }) => _FakeScannerView(
    scanner: this,
    onCode: onCode,
    onFailed: onFailed,
    key: key,
  );
}

class _FakeScannerView extends StatefulWidget {
  const _FakeScannerView({
    required this.scanner,
    required this.onCode,
    required this.onFailed,
    super.key,
  });

  final FakeCodeScanner scanner;
  final ValueChanged<String> onCode;
  final VoidCallback onFailed;

  @override
  State<_FakeScannerView> createState() => _FakeScannerViewState();
}

class _FakeScannerViewState extends State<_FakeScannerView> {
  @override
  void initState() {
    super.initState();
    widget.scanner
      ..starts += 1
      .._live.add(this)
      .._last = widget;
  }

  @override
  void dispose() {
    widget.scanner._live.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(key: ValueKey('fake-code-scanner'));
}
