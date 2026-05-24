// ignore_for_file: avoid_print
import 'dart:io';

const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _red = '\x1B[31m';
const _reset = '\x1B[0m';

String _color(double pct) => pct >= 80 ? _green : pct >= 50 ? _yellow : _red;

String _bar(double pct, {int width = 10}) {
  final filled = (pct / 100 * width).round();
  return '${_color(pct)}${'█' * filled}$_reset${'░' * (width - filled)}';
}

void main(List<String> args) {
  final files = <String, ({int lines, int hit})>{};
  String? currentFile;

  final lcovPaths = args.isNotEmpty
      ? args
      : Directory('.')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('lcov.info'))
          .map((f) => f.path)
          .toList();

  for (final path in lcovPaths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    for (final line in file.readAsLinesSync()) {
      if (line.startsWith('SF:')) {
        currentFile = line.substring(3);
        if (currentFile!.endsWith('.g.dart') || currentFile!.contains('/generated/')) {
          currentFile = null;
        }
      } else if (currentFile == null) {
        continue;
      } else if (line.startsWith('LF:')) {
        final lf = int.parse(line.substring(3));
        files.update(currentFile!, (v) => (lines: v.lines + lf, hit: v.hit),
            ifAbsent: () => (lines: lf, hit: 0));
      } else if (line.startsWith('LH:')) {
        final lh = int.parse(line.substring(3));
        files.update(currentFile!, (v) => (lines: v.lines, hit: v.hit + lh),
            ifAbsent: () => (lines: 0, hit: lh));
      }
    }
  }

  if (files.isEmpty) {
    print('No coverage data found.');
    return;
  }

  final maxName = files.keys.map((k) => k.length).reduce((a, b) => a > b ? a : b).clamp(4, 50);
  final header = '${'File'.padRight(maxName)}  Lines   Hit   Coverage';
  print('');
  print(header);
  print('─' * (header.length + 12));

  var totalLines = 0;
  var totalHit = 0;
  for (final entry in files.entries) {
    final name = entry.key.length > maxName
        ? '...${entry.key.substring(entry.key.length - maxName + 3)}'
        : entry.key.padRight(maxName);
    final pct = entry.value.lines > 0 ? entry.value.hit / entry.value.lines * 100 : 0.0;
    final pctStr = '${pct.toStringAsFixed(1)}%'.padLeft(6);
    print('$name  ${entry.value.lines.toString().padLeft(5)}  ${entry.value.hit.toString().padLeft(4)}   ${_bar(pct)} ${_color(pct)}$pctStr$_reset');
    totalLines += entry.value.lines;
    totalHit += entry.value.hit;
  }

  print('─' * (header.length + 12));
  final totalPct = totalLines > 0 ? totalHit / totalLines * 100 : 0.0;
  final totalPctStr = '${totalPct.toStringAsFixed(1)}%'.padLeft(6);
  print('${'TOTAL'.padRight(maxName)}  ${totalLines.toString().padLeft(5)}  ${totalHit.toString().padLeft(4)}   ${_bar(totalPct)} ${_color(totalPct)}$totalPctStr$_reset');
  print('');
}
