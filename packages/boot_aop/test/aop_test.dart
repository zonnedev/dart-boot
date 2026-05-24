import 'package:boot_aop/boot_aop.dart';
import 'package:boot_core/boot_core.dart';
import 'package:test/test.dart';

class _LoggingInterceptor implements MethodInterceptor {
  final List<String> log;
  final String name;
  _LoggingInterceptor(this.log, this.name);

  @override
  dynamic intercept(InvocationContext ctx) {
    log.add('$name:before:${ctx.methodName}');
    final result = ctx.proceed();
    log.add('$name:after:${ctx.methodName}');
    return result;
  }
}

class _CachingInterceptor implements MethodInterceptor {
  final cache = <String, dynamic>{};

  @override
  dynamic intercept(InvocationContext ctx) {
    final key = '${ctx.methodName}:${ctx.args}';
    if (cache.containsKey(key)) return cache[key];
    final result = ctx.proceed();
    cache[key] = result;
    return result;
  }
}

class _ShortCircuitInterceptor implements MethodInterceptor {
  @override
  dynamic intercept(InvocationContext ctx) => 'short-circuited';
}

class _AsyncLoggingInterceptor implements MethodInterceptor {
  final List<String> log;
  _AsyncLoggingInterceptor(this.log);

  @override
  dynamic intercept(InvocationContext ctx) async {
    log.add('async:before');
    final result = await ctx.proceed();
    log.add('async:after');
    return result;
  }
}

void main() {
  group('InterceptorChain.invoke (sync)', () {
    test('no interceptors calls original directly', () {
      var called = false;
      final chain = InterceptorChain(
        interceptors: [],
        methodName: 'doWork',
        args: [],
        target: null,
        originalMethod: () { called = true; return 42; },
      );
      expect(chain.invoke(), 42);
      expect(called, isTrue);
    });

    test('single interceptor wraps the call', () {
      final log = <String>[];
      final chain = InterceptorChain(
        interceptors: [_LoggingInterceptor(log, 'timing')],
        methodName: 'getUser',
        args: ['id-1'],
        target: null,
        originalMethod: () => 'user-data',
      );
      final result = chain.invoke();
      expect(result, 'user-data');
      expect(log, ['timing:before:getUser', 'timing:after:getUser']);
    });

    test('multiple interceptors chain in order', () {
      final log = <String>[];
      final chain = InterceptorChain(
        interceptors: [
          _LoggingInterceptor(log, 'outer'),
          _LoggingInterceptor(log, 'inner'),
        ],
        methodName: 'save',
        args: [],
        target: null,
        originalMethod: () { log.add('original'); return 'ok'; },
      );
      chain.invoke();
      expect(log, ['outer:before:save', 'inner:before:save', 'original', 'inner:after:save', 'outer:after:save']);
    });

    test('interceptor can short-circuit (skip original)', () {
      var originalCalled = false;
      final chain = InterceptorChain(
        interceptors: [_ShortCircuitInterceptor()],
        methodName: 'x',
        args: [],
        target: null,
        originalMethod: () { originalCalled = true; return 'real'; },
      );
      expect(chain.invoke(), 'short-circuited');
      expect(originalCalled, isFalse);
    });

    test('caching interceptor returns cached on second call', () {
      var callCount = 0;
      final caching = _CachingInterceptor();

      dynamic run() => InterceptorChain(
        interceptors: [caching],
        methodName: 'fetch',
        args: ['key1'],
        target: null,
        originalMethod: () { callCount++; return 'data'; },
      ).invoke();

      expect(run(), 'data');
      expect(run(), 'data');
      expect(callCount, 1); // only called once
    });

    test('InvocationContext provides method name, args, target', () {
      late InvocationContext captured;
      final target = Object();
      final chain = InterceptorChain(
        interceptors: [_CapturingInterceptor((ctx) => captured = ctx)],
        methodName: 'process',
        args: [1, 'two', true],
        target: target,
        originalMethod: () => null,
      );
      chain.invoke();
      expect(captured.methodName, 'process');
      expect(captured.args, [1, 'two', true]);
      expect(identical(captured.target, target), isTrue);
    });
  });

  group('InterceptorChain.invokeAsync', () {
    test('no interceptors calls original directly', () async {
      final chain = InterceptorChain(
        interceptors: [],
        methodName: 'fetch',
        args: [],
        target: null,
        originalMethod: () async => 'async-result',
      );
      expect(await chain.invokeAsync(), 'async-result');
    });

    test('async interceptor wraps the call', () async {
      final log = <String>[];
      final chain = InterceptorChain(
        interceptors: [_AsyncLoggingInterceptor(log)],
        methodName: 'load',
        args: [],
        target: null,
        originalMethod: () async { log.add('original'); return 'data'; },
      );
      final result = await chain.invokeAsync();
      expect(result, 'data');
      expect(log, ['async:before', 'original', 'async:after']);
    });

    test('multiple async interceptors chain correctly', () async {
      final log = <String>[];
      final chain = InterceptorChain(
        interceptors: [
          _LoggingInterceptor(log, 'a'),
          _LoggingInterceptor(log, 'b'),
        ],
        methodName: 'op',
        args: [],
        target: null,
        originalMethod: () async { log.add('real'); return 99; },
      );
      final result = await chain.invokeAsync();
      expect(result, 99);
      expect(log, ['a:before:op', 'b:before:op', 'real', 'b:after:op', 'a:after:op']);
    });
  });

  group('AOP with DI container', () {
    test('interceptors registered and retrieved from container', () {
      final container = BeanContainer();
      final log = <String>[];
      final interceptor = _LoggingInterceptor(log, 'timing');

      // Simulate: container.registerInterceptor(Timed, timedInterceptor)
      container.registerInterceptor(String, interceptor); // using String as fake annotation type

      final interceptors = container.getInterceptors(String);
      expect(interceptors.length, 1);

      // Simulate proxy calling the chain
      final chain = InterceptorChain(
        interceptors: interceptors,
        methodName: 'getProduct',
        args: ['42'],
        target: null,
        originalMethod: () => {'id': '42'},
      );
      final result = chain.invoke();
      expect(result, {'id': '42'});
      expect(log, ['timing:before:getProduct', 'timing:after:getProduct']);
    });

    test('multiple interceptors from different annotations', () {
      final container = BeanContainer();
      final log = <String>[];

      container.registerInterceptor(int, _LoggingInterceptor(log, 'timed'));
      container.registerInterceptor(double, _CachingInterceptor());

      // Simulate proxy with both @Timed and @Cached
      final allInterceptors = [
        ...container.getInterceptors(int),
        ...container.getInterceptors(double),
      ];

      var callCount = 0;
      dynamic run() => InterceptorChain(
        interceptors: allInterceptors,
        methodName: 'getData',
        args: ['x'],
        target: null,
        originalMethod: () { callCount++; return 'result'; },
      ).invoke();

      expect(run(), 'result');
      expect(run(), 'result');
      expect(callCount, 1); // cached after first call
      expect(log.where((l) => l.startsWith('timed:before')).length, 2); // timed ran twice
    });

    test('container without interceptors returns empty list', () {
      final container = BeanContainer();
      expect(container.getInterceptors(String), isEmpty);
    });
  });
}

class _CapturingInterceptor implements MethodInterceptor {
  final void Function(InvocationContext) _capture;
  _CapturingInterceptor(this._capture);

  @override
  dynamic intercept(InvocationContext ctx) {
    _capture(ctx);
    return ctx.proceed();
  }
}
