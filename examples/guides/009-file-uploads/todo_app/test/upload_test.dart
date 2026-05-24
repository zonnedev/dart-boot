import 'dart:typed_data';
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('File Upload', () {
    test('upload succeeds with valid file', () async {
      await bootTest($configure, test: (client, container) async {
        final boundary = '----TestBoundary';
        final body = _buildMultipart(boundary, {
          'username': 'testuser',
        }, {
          'avatar': _FakeFile('test.png', 'image/png', Uint8List(100)),
        });

        final res = await client.post('/upload/avatar',
          body: body,
          headers: {'content-type': 'multipart/form-data; boundary=$boundary'},
        );
        res.expectStatus(200);
        expect(res.json()['username'], 'testuser');
        expect(res.json()['filename'], contains('test.png'));
        expect(res.json()['size'], 100);
      });
    });

    test('upload fails without file', () async {
      await bootTest($configure, test: (client, container) async {
        final boundary = '----TestBoundary';
        final body = _buildMultipart(boundary, {'username': 'alice'}, {});

        final res = await client.post('/upload/avatar',
          body: body,
          headers: {'content-type': 'multipart/form-data; boundary=$boundary'},
        );
        res.expectStatus(400);
        expect(res.json()['error'], contains('No file uploaded'));
      });
    });

    test('upload fails with oversized file', () async {
      await bootTest($configure, test: (client, container) async {
        final boundary = '----TestBoundary';
        final bigFile = Uint8List(6 * 1024 * 1024);
        final body = _buildMultipart(boundary, {}, {
          'avatar': _FakeFile('big.bin', 'image/png', bigFile),
        });

        final res = await client.post('/upload/avatar',
          body: body,
          headers: {'content-type': 'multipart/form-data; boundary=$boundary'},
        );
        res.expectStatus(400);
        expect(res.json()['error'], contains('too large'));
      });
    });
  });
}

class _FakeFile {
  final String filename;
  final String contentType;
  final Uint8List bytes;
  _FakeFile(this.filename, this.contentType, this.bytes);
}

String _buildMultipart(String boundary, Map<String, String> fields, Map<String, _FakeFile> files) {
  final buf = StringBuffer();
  for (final entry in fields.entries) {
    buf.write('--$boundary\r\n');
    buf.write('Content-Disposition: form-data; name="${entry.key}"\r\n');
    buf.write('\r\n');
    buf.write('${entry.value}\r\n');
  }
  for (final entry in files.entries) {
    buf.write('--$boundary\r\n');
    buf.write('Content-Disposition: form-data; name="${entry.key}"; filename="${entry.value.filename}"\r\n');
    buf.write('Content-Type: ${entry.value.contentType}\r\n');
    buf.write('\r\n');
    buf.write(String.fromCharCodes(entry.value.bytes));
    buf.write('\r\n');
  }
  buf.write('--$boundary--\r\n');
  return buf.toString();
}
