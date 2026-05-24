// coverage:ignore-file
import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:boot_core/boot_core.dart' show Logger;

import '../websocket/websocket_server.dart';
import 'router.dart';

/// TLS client authentication mode.
enum ClientAuth { none, optional, required }

/// SSL/TLS configuration for the server.
class SslConfig {
  final String certPath;
  final String keyPath;
  final String? trustStorePath;
  final ClientAuth clientAuth;

  SslConfig({
    required this.certPath,
    required this.keyPath,
    this.trustStorePath,
    this.clientAuth = ClientAuth.none,
  });
}

/// Boot's HTTP server. Wraps shelf_io internally.
/// Protected by a zone guard — unhandled exceptions log and recover, never crash.
class BootServer {
  static final _log = Logger('BootServer');

  final BootRouter router;
  final int port;
  final String address;
  final WebSocketServer? webSocketServer;
  final SslConfig? sslConfig;
  HttpServer? _server;

  BootServer({
    required this.router,
    this.port = 8080,
    this.address = '0.0.0.0',
    this.webSocketServer,
    this.sslConfig,
  });

  /// Start the HTTP server.
  Future<void> start() async {
    if (webSocketServer != null) {
      _server = await _bind();
      final shelfHandler = router.build();
      _server!.listen((request) async {
        try {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            final handled = await webSocketServer!.handleUpgrade(request);
            if (!handled) {
              request.response.statusCode = 404;
              request.response.write('WebSocket endpoint not found');
              await request.response.close();
            }
          } else {
            await shelf_io.handleRequest(request, shelfHandler);
          }
        } catch (e, stack) {
          _log.error('Unhandled exception in request pipeline', null, e, stack);
          try {
            request.response.statusCode = 500;
            request.response.write('Internal Server Error');
            await request.response.close();
          } catch (_) {}
        }
      });
    } else {
      final shelfHandler = const shelf.Pipeline()
          .addMiddleware(_recoveryMiddleware)
          .addHandler(router.build());
      if (sslConfig != null) {
        _server = await _bind();
        _server!.listen((request) async {
          try {
            await shelf_io.handleRequest(request, shelfHandler);
          } catch (e, stack) {
            _log.error('Unhandled exception', null, e, stack);
          }
        });
      } else {
        _server = await shelf_io.serve(shelfHandler, address, port);
      }
    }
  }

  /// Bind with or without TLS.
  Future<HttpServer> _bind() async {
    if (sslConfig != null) {
      final ctx = SecurityContext()
        ..useCertificateChain(sslConfig!.certPath)
        ..usePrivateKey(sslConfig!.keyPath);
      if (sslConfig!.trustStorePath != null) {
        ctx.setTrustedCertificates(sslConfig!.trustStorePath!);
      }
      final server = await HttpServer.bindSecure(address, port, ctx,
          requestClientCertificate: sslConfig!.clientAuth != ClientAuth.none);
      return server;
    }
    return HttpServer.bind(address, port);
  }

  /// Middleware that catches any unhandled exception and returns 500.
  static shelf.Middleware get _recoveryMiddleware => (innerHandler) {
    return (request) async {
      try {
        return await innerHandler(request);
      } catch (e, stack) {
        _log.error('Unhandled exception in request pipeline', null, e, stack);
        return shelf.Response.internalServerError(
          body: '{"error":"Internal Server Error"}',
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };

  /// Stop the HTTP server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  /// Get the underlying shelf Handler (for testing).
  shelf.Handler get handler => router.build();
}
