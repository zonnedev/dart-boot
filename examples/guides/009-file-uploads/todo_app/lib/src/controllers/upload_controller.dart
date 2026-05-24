import 'dart:io';
import 'package:boot/boot.dart';

part 'upload_controller.g.dart';

@Controller('/upload')
class UploadController {
  @Post('/avatar')
  Future<Response> uploadAvatar(Request request) async {
    final form = await request.multipart();

    final username = form.field('username') ?? 'anonymous';

    final file = form.file('avatar');
    if (file == null) {
      throw BadRequestException('No file uploaded. Send a file in the "avatar" field.');
    }

    final allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (file.contentType != null && !allowedTypes.contains(file.contentType)) {
      throw BadRequestException(
        'Invalid file type: ${file.contentType}. Allowed: ${allowedTypes.join(", ")}',
      );
    }

    final maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      throw BadRequestException('File too large: ${file.size} bytes. Max: $maxSize bytes.');
    }

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
