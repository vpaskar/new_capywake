import 'dart:async';

import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:capywake/core/games/qr_treasure_hunt.dart';
import 'package:capywake/data/camera/code_scanner.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/game_header.dart';
import 'package:capywake/features/games/game_launch.dart';
import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:capywake/features/ringing/game_ringing_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// QR Treasure Hunt: walk to the saved checkpoint and scan its code. The
/// camera runs only after "Scan QR" and stops on a win, a tap or a pause.
class QrTreasureHuntView extends GameRingingView {
  const QrTreasureHuntView({
    required this.scanner,
    required this.checkpoint,
    required super.onProgress,
    required super.onCompleted,
    required super.reduceMotion,
    super.key,
  });

  QrTreasureHuntView.fromLaunch(GameLaunch launch, {Key? key})
    : this(
        scanner: launch.scanner,
        checkpoint: launch.qrCheckpoint,
        onProgress: launch.onProgress,
        onCompleted: launch.onCompleted,
        reduceMotion: launch.reduceMotion,
        key: key,
      );

  final CodeScanner scanner;
  final QrCheckpoint? checkpoint;

  static const fieldHeight = 118.0;
  static const scanButtonHeight = 56.0;
  static const bracketSize = 96.0;

  /// `collection_05` is 240 px wide: sharp to 80 pt at 3×.
  static const capySize = 72.0;
  static const pulse = Duration(milliseconds: 900);
  static const pulseRest = Duration(milliseconds: 600);
  static const pulseScale = 0.06;

  @override
  State<QrTreasureHuntView> createState() => _QrTreasureHuntViewState();
}

class _QrTreasureHuntViewState extends State<QrTreasureHuntView>
    with WidgetsBindingObserver {
  QrHuntRound _round = QrHuntRound.start();
  bool _scanning = false;
  bool _completionReported = false;
  bool _precached = false;
  int _pulseCycle = 0;
  Timer? _rest;

  bool get _moves =>
      !widget.reduceMotion && !MediaQuery.accessibleNavigationOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_moves) _stopPulse();
    if (_precached) return;
    _precached = true;
    unawaited(
      precacheImage(
        AssetImage(CapyArt.byId('game.capy.detective').path),
        context,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _scanning) {
      setState(() => _scanning = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPulse();
    super.dispose();
  }

  void _stopPulse() {
    _rest?.cancel();
    _rest = null;
  }

  void _pulseEnded() {
    if (!mounted || !_moves || _scanning || _round.isComplete) return;
    _rest = Timer(QrTreasureHuntView.pulseRest, () {
      if (mounted) setState(() => _pulseCycle++);
    });
  }

  void _toggleCamera() {
    if (_round.isComplete) return;
    setState(() {
      _scanning = !_scanning;
      if (_scanning) _round = _round.newLook();
    });
  }

  void _onCode(String code) {
    if (!mounted || !_scanning || _round.isComplete) return;
    final next = _round.scan(code, widget.checkpoint);
    if (identical(next, _round)) return;
    _apply(next);
  }

  void _onFailed() {
    if (!mounted || !_scanning) return;
    setState(() => _scanning = false);
    _apply(_round.cameraFailed());
  }

  void _apply(QrHuntRound next) {
    setState(() {
      _round = next;
      if (next.isComplete) _scanning = false;
    });
    widget.onProgress(next.challenge);
    if (next.isComplete && !_completionReported) {
      _completionReported = true;
      _stopPulse();
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outcome = switch (_round.lastOutcome) {
      QrHuntOutcome.wrongCode => l10n.gameQrWrongCode,
      QrHuntOutcome.cameraFailed => l10n.gameQrCameraFailed,
      null => widget.checkpoint == null ? l10n.gameQrNoCheckpoint : null,
    };

    return CapyCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameHeader(
            title: l10n.gameQrTreasureHunt,
            instruction: l10n.gameQrInstruction,
            done: _round.isComplete ? 1 : 0,
            total: 1,
          ),
          const SizedBox(height: CapySpacing.md),
          SizedBox(
            height: QrTreasureHuntView.fieldHeight,
            child: ExcludeSemantics(child: _field()),
          ),
          const SizedBox(height: CapySpacing.sm),
          _scanButton(l10n),
          const SizedBox(height: CapySpacing.sm),
          GameOutcomeLine(
            text: outcome,
            serial: _round.struggles,
            reserveFor: [
              l10n.gameQrWrongCode,
              l10n.gameQrCameraFailed,
              l10n.gameQrNoCheckpoint,
            ],
          ),
        ],
      ),
    );
  }

  /// A game control, not the orange call to action: Snooze sits just below
  /// it, and a slip between twin buttons would snooze the alarm.
  Widget _scanButton(AppLocalizations l10n) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final done = _round.isComplete;
    final label = _scanning ? l10n.gameQrStopScan : l10n.gameQrScan;

    return Semantics(
      button: true,
      enabled: !done,
      label: label,
      onTap: done ? null : _toggleCamera,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('qr-hunt-scan'),
        behavior: HitTestBehavior.opaque,
        onTap: done ? null : _toggleCamera,
        child: Container(
          height: QrTreasureHuntView.scanButtonHeight,
          decoration: BoxDecoration(
            color: dark ? CapyColors.darkSurface : CapyColors.surface,
            borderRadius: BorderRadius.circular(CapyRadius.pill),
            border: Border.all(color: ink, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _scanning
                    ? Icons.videocam_off_rounded
                    : Icons.qr_code_scanner_rounded,
                color: ink,
              ),
              const SizedBox(width: CapySpacing.xs),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: CapyType.label.copyWith(color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(CapyRadius.lg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_scanning)
            widget.scanner.build(
              key: const ValueKey('qr-hunt-camera'),
              onCode: _onCode,
              onFailed: _onFailed,
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt,
              ),
              child: Center(
                child: Image.asset(
                  CapyArt.byId('game.capy.detective').path,
                  key: const ValueKey('qr-hunt-capy'),
                  width: QrTreasureHuntView.capySize,
                  height: QrTreasureHuntView.capySize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          Center(child: _brackets(dark: dark)),
        ],
      ),
    );
  }

  Widget _brackets({required bool dark}) {
    final color = _scanning
        ? Colors.white
        : (dark ? CapyColors.darkInk : CapyColors.cocoa);
    final frame = CustomPaint(
      key: const ValueKey('qr-hunt-brackets'),
      size: const Size.square(QrTreasureHuntView.bracketSize),
      painter: _BracketPainter(color: color),
    );
    if (!_moves || _scanning || _round.isComplete) return frame;
    return TweenAnimationBuilder<double>(
      key: ValueKey(('pulse', _pulseCycle)),
      tween: Tween(begin: 0, end: 1),
      duration: QrTreasureHuntView.pulse,
      onEnd: _pulseEnded,
      builder: (context, t, child) => Transform.scale(
        scale: 1 + QrTreasureHuntView.pulseScale * (1 - (2 * t - 1).abs()),
        child: child,
      ),
      child: frame,
    );
  }
}

class _BracketPainter extends CustomPainter {
  const _BracketPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final arm = size.shortestSide * 0.28;
    final w = size.width;
    final h = size.height;
    for (final (corner, dx, dy) in [
      (Offset.zero, 1.0, 1.0),
      (Offset(w, 0), -1.0, 1.0),
      (Offset(0, h), 1.0, -1.0),
      (Offset(w, h), -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(corner, corner + Offset(arm * dx, 0), paint)
        ..drawLine(corner, corner + Offset(0, arm * dy), paint);
    }
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.color != color;
}
