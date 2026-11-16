import 'package:capywake/core/engine/alarm_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds the message the way the platform adapters do — by interpolating what
/// was being attempted.
///
/// Deliberately a function rather than a literal. Every other use of
/// [AlarmEngineException] in the suite is a `const` invocation, and `const` is
/// canonicalised at compile time, so the constructor never actually ran: the
/// type shipped through thirty phases with its shape unasserted. A `const`
/// here would reintroduce exactly that hole, which is also why the analyzer
/// cannot suggest one.
String _diagnostic(String what) => 'failed to $what';

void main() {
  group('AlarmEngineException', () {
    test('carries a diagnostic message', () {
      final error = AlarmEngineException(_diagnostic('arm alarm a1'));
      expect(error.message, 'failed to arm alarm a1');
      expect(error.cause, isNull);
    });

    test('carries the underlying platform error when there is one', () {
      final cause = StateError('plugin exploded');
      final error = AlarmEngineException(_diagnostic('arm'), cause: cause);
      expect(error.cause, same(cause));
    });

    test('is an Exception, so a caller can catch it as one', () {
      expect(AlarmEngineException(_diagnostic('arm')), isA<Exception>());
    });

    test('describes itself without a cause', () {
      // Diagnostic only — this string is English and never reaches a user.
      // User-facing wording comes from `ReliabilityCopyService`.
      expect(
        AlarmEngineException(_diagnostic('arm')).toString(),
        'AlarmEngineException: failed to arm',
      );
    });

    test('describes itself with a cause', () {
      expect(
        AlarmEngineException(
          _diagnostic('arm'),
          cause: StateError('plugin exploded'),
        ).toString(),
        contains('cause: Bad state: plugin exploded'),
      );
    });
  });
}
