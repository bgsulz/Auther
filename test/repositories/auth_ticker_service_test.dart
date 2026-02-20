import 'package:auther/customization/config.dart';
import 'package:auther/repositories/auth_ticker_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthTicker', () {
    test('emits a future seed immediately on start', () {
      fakeAsync((async) {
        final ticker = AuthTicker();
        final emitted = <int>[];
        ticker.seedStream.listen(emitted.add);

        ticker.start();
        async.flushMicrotasks();

        expect(emitted, isNotEmpty);
        final now = DateTime.now().millisecondsSinceEpoch;
        expect(emitted.last, greaterThan(now));
        expect(emitted.last - now, lessThanOrEqualTo(Config.intervalMillis));
        ticker.dispose();
      });
    });

    test('self-heals after delayed timer callbacks', () {
      fakeAsync((async) {
        final ticker = AuthTicker();
        final emitted = <int>[];
        ticker.seedStream.listen(emitted.add);

        ticker.start();
        async.flushMicrotasks();
        async.elapseBlocking(const Duration(minutes: 3));
        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();

        final now = DateTime.now().millisecondsSinceEpoch;
        expect(emitted.last, greaterThan(now));
        expect(emitted.last - now, lessThanOrEqualTo(Config.intervalMillis));
        ticker.dispose();
      });
    });
  });
}
