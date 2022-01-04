///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2022/1/4 09:59
///
import 'src/constants.dart';

Future<void> main(List<String> arguments) async {
  await initializeCheck(arguments);
  if (!downloadedRecordsFile.existsSync()) {
    await downloadFile.copy(awaitingFileRecords);
    print('All files are awaiting.');
    return;
  }
  final downloadedLines =
      (await downloadedRecordsFile.readAsString()).split('\n');
  downloadedLines.removeWhere((String e) => e.isEmpty);
  print('${downloadedLines.length} files downloaded.');
  if (downloadedLines.isEmpty) {
    await downloadFile.copy(awaitingFileRecords);
    print('All files are awaiting.');
    return;
  }
  for (final String line in downloadedLines) {
    lines.remove(line);
  }
  await awaitingRecordsFile.writeAsString(lines.join('\n'));
  print('${lines.length} files are awaiting.');
}
