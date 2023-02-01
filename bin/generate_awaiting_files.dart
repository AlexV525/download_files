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
  final downloadedLines = await downloadedRecordsFile.readAsLines();
  downloadedLines.removeWhere((String e) => e.isEmpty);
  print('${downloadedLines.length} files downloaded.\n');
  if (downloadedLines.isEmpty) {
    await downloadFile.copy(awaitingFileRecords);
    print('All files are awaiting.');
    return;
  }
  final originalSet = Set<String>.from(lines);
  final downloadedSet = Set<String>.from(downloadedLines);
  final differenceList = List<String>.from(originalSet.difference(downloadedSet));
  await awaitingRecordsFile.writeAsString(differenceList.join('\n'));
  print('${differenceList.length} files are awaiting.');
}
