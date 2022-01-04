import 'dart:io';

Future<void> main() async {
  final Stopwatch stopwatch = Stopwatch()..start();
  List<String> _lines = await File('video.txt').readAsLines();
  Set<String> duplicates = <String>{};
  for (final line in _lines) {
    final name = Uri.parse(line).queryParameters['download_name']!;
    final _d = _lines.where((e) => e != line && e.contains(name));
    duplicates.addAll(_d);
  }
  print(duplicates.join('\n'));
  for (final line in duplicates) {
    _lines.remove(line);
  }
  print(_lines.length);
  _lines = _lines
      .map((l) => Uri.parse(l).queryParameters['download_name']!)
      .toList();
  stopwatch.stop();
  print(stopwatch.elapsed);
}
