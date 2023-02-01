import 'src/constants.dart';

Future<void> main(List<String> arguments) async {
  await initializeCheck(arguments);
  final Stopwatch stopwatch = Stopwatch()..start();
  Set<String> duplicates = <String>{};
  for (final line in lines) {
    final name = Uri.parse(line).queryParameters[filenameParameter]!;
    final d = lines.where((e) => e != line && e.contains(name));
    duplicates.addAll(d);
  }
  print(duplicates.join('\n'));
  for (final line in duplicates) {
    lines.remove(line);
  }
  print(lines.length);
  lines = lines
      .map((l) => Uri.parse(l).queryParameters[filenameParameter]!)
      .toList();
  stopwatch.stop();
  print(stopwatch.elapsed);
}
