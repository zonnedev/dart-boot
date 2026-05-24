# Guide 009: File Uploads

## What you'll build

An avatar upload endpoint that accepts image files, validates them, and stores them on disk.

## What you'll learn

- How multipart/form-data works
- How to parse uploaded files with `request.multipart()`
- How to access form fields alongside files
- How to validate file type and size
- How to test file uploads

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)

---

## Step 1: What is multipart/form-data?

When a browser sends a file, it uses a special encoding called `multipart/form-data`. Unlike JSON, it can carry both text fields and binary files in one request.

A multipart request looks like this conceptually:

```
--boundary
Content-Disposition: form-data; name="username"

alice
--boundary
Content-Disposition: form-data; name="avatar"; filename="photo.jpg"
Content-Type: image/jpeg

<binary file data>
--boundary--
```

Boot parses this automatically — you just call `request.multipart()`.

---

## Step 2: Create an upload controller

**`lib/src/controllers/upload_controller.dart`**

```dart
import 'dart:io';
import 'package:boot/boot.dart';

part 'upload_controller.g.dart';

@Controller('/upload')
class UploadController {
  /// POST /upload/avatar — accepts a file upload with an optional username field.
  @Post('/avatar')
  Future<Response> uploadAvatar(Request request) async {
    // Parse the multipart form data
    final form = await request.multipart();

    // Get the text field
    final username = form.field('username') ?? 'anonymous';

    // Get the uploaded file
    final file = form.file('avatar');
    if (file == null) {
      throw BadRequestException('No file uploaded. Send a file in the "avatar" field.');
    }

    // Validate file type
    final allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (file.contentType != null && !allowedTypes.contains(file.contentType)) {
      throw BadRequestException(
        'Invalid file type: ${file.contentType}. Allowed: ${allowedTypes.join(", ")}',
      );
    }

    // Validate file size (max 5MB)
    final maxSize = 5 * 1024 * 1024; // 5MB in bytes
    if (file.size > maxSize) {
      throw BadRequestException('File too large: ${file.size} bytes. Max: $maxSize bytes.');
    }

    // Save to disk
    final uploadDir = Directory('uploads');
    if (!uploadDir.existsSync()) uploadDir.createSync();

    final filename = '${username}_${DateTime.now().millisecondsSinceEpoch}_${file.filename}';
    final savedFile = File('uploads/$filename');
    await savedFile.writeAsBytes(file.bytes);

    return Response.json({
      'message': 'File uploaded successfully',
      'username': username,
      'filename': filename,
      'size': file.size,
      'contentType': file.contentType,
    });
  }
}
```

**What's happening:**

- `request.multipart()` — parses the raw multipart body into a `FormData` object
- `form.field('username')` — gets a text field by name (returns `String?`)
- `form.file('avatar')` — gets an uploaded file by name (returns `MultipartFile?`)
- `file.bytes` — the raw file content as `Uint8List`
- `file.filename` — the original filename from the client
- `file.contentType` — the MIME type (e.g., `image/jpeg`)
- `file.size` — size in bytes

---

## Step 3: The MultipartFile and FormData API

```dart
// FormData — the parsed form
form.field('name');          // String? — a text field
form.file('avatar');         // MultipartFile? — an uploaded file
form.fields;                 // Map<String, String> — all text fields
form.files;                  // Map<String, MultipartFile> — all files

// MultipartFile — one uploaded file
file.name;                   // String — the form field name
file.filename;               // String? — original filename
file.contentType;            // String? — MIME type
file.bytes;                  // Uint8List — file content
file.size;                   // int — size in bytes
file.text;                   // String — content as UTF-8 text (for text files)
```

---

## Step 4: Multiple file uploads

You can upload multiple files in one request:

```dart
@Post('/gallery')
Future<Response> uploadGallery(Request request) async {
  final form = await request.multipart();

  final results = <Map<String, dynamic>>[];
  for (final entry in form.files.entries) {
    final file = entry.value;
    final savedPath = 'uploads/${file.filename}';
    await File(savedPath).writeAsBytes(file.bytes);
    results.add({'field': entry.key, 'filename': file.filename, 'size': file.size});
  }

  return Response.json({'uploaded': results.length, 'files': results});
}
```

---

## Step 5: Export and build

**`lib/todo_app.dart`** — add export:

```dart
export 'src/controllers/upload_controller.dart';
```

```bash
boot build
boot serve
```

---

## Step 6: Test manually with curl

**Upload a file:**

```bash
curl -X POST http://localhost:8080/upload/avatar \
  -F "username=alice" \
  -F "avatar=@photo.jpg"
```

Response:
```json
{
  "message": "File uploaded successfully",
  "username": "alice",
  "filename": "alice_1716508800000_photo.jpg",
  "size": 45231,
  "contentType": "image/jpeg"
}
```

**Upload without a file (should fail):**

```bash
curl -X POST http://localhost:8080/upload/avatar \
  -F "username=alice"
```

Response:
```json
{"error": "No file uploaded. Send a file in the \"avatar\" field."}
```
Status: 400

**Upload a too-large file:**

```bash
# Create a 10MB test file
dd if=/dev/zero of=/tmp/big.bin bs=1M count=10
curl -X POST http://localhost:8080/upload/avatar \
  -F "avatar=@/tmp/big.bin"
```

Response:
```json
{"error": "File too large: 10485760 bytes. Max: 5242880 bytes."}
```
Status: 400

---

## Step 7: Write automated tests

**`test/upload_test.dart`**

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('File Upload', () {
    test('upload succeeds with valid file', () async {
      await bootTest($configure, test: (client, container) async {
        // Simulate a multipart upload
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
        final bigFile = Uint8List(6 * 1024 * 1024); // 6MB
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
    buf.writeln('--$boundary');
    buf.writeln('Content-Disposition: form-data; name="${entry.key}"');
    buf.writeln();
    buf.writeln(entry.value);
  }
  for (final entry in files.entries) {
    buf.writeln('--$boundary');
    buf.writeln('Content-Disposition: form-data; name="${entry.key}"; filename="${entry.value.filename}"');
    buf.writeln('Content-Type: ${entry.value.contentType}');
    buf.writeln();
    buf.write(String.fromCharCodes(entry.value.bytes));
    buf.writeln();
  }
  buf.writeln('--$boundary--');
  return buf.toString();
}
```

```bash
boot test
```

---

## Step 8: Add to .gitignore

Don't commit uploaded files:

```
# .gitignore
uploads/
```

---

## What you've learned

- `request.multipart()` parses multipart/form-data requests
- `form.field('name')` gets text fields, `form.file('name')` gets files
- `MultipartFile` gives you `bytes`, `filename`, `contentType`, `size`
- Validate file type and size before saving
- Use `File(...).writeAsBytes(file.bytes)` to save to disk
- Multiple files can be uploaded in one request
- Test uploads by building multipart bodies manually

## Next steps

- [Guide 010: Server-Sent Events](010-server-sent-events.md) — stream real-time updates to clients
