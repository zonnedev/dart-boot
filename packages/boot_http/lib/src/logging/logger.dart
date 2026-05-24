// coverage:ignore-file
import 'dart:convert';

import '../context/boot_context.dart';

/// Log severity levels.
enum Level { trace, debug, info, warn, error }

/// A structured log record.
class LogRecord {
  final DateTime timestamp;
  final Level level;
  final String logger;
  final String message;
  final Map<String, dynamic> fields;
  final String? traceId;
  final String? spanId;
  final Object? error;
  final StackTrace? stackTrace;

  LogRecord({
    required this.timestamp,
    required this.level,
    required this.logger,
    required this.message,
    this.fields = const {},
    this.traceId,
    this.spanId,
    this.error,
    this.stackTrace,
  });
}

/// Interface for log output. Implement to send logs to custom destinations.
abstract class LogHandler {
  void handle(LogRecord record);
}

/// Default console log handler — outputs JSON or text to stdout.
class ConsoleLogHandler implements LogHandler {
  final bool json;

  ConsoleLogHandler({this.json = false});

  @override
  void handle(LogRecord record) {
    if (json) {
      _writeJson(record);
    } else {
      _writeText(record);
    }
  }

  void _writeJson(LogRecord record) {
    final map = <String, dynamic>{
      'ts': record.timestamp.toUtc().toIso8601String(),
      'level': record.level.name.toUpperCase(),
      'logger': record.logger,
      'msg': record.message,
    };
    if (record.traceId != null) map['traceId'] = record.traceId;
    if (record.spanId != null) map['spanId'] = record.spanId;
    if (record.fields.isNotEmpty) map.addAll(record.fields);
    if (record.error != null) map['error'] = record.error.toString();
    print(jsonEncode(map));
  }

  void _writeText(LogRecord record) {
    final buf = StringBuffer();
    buf.write('${record.timestamp.toIso8601String()} ');
    buf.write('[${record.level.name.toUpperCase().padRight(5)}] ');
    buf.write('${record.logger}: ${record.message}');
    if (record.traceId != null) {
      buf.write(' [${record.traceId}');
      if (record.spanId != null) buf.write(',${record.spanId}');
      buf.write(']');
    }
    if (record.fields.isNotEmpty) buf.write(' ${record.fields}');
    if (record.error != null) buf.write(' ERROR: ${record.error}');
    print(buf);
    if (record.stackTrace != null) print(record.stackTrace);
  }
}

/// Logger factory and registry.
class LogManager {
  static final _instance = LogManager._();
  factory LogManager() => _instance;
  LogManager._();

  Level rootLevel = Level.info;
  final Map<String, Level> _levels = {};
  final List<LogHandler> _handlers = [ConsoleLogHandler()];

  void setLevel(String logger, Level level) => _levels[logger] = level;
  Level getLevel(String logger) => _levels[logger] ?? rootLevel;

  void addHandler(LogHandler handler) => _handlers.add(handler);
  void setHandlers(List<LogHandler> handlers) {
    _handlers.clear();
    _handlers.addAll(handlers);
  }

  void emit(LogRecord record) {
    if (record.level.index < getLevel(record.logger).index) return;
    for (final handler in _handlers) {
      handler.handle(record);
    }
  }
}

/// Lightweight logger — create with a name, use anywhere.
class Logger {
  final String name;

  Logger(this.name);

  void trace(String msg, [Map<String, dynamic>? fields]) => _log(Level.trace, msg, fields);
  void debug(String msg, [Map<String, dynamic>? fields]) => _log(Level.debug, msg, fields);
  void info(String msg, [Map<String, dynamic>? fields]) => _log(Level.info, msg, fields);
  void warn(String msg, [Map<String, dynamic>? fields, Object? error]) => _log(Level.warn, msg, fields, error);
  void error(String msg, [Map<String, dynamic>? fields, Object? error, StackTrace? stack]) =>
      _log(Level.error, msg, fields, error, stack);

  void _log(Level level, String msg, [Map<String, dynamic>? fields, Object? err, StackTrace? stack]) {
    final ctx = BootContext.current;
    LogManager().emit(LogRecord(
      timestamp: DateTime.now(),
      level: level,
      logger: name,
      message: msg,
      fields: fields ?? const {},
      traceId: ctx?.traceId,
      spanId: ctx?.spanId,
      error: err,
      stackTrace: stack,
    ));
  }
}
