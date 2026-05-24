/// A Server-Sent Event.
class SseEvent {
  final String? event;
  final String data;
  final String? id;
  final int? retry;

  SseEvent({required this.data, this.event, this.id, this.retry});

  /// Format as SSE wire format.
  String encode() {
    final buf = StringBuffer();
    if (event != null) buf.writeln('event: $event');
    if (id != null) buf.writeln('id: $id');
    if (retry != null) buf.writeln('retry: $retry');
    for (final line in data.split('\n')) {
      buf.writeln('data: $line');
    }
    buf.writeln();
    return buf.toString();
  }
}
