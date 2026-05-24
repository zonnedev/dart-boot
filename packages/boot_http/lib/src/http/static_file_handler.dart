import 'dart:io';
import 'package:path/path.dart' as p;

/// Serves static files from a directory.
class StaticFileHandler {
  final String urlPath;
  final String directory;
  final String index;
  final int maxAge;
  final bool etag;
  final bool gzip;

  static const _mimeTypes = {
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
    '.ttf': 'font/ttf',
    '.otf': 'font/otf',
    '.webp': 'image/webp',
    '.webm': 'video/webm',
    '.mp4': 'video/mp4',
    '.pdf': 'application/pdf',
    '.xml': 'application/xml',
    '.txt': 'text/plain; charset=utf-8',
    '.map': 'application/json',
    '.wasm': 'application/wasm',
  };

  StaticFileHandler({
    required this.urlPath,
    required this.directory,
    this.index = 'index.html',
    this.maxAge = 3600,
    this.etag = true,
    this.gzip = true,
  });

  /// Try to serve a static file. Returns null if not a static path or file not found.
  Future<_StaticResponse?> handle(String method, String requestPath, Map<String, String> requestHeaders) async {
    if (method != 'GET' && method != 'HEAD') return null;

    // Check if request matches our URL prefix
    final prefix = urlPath.endsWith('/') ? urlPath : '$urlPath/';
    if (!requestPath.startsWith(prefix) && requestPath != urlPath) return null;

    // Extract relative path
    var relativePath = requestPath.substring(urlPath.length);
    if (relativePath.startsWith('/')) relativePath = relativePath.substring(1);
    if (relativePath.isEmpty) relativePath = index;

    // Security: block path traversal
    final normalized = p.normalize(relativePath);
    if (normalized.startsWith('..') || p.isAbsolute(normalized)) return null;

    final filePath = p.join(directory, normalized);
    var file = File(filePath);

    // If it's a directory, try index file
    if (await FileSystemEntity.isDirectory(filePath)) {
      file = File(p.join(filePath, index));
    }

    if (!await file.exists()) return null;

    final stat = await file.stat();
    final ext = p.extension(file.path).toLowerCase();
    final contentType = _mimeTypes[ext] ?? 'application/octet-stream';

    // ETag based on modified time + size
    final etagValue = etag
        ? '"${stat.modified.millisecondsSinceEpoch.toRadixString(36)}-${stat.size.toRadixString(36)}"'
        : null;

    // 304 Not Modified check
    if (etagValue != null) {
      final ifNoneMatch = requestHeaders['if-none-match'];
      if (ifNoneMatch == etagValue) {
        return _StaticResponse(304, {}, null);
      }
    }

    final ifModifiedSince = requestHeaders['if-modified-since'];
    if (ifModifiedSince != null) {
      try {
        final since = HttpDate.parse(ifModifiedSince);
        if (!stat.modified.isAfter(since)) {
          return _StaticResponse(304, {}, null);
        }
      } catch (_) {}
    }

    // Check for pre-compressed gzip variant
    List<int>? body;
    var headers = <String, String>{
      'content-type': contentType,
      'cache-control': 'public, max-age=$maxAge',
      'last-modified': HttpDate.format(stat.modified),
    };
    if (etagValue != null) headers['etag'] = etagValue;

    final acceptsGzip = requestHeaders['accept-encoding']?.contains('gzip') ?? false;
    if (gzip && acceptsGzip) {
      final gzFile = File('${file.path}.gz');
      if (await gzFile.exists()) {
        body = await gzFile.readAsBytes();
        headers['content-encoding'] = 'gzip';
      }
    }

    body ??= await file.readAsBytes();
    headers['content-length'] = body.length.toString();

    return _StaticResponse(200, headers, body);
  }
}

class _StaticResponse {
  final int status;
  final Map<String, String> headers;
  final List<int>? body;
  _StaticResponse(this.status, this.headers, this.body);
}
