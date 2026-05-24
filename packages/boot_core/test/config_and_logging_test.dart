import 'dart:io';

import 'package:boot_core/boot_core.dart';
import 'package:test/test.dart';

void main() {
  group('BootConfig', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('boot_config_test_');
      Directory.current = tmpDir;
    });

    tearDown(() {
      Directory.current = Platform.environment['HOME']!;
      tmpDir.deleteSync(recursive: true);
    });

    test('loads application.yml', () {
      File('${tmpDir.path}/application.yml').writeAsStringSync('''
server:
  port: 9090
  host: 0.0.0.0
app:
  name: myapp
''');
      Directory.current = tmpDir;
      final config = BootConfig();
      expect(config.get('server.port'), '9090');
      expect(config.get('server.host'), '0.0.0.0');
      expect(config.get('app.name'), 'myapp');
    });

    test('loads environment-specific YAML overlay', () {
      File('${tmpDir.path}/application.yml').writeAsStringSync('''
db:
  host: localhost
  port: 5432
''');
      File('${tmpDir.path}/application-prod.yml').writeAsStringSync('''
db:
  host: prod-db.internal
''');
      Directory.current = tmpDir;
      final config = BootConfig(activeEnv: 'prod');
      expect(config.get('db.host'), 'prod-db.internal'); // overridden
      expect(config.get('db.port'), '5432'); // from base
    });

    test('flattens nested YAML maps', () {
      File('${tmpDir.path}/application.yml').writeAsStringSync('''
boot:
  security:
    enabled: true
    intercept-url-map:
      - pattern: /api/**
        access: isAuthenticated()
''');
      Directory.current = tmpDir;
      final config = BootConfig();
      expect(config.get('boot.security.enabled'), 'true');
      expect(config.get('boot.security.intercept-url-map[0].pattern'), '/api/**');
      expect(config.get('boot.security.intercept-url-map[0].access'), 'isAuthenticated()');
    });

    test('YAML list items are indexed', () {
      File('${tmpDir.path}/application.yml').writeAsStringSync('''
tags:
  - alpha
  - beta
  - gamma
''');
      Directory.current = tmpDir;
      final config = BootConfig();
      expect(config.get('tags[0]'), 'alpha');
      expect(config.get('tags[1]'), 'beta');
      expect(config.get('tags[2]'), 'gamma');
      expect(config.getList('tags'), ['alpha', 'beta', 'gamma']);
    });

    test('getSubKeys works with YAML-loaded properties', () {
      File('${tmpDir.path}/application.yml').writeAsStringSync('''
datasources:
  primary:
    url: jdbc:postgresql://localhost/db1
  analytics:
    url: jdbc:postgresql://localhost/db2
''');
      Directory.current = tmpDir;
      final config = BootConfig();
      final keys = config.getSubKeys('datasources');
      expect(keys.toSet(), {'primary', 'analytics'});
    });

    test('getProperties returns flat map from YAML', () {
      File('${tmpDir.path}/application.yml').writeAsStringSync('''
db:
  host: localhost
  port: 5432
  name: mydb
''');
      Directory.current = tmpDir;
      final config = BootConfig();
      final props = config.getProperties('db');
      expect(props, {'host': 'localhost', 'port': '5432', 'name': 'mydb'});
    });

    test('programmatic overrides YAML values', () {
      File('${tmpDir.path}/application.yml').writeAsStringSync('''
server:
  port: 8080
''');
      Directory.current = tmpDir;
      final config = BootConfig(properties: {'server.port': '9090'});
      expect(config.get('server.port'), '9090');
    });

    test('missing YAML file does not crash', () {
      // No application.yml in tmpDir
      Directory.current = tmpDir;
      final config = BootConfig();
      expect(config.get('anything'), isNull);
    });

    test('null YAML values are skipped', () {
      File('${tmpDir.path}/application.yml').writeAsStringSync('''
key1: value1
key2:
key3: value3
''');
      Directory.current = tmpDir;
      final config = BootConfig();
      expect(config.get('key1'), 'value1');
      expect(config.get('key2'), isNull);
      expect(config.get('key3'), 'value3');
    });

    test('programmatic properties are resolved', () {
      final config = BootConfig(properties: {'app.name': 'test'});
      expect(config.get('app.name'), 'test');
    });

    test('returns null for missing key', () {
      final config = BootConfig();
      expect(config.get('nonexistent'), isNull);
    });

    test('programmatic overrides YAML', () {
      final config = BootConfig(properties: {'boot.env': 'prod'});
      expect(config.get('boot.env'), 'prod');
    });

    test('CLI args override programmatic', () {
      final config = BootConfig(
        properties: {'server.port': '8080'},
        args: ['--server.port=9090'],
      );
      expect(config.get('server.port'), '9090');
    });

    test('CLI args with space separator', () {
      final config = BootConfig(args: ['--server.port', '9090']);
      expect(config.get('server.port'), '9090');
    });

    test('CLI flag without value defaults to true', () {
      final config = BootConfig(args: ['--debug']);
      expect(config.get('debug'), 'true');
    });

    test('CLI args with equals containing equals', () {
      final config = BootConfig(args: ['--filter=name=foo']);
      expect(config.get('filter'), 'name=foo');
    });

    test('activeEnv is stored', () {
      final config = BootConfig(activeEnv: 'test');
      expect(config.get('boot.env'), 'test');
    });

    test('addAll adds properties', () {
      final config = BootConfig();
      config.addAll({'new.key': 'value'});
      expect(config.get('new.key'), 'value');
    });

    test('resolvePlaceholder with value present', () {
      final config = BootConfig(properties: {'server.port': '9090'});
      expect(config.resolvePlaceholder('\${server.port:8080}'), '9090');
    });

    test('resolvePlaceholder with default fallback', () {
      final config = BootConfig();
      expect(config.resolvePlaceholder('\${server.port:8080}'), '8080');
    });

    test('resolvePlaceholder without default returns empty', () {
      final config = BootConfig();
      expect(config.resolvePlaceholder('\${missing.key}'), '');
    });

    test('resolvePlaceholder non-placeholder returns as-is', () {
      final config = BootConfig();
      expect(config.resolvePlaceholder('plain-value'), 'plain-value');
    });

    test('isPlaceholder detects placeholders', () {
      expect(BootConfig.isPlaceholder('\${key}'), isTrue);
      expect(BootConfig.isPlaceholder('\${key:default}'), isTrue);
      expect(BootConfig.isPlaceholder('plain'), isFalse);
    });

    test('getList returns indexed values', () {
      final config = BootConfig(properties: {
        'items[0]': 'a',
        'items[1]': 'b',
        'items[2]': 'c',
      });
      expect(config.getList('items'), ['a', 'b', 'c']);
    });

    test('getList returns null for missing key', () {
      final config = BootConfig();
      expect(config.getList('missing'), isNull);
    });

    test('getList splits comma-separated single value', () {
      final config = BootConfig(properties: {'tags': 'a, b, c'});
      expect(config.getList('tags'), ['a', 'b', 'c']);
    });

    test('getSubKeys returns empty for unknown prefix in programmatic', () {
      final config = BootConfig();
      expect(config.getSubKeys('nonexistent'), isEmpty);
    });
  });

  group('BootContext', () {
    test('set and get values', () {
      final ctx = BootContext();
      ctx.set('key', 'value');
      expect(ctx.get('key'), 'value');
    });

    test('get returns null for missing key', () {
      final ctx = BootContext();
      expect(ctx.get('missing'), isNull);
    });

    test('run makes context available via Zone', () {
      final ctx = BootContext();
      ctx.set('name', 'test');
      ctx.run(() {
        expect(BootContext.current, isNotNull);
        expect(BootContext.current!.get('name'), 'test');
      });
    });

    test('current is null outside of run', () {
      expect(BootContext.current, isNull);
    });

    test('traceId from traceparent', () {
      final ctx = BootContext();
      ctx.set(BootContextKeys.traceparent, Traceparent(traceId: 'abc123', parentId: 'def456'));
      expect(ctx.traceId, 'abc123');
      expect(ctx.spanId, 'def456');
    });

    test('traceId from direct key overrides traceparent', () {
      final ctx = BootContext();
      ctx.set(BootContextKeys.traceId, 'direct');
      ctx.set(BootContextKeys.traceparent, Traceparent(traceId: 'from-tp', parentId: 'x'));
      expect(ctx.traceId, 'direct');
    });

    test('traceparent getter', () {
      final ctx = BootContext();
      final tp = Traceparent(traceId: 'a', parentId: 'b');
      ctx.set(BootContextKeys.traceparent, tp);
      expect(ctx.traceparent, tp);
    });
  });

  group('Traceparent', () {
    test('generate creates valid IDs', () {
      final tp = Traceparent.generate();
      expect(tp.traceId.length, 32);
      expect(tp.parentId.length, 16);
    });

    test('parse valid header', () {
      final tp = Traceparent.parse('00-abcdef1234567890abcdef1234567890-1234567890abcdef-01');
      expect(tp, isNotNull);
      expect(tp!.traceId, 'abcdef1234567890abcdef1234567890');
      expect(tp.parentId, '1234567890abcdef');
    });

    test('parse returns null for null input', () {
      expect(Traceparent.parse(null), isNull);
    });

    test('parse returns null for invalid format', () {
      expect(Traceparent.parse('invalid'), isNull);
      expect(Traceparent.parse('too-short'), isNull);
    });

    test('toString produces W3C format', () {
      final tp = Traceparent(traceId: 'aaa', parentId: 'bbb');
      expect(tp.toString(), '00-aaa-bbb-01');
    });
  });

  group('BootContextKeys', () {
    test('constants are defined', () {
      expect(BootContextKeys.httpRequestMethod, 'http.method');
      expect(BootContextKeys.urlPath, 'http.path');
      expect(BootContextKeys.traceparent, 'traceparent');
      expect(BootContextKeys.traceId, 'traceId');
    });
  });

  group('Exceptions', () {
    test('BeanNotFoundException toString without name', () {
      final e = BeanNotFoundException(String);
      expect(e.toString(), contains('String'));
      expect(e.toString(), isNot(contains('name')));
    });

    test('BeanNotFoundException toString with name', () {
      final e = BeanNotFoundException(String, name: 'myBean');
      expect(e.toString(), contains('myBean'));
    });

    test('CircularDependencyException toString shows chain', () {
      final e = CircularDependencyException([String, int, String]);
      expect(e.toString(), contains('String -> int -> String'));
    });

    test('NonUniqueBeanException toString shows candidates', () {
      final e = NonUniqueBeanException(String, ['BeanA', 'BeanB']);
      expect(e.toString(), contains('BeanA'));
      expect(e.toString(), contains('BeanB'));
    });
  });

  group('Logger', () {
    test('Logger creates with name', () {
      final logger = Logger('MyService');
      expect(logger.name, 'MyService');
    });

    test('LogManager sets root level', () {
      LogManager().rootLevel = Level.error;
      expect(LogManager().rootLevel, Level.error);
      LogManager().rootLevel = Level.info; // reset
    });

    test('LogManager setLevel and getLevel per logger', () {
      LogManager().setLevel('db', Level.debug);
      expect(LogManager().getLevel('db'), Level.debug);
      expect(LogManager().getLevel('unknown'), LogManager().rootLevel);
    });

    test('LogManager emit filters by level', () {
      final records = <LogRecord>[];
      LogManager().setHandlers([_CapturingHandler(records)]);
      LogManager().rootLevel = Level.warn;

      LogManager().emit(LogRecord(timestamp: DateTime.now(), level: Level.info, logger: 'x', message: 'skip'));
      LogManager().emit(LogRecord(timestamp: DateTime.now(), level: Level.warn, logger: 'x', message: 'keep'));
      LogManager().emit(LogRecord(timestamp: DateTime.now(), level: Level.error, logger: 'x', message: 'keep2'));

      expect(records.length, 2);
      expect(records[0].message, 'keep');
      expect(records[1].message, 'keep2');

      LogManager().rootLevel = Level.info;
      LogManager().setHandlers([ConsoleLogHandler()]);
    });

    test('LogManager addHandler appends', () {
      final records = <LogRecord>[];
      LogManager().setHandlers([ConsoleLogHandler()]);
      LogManager().addHandler(_CapturingHandler(records));
      LogManager().emit(LogRecord(timestamp: DateTime.now(), level: Level.info, logger: 'x', message: 'hi'));
      expect(records.length, 1);
      LogManager().setHandlers([ConsoleLogHandler()]);
    });

    test('Logger.trace/debug/info/warn/error emit records', () {
      final records = <LogRecord>[];
      LogManager().setHandlers([_CapturingHandler(records)]);
      LogManager().rootLevel = Level.trace;

      final log = Logger('Test');
      log.trace('t');
      log.debug('d');
      log.info('i');
      log.warn('w', null, Exception('oops'));
      log.error('e', {'code': 500}, Exception('fail'), StackTrace.current);

      expect(records.length, 5);
      expect(records[0].level, Level.trace);
      expect(records[3].error.toString(), contains('oops'));
      expect(records[4].stackTrace, isNotNull);
      expect(records[4].fields['code'], 500);

      LogManager().rootLevel = Level.info;
      LogManager().setHandlers([ConsoleLogHandler()]);
    });

    test('ConsoleLogHandler text format with all fields', () {
      final handler = ConsoleLogHandler(json: false);
      handler.handle(LogRecord(
        timestamp: DateTime.now(),
        level: Level.error,
        logger: 'Svc',
        message: 'fail',
        fields: {'key': 'val'},
        traceId: 'abc',
        spanId: '123',
        error: Exception('boom'),
        stackTrace: StackTrace.current,
      ));
    });

    test('ConsoleLogHandler text format without optional fields', () {
      final handler = ConsoleLogHandler(json: false);
      handler.handle(LogRecord(
        timestamp: DateTime.now(),
        level: Level.info,
        logger: 'Test',
        message: 'simple',
      ));
    });

    test('ConsoleLogHandler json format with all fields', () {
      final handler = ConsoleLogHandler(json: true);
      handler.handle(LogRecord(
        timestamp: DateTime.now(),
        level: Level.warn,
        logger: 'Test',
        message: 'warning',
        fields: {'key': 'value'},
        traceId: 'trace1',
        spanId: 'span1',
        error: Exception('err'),
      ));
    });

    test('LogRecord stores all fields', () {
      final now = DateTime.now();
      final record = LogRecord(
        timestamp: now,
        level: Level.error,
        logger: 'Svc',
        message: 'fail',
        fields: {'code': 500},
        traceId: 'abc',
        spanId: '123',
        error: Exception('oops'),
      );
      expect(record.timestamp, now);
      expect(record.level, Level.error);
      expect(record.logger, 'Svc');
      expect(record.message, 'fail');
      expect(record.fields['code'], 500);
      expect(record.traceId, 'abc');
      expect(record.spanId, '123');
      expect(record.error, isA<Exception>());
    });
  });
}

class _CapturingHandler implements LogHandler {
  final List<LogRecord> records;
  _CapturingHandler(this.records);

  @override
  void handle(LogRecord record) => records.add(record);
}
