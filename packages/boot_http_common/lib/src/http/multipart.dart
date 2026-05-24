import 'dart:convert';
import 'dart:typed_data';

/// Represents an uploaded file from a multipart form.
class MultipartFile {
  final String name;
  final String? filename;
  final String? contentType;
  final Uint8List bytes;

  MultipartFile({
    required this.name,
    this.filename,
    this.contentType,
    required this.bytes,
  });

  int get size => bytes.length;

  String get text => utf8.decode(bytes);
}

/// Represents parsed multipart form data (fields + files).
class FormData {
  final Map<String, String> _fields;
  final Map<String, MultipartFile> _files;

  FormData(this._fields, this._files);

  /// Get a text field value by name.
  String? field(String name) => _fields[name];

  /// Get an uploaded file by field name.
  MultipartFile? file(String name) => _files[name];

  /// All text fields.
  Map<String, String> get fields => Map.unmodifiable(_fields);

  /// All uploaded files.
  Map<String, MultipartFile> get files => Map.unmodifiable(_files);
}

/// Parses multipart/form-data from raw bytes and boundary.
FormData parseMultipart(List<int> body, String boundary) {
  final fields = <String, String>{};
  final files = <String, MultipartFile>{};

  final boundaryBytes = utf8.encode('--$boundary');
  final bodyBytes = Uint8List.fromList(body);

  // Split by boundary
  final parts = <Uint8List>[];
  var start = 0;
  while (start < bodyBytes.length) {
    final idx = _indexOf(bodyBytes, boundaryBytes, start);
    if (idx == -1) break;
    if (start > 0) {
      // Strip leading \r\n and trailing \r\n before boundary
      var partEnd = idx - 2; // skip \r\n before boundary
      if (partEnd > start) {
        parts.add(bodyBytes.sublist(start, partEnd));
      }
    }
    start = idx + boundaryBytes.length;
    // Skip \r\n or -- after boundary
    if (start < bodyBytes.length - 1 && bodyBytes[start] == 13 && bodyBytes[start + 1] == 10) {
      start += 2;
    } else if (start < bodyBytes.length - 1 && bodyBytes[start] == 45 && bodyBytes[start + 1] == 45) {
      break; // final boundary --
    }
  }

  for (final part in parts) {
    // Find header/body separator (\r\n\r\n)
    final sep = _indexOf(part, utf8.encode('\r\n\r\n'), 0);
    if (sep == -1) continue;

    final headerStr = utf8.decode(part.sublist(0, sep));
    final content = part.sublist(sep + 4);

    final disposition = RegExp(r'Content-Disposition:\s*form-data;\s*(.+)', caseSensitive: false)
        .firstMatch(headerStr);
    if (disposition == null) continue;

    final params = disposition.group(1)!;
    final nameMatch = RegExp(r'name="([^"]*)"').firstMatch(params);
    if (nameMatch == null) continue;
    final name = nameMatch.group(1)!;

    final filenameMatch = RegExp(r'filename="([^"]*)"').firstMatch(params);
    if (filenameMatch != null) {
      final contentTypeMatch = RegExp(r'Content-Type:\s*(.+)', caseSensitive: false)
          .firstMatch(headerStr);
      files[name] = MultipartFile(
        name: name,
        filename: filenameMatch.group(1),
        contentType: contentTypeMatch?.group(1)?.trim(),
        bytes: Uint8List.fromList(content),
      );
    } else {
      fields[name] = utf8.decode(content);
    }
  }

  return FormData(fields, files);
}

int _indexOf(Uint8List haystack, List<int> needle, int start) {
  outer:
  for (var i = start; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}
